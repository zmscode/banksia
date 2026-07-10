//! DNG (TIFF container) decode: the subset of the format emu needs.
//!
//! Supported today: 16-bit CFA mosaics with 2x2 Bayer patterns, either byte
//! order, strip or tile layout, uncompressed (Compression = 1) or lossless
//! JPEG (Compression = 7 — what real cameras and Adobe DNG Converter
//! write), the raw IFD located through the IFD0 / SubIFD chain, and
//! AsShotNeutral from the raw IFD or its IFD0 home. Vendor formats (CR3,
//! NEF, ARW) arrive behind this same interface later (plan.md, Phase 6).
//!
//! Parsing is control plane over untrusted input: malformed input returns
//! `error.Corrupt`, unimplemented features return an `Unsupported*` error
//! naming what is missing, and nothing trips an assertion. The assertions
//! here guard *our* invariants, on data we produced.

const std = @import("std");
const assert = std.debug.assert;
const image = @import("image.zig");
const jpeg_lossless = @import("jpeg_lossless.zig");

pub const CfaColor = enum(u8) { red = 0, green = 1, blue = 2 };

pub const SensorData = struct {
    width: u32,
    height: u32,
    /// Row-major 2x2 repeat pattern: [top-left, top-right, bot-left, bot-right].
    cfa: [4]CfaColor,
    black_level: f32,
    white_level: f32,
    /// Camera as-shot neutral (linear RGB of a neutral patch), for white balance.
    wb_neutral: [3]f32,
    /// Dense row-major mosaic, exactly `width * height` samples.
    bayer: []u16,

    pub fn deinit(self: *SensorData, gpa: std.mem.Allocator) void {
        assert(self.bayer.len == @as(usize, self.width) * self.height);
        gpa.free(self.bayer);
        self.* = undefined;
    }
};

/// Malformed input is `Corrupt`; valid DNG using a feature this decoder
/// lacks gets an error naming the feature, so "cannot open" self-diagnoses
/// at the CLI and across the C ABI (both print the error name).
pub const Error = error{
    Corrupt,
    OutOfMemory,
    /// Compression other than uncompressed (1) or lossless JPEG (7).
    UnsupportedCompression,
    /// Neither a strip layout nor a tile layout (or, corruptly, both).
    UnsupportedLayout,
    /// Sample storage other than 16 bits per sample, one sample per pixel.
    UnsupportedBitDepth,
    /// CFA patterns beyond the 2x2 Bayer family.
    UnsupportedCfa,
    /// Per-site black levels that differ within the repeat pattern.
    UnsupportedBlackLevel,
    /// Image larger than `image.edge_px_max` on a side.
    UnsupportedDimensions,
    /// TIFF structure outside the profile: exotic tag types, IFD chains
    /// deeper than the walk bound, or no CFA IFD at all.
    UnsupportedStructure,
    /// Lossless JPEG features outside DNG's use of it (restart intervals,
    /// subsampling, arithmetic coding).
    UnsupportedJpeg,
};

/// Bounds on the container walk. Every loop below is capped by one of these.
const ifd_visit_max: u32 = 8;
const ifd_entries_max: u32 = 512;
const segments_max: u32 = 65536;
/// Cap on one segment's decoded samples (a 256x240 tile is 61k; this is
/// generous) so a hostile tile size cannot demand gigabytes of scratch.
const segment_samples_max: u32 = 1 << 26;

const tag_new_subfile_type: u16 = 254;
const tag_image_width: u16 = 256;
const tag_image_height: u16 = 257;
const tag_bits_per_sample: u16 = 258;
const tag_compression: u16 = 259;
const tag_photometric: u16 = 262;
const tag_strip_offsets: u16 = 273;
const tag_samples_per_pixel: u16 = 277;
const tag_rows_per_strip: u16 = 278;
const tag_strip_byte_counts: u16 = 279;
const tag_sub_ifds: u16 = 330;
const tag_tile_width: u16 = 322;
const tag_tile_height: u16 = 323;
const tag_tile_offsets: u16 = 324;
const tag_tile_byte_counts: u16 = 325;
const tag_cfa_repeat_dim: u16 = 33421;
const tag_cfa_pattern: u16 = 33422;
const tag_black_level: u16 = 50714;
const tag_white_level: u16 = 50717;
const tag_as_shot_neutral: u16 = 50728;

const photometric_cfa: u32 = 32803;

const type_byte: u16 = 1;
const type_ascii: u16 = 2;
const type_short: u16 = 3;
const type_long: u16 = 4;
const type_rational: u16 = 5;
const type_srational: u16 = 10;

const Reader = struct {
    bytes: []const u8,
    endian: std.builtin.Endian,

    fn slice(self: *const Reader, off: u32, len: u64) Error![]const u8 {
        const end = @as(u64, off) + len;
        if (end > self.bytes.len) return error.Corrupt;
        return self.bytes[off..@intCast(end)];
    }

    fn read_u16(self: *const Reader, off: u32) Error!u16 {
        const s = try self.slice(off, 2);
        return std.mem.readInt(u16, s[0..2], self.endian);
    }

    fn read_u32(self: *const Reader, off: u32) Error!u32 {
        const s = try self.slice(off, 4);
        return std.mem.readInt(u32, s[0..4], self.endian);
    }
};

const Entry = struct {
    tag: u16,
    typ: u16,
    count: u32,
    /// Offset of the entry's own 4 payload bytes (not the pointed-to value).
    payload_off: u32,
};

const Ifd = struct {
    entries: [ifd_entries_max]Entry,
    len: u32,

    fn find(self: *const Ifd, tag: u16) ?Entry {
        assert(self.len <= ifd_entries_max);
        for (self.entries[0..self.len]) |e| {
            if (e.tag == tag) return e;
        }
        return null;
    }
};

fn type_size(typ: u16) Error!u32 {
    return switch (typ) {
        type_byte, type_ascii => 1,
        type_short => 2,
        type_long => 4,
        type_rational, type_srational => 8,
        else => error.UnsupportedStructure,
    };
}

/// Offset of element `index` of an entry's value, following TIFF's rule:
/// values of 4 bytes or fewer live inline in the entry, wider ones live at
/// the offset the entry's payload points to.
fn value_off(r: *const Reader, e: Entry, index: u32) Error!u32 {
    if (index >= e.count) return error.Corrupt;
    const size = try type_size(e.typ);
    const total = @as(u64, size) * e.count;
    const base: u32 = if (total <= 4) e.payload_off else try r.read_u32(e.payload_off);
    const off = @as(u64, base) + @as(u64, size) * index;
    if (off > std.math.maxInt(u32)) return error.Corrupt;
    return @intCast(off);
}

fn value_scalar(r: *const Reader, e: Entry, index: u32) Error!u32 {
    const off = try value_off(r, e, index);
    return switch (e.typ) {
        type_byte => (try r.slice(off, 1))[0],
        type_short => try r.read_u16(off),
        type_long => try r.read_u32(off),
        else => error.UnsupportedStructure,
    };
}

fn value_fraction(r: *const Reader, e: Entry, index: u32) Error!f32 {
    const off = try value_off(r, e, index);
    switch (e.typ) {
        type_short, type_long, type_byte => {
            return @floatFromInt(try value_scalar(r, e, index));
        },
        type_rational, type_srational => {
            const numerator = try r.read_u32(off);
            const denominator = try r.read_u32(off + 4);
            if (denominator == 0) return error.Corrupt;
            if (e.typ == type_srational) {
                const n: i32 = @bitCast(numerator);
                const d: i32 = @bitCast(denominator);
                if (d == 0) return error.Corrupt;
                return @as(f32, @floatFromInt(n)) / @as(f32, @floatFromInt(d));
            }
            return @as(f32, @floatFromInt(numerator)) /
                @as(f32, @floatFromInt(denominator));
        },
        else => return error.UnsupportedStructure,
    }
}

fn ifd_parse(r: *const Reader, off: u32) Error!struct { ifd: Ifd, next: u32 } {
    const count = try r.read_u16(off);
    if (count == 0) return error.Corrupt;
    if (count > ifd_entries_max) return error.UnsupportedStructure;
    var ifd = Ifd{ .entries = undefined, .len = count };
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const entry_off = off + 2 + i * 12;
        ifd.entries[i] = .{
            .tag = try r.read_u16(entry_off),
            .typ = try r.read_u16(entry_off + 2),
            .count = try r.read_u32(entry_off + 4),
            .payload_off = entry_off + 8,
        };
    }
    const next = try r.read_u32(off + 2 + count * 12);
    return .{ .ifd = ifd, .next = next };
}

fn reader_init(bytes: []const u8) Error!Reader {
    if (bytes.len < 8) return error.Corrupt;
    const endian: std.builtin.Endian = switch (std.mem.readInt(u16, bytes[0..2], .little)) {
        0x4949 => .little, // "II"
        0x4D4D => .big, // "MM"
        else => return error.Corrupt,
    };
    const r = Reader{ .bytes = bytes, .endian = endian };
    if (try r.read_u16(2) != 42) return error.Corrupt;
    return r;
}

/// Decode a DNG blob into dense sensor data. The blob is untrusted; the
/// result is trusted (its invariants are asserted before returning).
pub fn decode(gpa: std.mem.Allocator, bytes: []const u8) Error!SensorData {
    const r = try reader_init(bytes);

    // Walk IFD0, its chain, and any SubIFDs, bounded by `ifd_visit_max` —
    // an explicit worklist, not recursion. The raw image is the first IFD
    // whose PhotometricInterpretation is CFA.
    var pending: [ifd_visit_max]u32 = undefined;
    var pending_len: u32 = 1;
    pending[0] = try r.read_u32(4);
    var visited: u32 = 0;
    var raw: ?Ifd = null;
    // IFD0 is retained: DNG keeps camera-wide tags (AsShotNeutral) there
    // even when the raw mosaic lives in a SubIFD.
    var first: ?Ifd = null;

    while (pending_len > 0 and raw == null) {
        visited += 1;
        if (visited > ifd_visit_max) return error.UnsupportedStructure;
        pending_len -= 1;
        const off = pending[pending_len];
        if (off == 0) continue;

        const parsed = try ifd_parse(&r, off);
        const ifd = parsed.ifd;
        if (first == null) first = ifd;
        if (ifd.find(tag_photometric)) |p| {
            if (try value_scalar(&r, p, 0) == photometric_cfa) {
                raw = ifd;
                break;
            }
        }
        if (parsed.next != 0 and pending_len < ifd_visit_max) {
            pending[pending_len] = parsed.next;
            pending_len += 1;
        }
        if (ifd.find(tag_sub_ifds)) |subs| {
            var i: u32 = 0;
            while (i < subs.count and pending_len < ifd_visit_max) : (i += 1) {
                pending[pending_len] = try value_scalar(&r, subs, i);
                pending_len += 1;
            }
        }
    }

    const ifd = raw orelse return error.UnsupportedStructure;
    assert(first != null); // the loop parsed at least the IFD that broke it
    return sensor_from_ifd(gpa, &r, &ifd, &first.?);
}

const compression_none: u32 = 1;
const compression_lossless_jpeg: u32 = 7;

fn sensor_from_ifd(
    gpa: std.mem.Allocator,
    r: *const Reader,
    ifd: *const Ifd,
    ifd0: *const Ifd,
) Error!SensorData {
    const width = try require_scalar(r, ifd, tag_image_width);
    const height = try require_scalar(r, ifd, tag_image_height);
    if (width == 0 or height == 0) return error.Corrupt;
    if (width > image.edge_px_max) return error.UnsupportedDimensions;
    if (height > image.edge_px_max) return error.UnsupportedDimensions;

    if (try require_scalar(r, ifd, tag_bits_per_sample) != 16) {
        return error.UnsupportedBitDepth;
    }
    if (try scalar_or(r, ifd, tag_samples_per_pixel, 1) != 1) {
        return error.UnsupportedBitDepth;
    }
    const compression = try require_scalar(r, ifd, tag_compression);
    if (compression != compression_none and compression != compression_lossless_jpeg) {
        return error.UnsupportedCompression;
    }

    const cfa = try cfa_pattern(r, ifd);
    const black_level = try black_level_read(r, ifd);
    const white_level: f32 = @floatFromInt(try scalar_or(r, ifd, tag_white_level, 65535));
    if (white_level <= black_level) return error.Corrupt;
    const wb_neutral = try as_shot_neutral(r, ifd, ifd0);

    const bayer = try bayer_read(gpa, r, ifd, width, height, compression);
    errdefer comptime unreachable; // no failure paths after this point

    // Postconditions: this is the trust boundary. Everything downstream may
    // assert instead of re-validating.
    assert(bayer.len == @as(usize, width) * height);
    assert(white_level > black_level);
    return .{
        .width = width,
        .height = height,
        .cfa = cfa,
        .black_level = black_level,
        .white_level = white_level,
        .wb_neutral = wb_neutral,
        .bayer = bayer,
    };
}

fn require_scalar(r: *const Reader, ifd: *const Ifd, tag: u16) Error!u32 {
    const e = ifd.find(tag) orelse return error.UnsupportedStructure;
    return value_scalar(r, e, 0);
}

fn scalar_or(r: *const Reader, ifd: *const Ifd, tag: u16, default: u32) Error!u32 {
    const e = ifd.find(tag) orelse return default;
    return value_scalar(r, e, 0);
}

/// BlackLevel may repeat per CFA site; the pipeline models one scalar, so
/// per-site values are accepted only when they agree.
fn black_level_read(r: *const Reader, ifd: *const Ifd) Error!f32 {
    const e = ifd.find(tag_black_level) orelse return 0;
    if (e.count == 0 or e.count > 16) return error.Corrupt;
    const first = try value_fraction(r, e, 0);
    var i: u32 = 1;
    while (i < e.count) : (i += 1) {
        if (try value_fraction(r, e, i) != first) return error.UnsupportedBlackLevel;
    }
    return first;
}

fn cfa_pattern(r: *const Reader, ifd: *const Ifd) Error![4]CfaColor {
    const dims = ifd.find(tag_cfa_repeat_dim) orelse return error.UnsupportedCfa;
    if (try value_scalar(r, dims, 0) != 2) return error.UnsupportedCfa;
    if (try value_scalar(r, dims, 1) != 2) return error.UnsupportedCfa;

    const pattern = ifd.find(tag_cfa_pattern) orelse return error.UnsupportedCfa;
    if (pattern.count != 4) return error.UnsupportedCfa;
    var cfa: [4]CfaColor = undefined;
    var greens: u32 = 0;
    var reds: u32 = 0;
    var blues: u32 = 0;
    for (&cfa, 0..) |*c, i| {
        const v = try value_scalar(r, pattern, @intCast(i));
        c.* = switch (v) {
            0 => .red,
            1 => .green,
            2 => .blue,
            else => return error.UnsupportedCfa,
        };
        switch (c.*) {
            .red => reds += 1,
            .green => greens += 1,
            .blue => blues += 1,
        }
    }
    // A Bayer mosaic is exactly two greens on one diagonal, one red, one
    // blue — equivalently, no row or column of the 2x2 repeats a colour.
    if (greens != 2 or reds != 1 or blues != 1) return error.UnsupportedCfa;
    if (cfa[0] == cfa[1] or cfa[2] == cfa[3]) return error.UnsupportedCfa;
    if (cfa[0] == cfa[2] or cfa[1] == cfa[3]) return error.UnsupportedCfa;
    return cfa;
}

fn as_shot_neutral(r: *const Reader, ifd: *const Ifd, ifd0: *const Ifd) Error![3]f32 {
    // The raw IFD wins if it carries the tag, but its spec home is IFD0.
    const e = ifd.find(tag_as_shot_neutral) orelse
        ifd0.find(tag_as_shot_neutral) orelse return .{ 1, 1, 1 };
    if (e.count != 3) return error.Corrupt;
    var neutral: [3]f32 = undefined;
    for (&neutral, 0..) |*n, i| {
        n.* = try value_fraction(r, e, @intCast(i));
        if (!(n.* > 0)) return error.Corrupt;
    }
    return neutral;
}

/// The segment grid: strips are tiles the width of the image in a 1-wide
/// grid, so one geometry serves both layouts. `source_*` is what a segment
/// stores (tiles pad the edges; strips clip), `copy_*` is what lands in
/// the mosaic.
const Layout = struct {
    kind: enum { strips, tiles },
    offsets: Entry,
    byte_counts: Entry,
    segment_width: u32,
    segment_height: u32,
    across: u32,
    down: u32,

    fn segment_count(self: *const Layout) u32 {
        assert(self.across >= 1);
        assert(self.down >= 1);
        return self.across * self.down;
    }

    fn segment(self: *const Layout, index: u32, width: u32, height: u32) Segment {
        assert(index < self.segment_count());
        const x = (index % self.across) * self.segment_width;
        const y = (index / self.across) * self.segment_height;
        assert(x < width);
        assert(y < height);
        const copy_width = @min(self.segment_width, width - x);
        const copy_height = @min(self.segment_height, height - y);
        return .{
            .x = x,
            .y = y,
            .copy_width = copy_width,
            .copy_height = copy_height,
            .source_width = self.segment_width,
            // Tiles store full (padded) tiles; strips store exactly the
            // rows that exist.
            .source_height = if (self.kind == .tiles) self.segment_height else copy_height,
        };
    }
};

const Segment = struct {
    x: u32,
    y: u32,
    copy_width: u32,
    copy_height: u32,
    source_width: u32,
    source_height: u32,
};

fn layout_parse(r: *const Reader, ifd: *const Ifd, width: u32, height: u32) Error!Layout {
    const strip_offsets = ifd.find(tag_strip_offsets);
    const tile_offsets = ifd.find(tag_tile_offsets);
    // Exactly one layout: neither is undecodable, both is malformed.
    if (strip_offsets == null and tile_offsets == null) return error.UnsupportedLayout;
    if (strip_offsets != null and tile_offsets != null) return error.Corrupt;

    var layout: Layout = undefined;
    if (strip_offsets) |offsets| {
        const rows = @min(try scalar_or(r, ifd, tag_rows_per_strip, height), height);
        if (rows == 0) return error.Corrupt;
        layout = .{
            .kind = .strips,
            .offsets = offsets,
            .byte_counts = ifd.find(tag_strip_byte_counts) orelse return error.Corrupt,
            .segment_width = width,
            .segment_height = rows,
            .across = 1,
            .down = (height + rows - 1) / rows,
        };
    } else {
        const tile_width = try require_scalar(r, ifd, tag_tile_width);
        const tile_height = try require_scalar(r, ifd, tag_tile_height);
        if (tile_width == 0 or tile_height == 0) return error.Corrupt;
        if (@as(u64, tile_width) * tile_height > segment_samples_max) {
            return error.UnsupportedDimensions;
        }
        layout = .{
            .kind = .tiles,
            .offsets = tile_offsets.?,
            .byte_counts = ifd.find(tag_tile_byte_counts) orelse return error.Corrupt,
            .segment_width = tile_width,
            .segment_height = tile_height,
            .across = (width + tile_width - 1) / tile_width,
            .down = (height + tile_height - 1) / tile_height,
        };
    }
    if (layout.segment_count() > segments_max) return error.UnsupportedLayout;
    if (layout.offsets.count != layout.segment_count()) return error.Corrupt;
    if (layout.byte_counts.count != layout.segment_count()) return error.Corrupt;
    return layout;
}

fn bayer_read(
    gpa: std.mem.Allocator,
    r: *const Reader,
    ifd: *const Ifd,
    width: u32,
    height: u32,
    compression: u32,
) Error![]u16 {
    const layout = try layout_parse(r, ifd, width, height);
    const sample_count = @as(u64, width) * height;
    const bayer = try gpa.alloc(u16, @intCast(sample_count));
    errdefer gpa.free(bayer);

    // Lossless JPEG decodes a whole segment (padding included) before the
    // in-bounds region is copied out; one scratch serves every segment.
    var scratch: []u16 = &.{};
    defer gpa.free(scratch);
    if (compression == compression_lossless_jpeg) {
        scratch = try gpa.alloc(
            u16,
            @as(usize, layout.segment_width) * layout.segment_height,
        );
    }

    var index: u32 = 0;
    while (index < layout.segment_count()) : (index += 1) {
        const seg = layout.segment(index, width, height);
        const offset = try value_scalar(r, layout.offsets, index);
        const byte_count = try value_scalar(r, layout.byte_counts, index);
        const data = try r.slice(offset, byte_count);

        if (compression == compression_none) {
            const expected = @as(u64, seg.source_width) * seg.source_height * 2;
            if (byte_count != expected) return error.Corrupt;
            segment_copy_raw(bayer, width, seg, data, r.endian);
        } else {
            const samples = scratch[0 .. @as(usize, seg.source_width) * seg.source_height];
            try jpeg_lossless.decode(data, samples, seg.source_width, seg.source_height);
            segment_copy_decoded(bayer, width, seg, samples);
        }
    }
    // The grid covers the image exactly by construction: segment origins
    // step by segment size and every copy region clips to the border, so
    // each mosaic site was written exactly once.
    return bayer;
}

fn segment_copy_raw(
    bayer: []u16,
    width: u32,
    seg: Segment,
    data: []const u8,
    endian: std.builtin.Endian,
) void {
    assert(data.len == @as(u64, seg.source_width) * seg.source_height * 2);
    assert(seg.copy_width <= seg.source_width);
    assert(seg.x + seg.copy_width <= width);
    var row: u32 = 0;
    while (row < seg.copy_height) : (row += 1) {
        const source_base = @as(usize, row) * seg.source_width * 2;
        const target_base = @as(usize, seg.y + row) * width + seg.x;
        var column: u32 = 0;
        while (column < seg.copy_width) : (column += 1) {
            bayer[target_base + column] = std.mem.readInt(
                u16,
                data[source_base + @as(usize, column) * 2 ..][0..2],
                endian,
            );
        }
    }
}

fn segment_copy_decoded(bayer: []u16, width: u32, seg: Segment, samples: []const u16) void {
    assert(samples.len == @as(u64, seg.source_width) * seg.source_height);
    assert(seg.copy_width <= seg.source_width);
    assert(seg.x + seg.copy_width <= width);
    var row: u32 = 0;
    while (row < seg.copy_height) : (row += 1) {
        const source_base = @as(usize, row) * seg.source_width;
        const target_base = @as(usize, seg.y + row) * width + seg.x;
        @memcpy(
            bayer[target_base..][0..seg.copy_width],
            samples[source_base..][0..seg.copy_width],
        );
    }
}

test "truncated and garbage input is Corrupt, never a crash" {
    const gpa = std.testing.allocator;
    try std.testing.expectError(error.Corrupt, decode(gpa, ""));
    try std.testing.expectError(error.Corrupt, decode(gpa, "II\x2a\x00"));
    try std.testing.expectError(error.Corrupt, decode(gpa, "not a tiff at all"));
    // Valid header, IFD offset pointing past the end.
    try std.testing.expectError(
        error.Corrupt,
        decode(gpa, "II\x2a\x00\xff\xff\xff\xff"),
    );
}

/// Overwrite one IFD0 entry of a little-endian fixture in place. Tests
/// know the writer's layout (IFD at offset 8); this keeps negative-space
/// cases one field away from a valid file instead of hand-built blobs.
fn test_entry_patch(blob: []u8, tag: u16, payload: u32) void {
    const count = std.mem.readInt(u16, blob[8..10], .little);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const off = 10 + i * 12;
        if (std.mem.readInt(u16, blob[off..][0..2], .little) == tag) {
            std.mem.writeInt(u32, blob[off + 8 ..][0..4], payload, .little);
            return;
        }
    }
    unreachable; // the fixture writer always emits the tag under test
}

fn test_entry_retag(blob: []u8, tag: u16, tag_new: u16) void {
    const count = std.mem.readInt(u16, blob[8..10], .little);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const off = 10 + i * 12;
        if (std.mem.readInt(u16, blob[off..][0..2], .little) == tag) {
            std.mem.writeInt(u16, blob[off..][0..2], tag_new, .little);
            return;
        }
    }
    unreachable;
}

test "unsupported features fail by name, one field away from valid" {
    const gpa = std.testing.allocator;
    const dng_write = @import("dng_write.zig");
    const bayer = [_]u16{ 100, 200, 300, 400 };
    const pristine = try dng_write.write(gpa, .{ .width = 2, .height = 2, .bayer = &bayer });
    defer gpa.free(pristine);

    const cases = [_]struct { tag: u16, payload: u32, expected: Error }{
        // Deflate-compressed DNG exists in the wild; name it, don't lump it.
        .{ .tag = tag_compression, .payload = 8, .expected = error.UnsupportedCompression },
        .{ .tag = tag_bits_per_sample, .payload = 8, .expected = error.UnsupportedBitDepth },
        .{ .tag = tag_samples_per_pixel, .payload = 3, .expected = error.UnsupportedBitDepth },
        // Photometric that never becomes CFA: the walk finds no raw IFD.
        .{ .tag = tag_photometric, .payload = 1, .expected = error.UnsupportedStructure },
        // A 3x3 repeat pattern (X-Trans territory) is not Bayer.
        .{ .tag = tag_cfa_repeat_dim, .payload = 3 | (3 << 16), .expected = error.UnsupportedCfa },
        // Compression 7 whose strip bytes are not a JPEG stream at all.
        .{ .tag = tag_compression, .payload = 7, .expected = error.Corrupt },
    };
    for (cases) |case| {
        const blob = try gpa.dupe(u8, pristine);
        defer gpa.free(blob);
        test_entry_patch(blob, case.tag, case.payload);
        try std.testing.expectError(case.expected, decode(gpa, blob));
    }

    // No strip layout and no tile layout leaves nothing to read.
    const blob = try gpa.dupe(u8, pristine);
    defer gpa.free(blob);
    test_entry_retag(blob, tag_strip_offsets, 999);
    try std.testing.expectError(error.UnsupportedLayout, decode(gpa, blob));
}
