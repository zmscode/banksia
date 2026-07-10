//! DNG (TIFF container) decode: the subset of the format emu needs.
//!
//! Supported today: uncompressed (Compression = 1) 16-bit CFA mosaics with
//! 2x2 Bayer patterns, strip layout, either byte order, and the raw IFD
//! located through the IFD0 / SubIFD chain. Lossless-JPEG DNG and vendor
//! formats arrive behind this same interface later (plan.md).
//!
//! Parsing is control plane over untrusted input: malformed input returns
//! `error.Corrupt` / `error.Unsupported`, never trips an assertion. The
//! assertions here guard *our* invariants, on data we produced.

const std = @import("std");
const assert = std.debug.assert;
const image = @import("image.zig");

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

pub const Error = error{ Corrupt, Unsupported, OutOfMemory };

/// Bounds on the container walk. Every loop below is capped by one of these.
const ifd_visit_max: u32 = 8;
const ifd_entries_max: u32 = 512;
const strips_max: u32 = 4096;

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
        else => error.Unsupported,
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
        else => error.Unsupported,
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
        else => return error.Unsupported,
    }
}

fn ifd_parse(r: *const Reader, off: u32) Error!struct { ifd: Ifd, next: u32 } {
    const count = try r.read_u16(off);
    if (count == 0 or count > ifd_entries_max) return error.Unsupported;
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

    while (pending_len > 0 and raw == null) {
        visited += 1;
        if (visited > ifd_visit_max) return error.Unsupported;
        pending_len -= 1;
        const off = pending[pending_len];
        if (off == 0) continue;

        const parsed = try ifd_parse(&r, off);
        const ifd = parsed.ifd;
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

    const ifd = raw orelse return error.Unsupported;
    return sensor_from_ifd(gpa, &r, &ifd);
}

fn sensor_from_ifd(gpa: std.mem.Allocator, r: *const Reader, ifd: *const Ifd) Error!SensorData {
    const width = try require_scalar(r, ifd, tag_image_width);
    const height = try require_scalar(r, ifd, tag_image_height);
    if (width == 0 or width > image.edge_px_max) return error.Unsupported;
    if (height == 0 or height > image.edge_px_max) return error.Unsupported;

    if (try require_scalar(r, ifd, tag_bits_per_sample) != 16) return error.Unsupported;
    if (try require_scalar(r, ifd, tag_compression) != 1) return error.Unsupported;
    if (try scalar_or(r, ifd, tag_samples_per_pixel, 1) != 1) return error.Unsupported;

    const cfa = try cfa_pattern(r, ifd);
    const black_level = try fraction_or(r, ifd, tag_black_level, 0.0);
    const white_level: f32 = @floatFromInt(try scalar_or(r, ifd, tag_white_level, 65535));
    if (white_level <= black_level) return error.Corrupt;
    const wb_neutral = try as_shot_neutral(r, ifd);

    const bayer = try bayer_read(gpa, r, ifd, width, height);
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
    const e = ifd.find(tag) orelse return error.Unsupported;
    return value_scalar(r, e, 0);
}

fn scalar_or(r: *const Reader, ifd: *const Ifd, tag: u16, default: u32) Error!u32 {
    const e = ifd.find(tag) orelse return default;
    return value_scalar(r, e, 0);
}

fn fraction_or(r: *const Reader, ifd: *const Ifd, tag: u16, default: f32) Error!f32 {
    const e = ifd.find(tag) orelse return default;
    return value_fraction(r, e, 0);
}

fn cfa_pattern(r: *const Reader, ifd: *const Ifd) Error![4]CfaColor {
    const dims = ifd.find(tag_cfa_repeat_dim) orelse return error.Unsupported;
    if (try value_scalar(r, dims, 0) != 2) return error.Unsupported;
    if (try value_scalar(r, dims, 1) != 2) return error.Unsupported;

    const pattern = ifd.find(tag_cfa_pattern) orelse return error.Unsupported;
    if (pattern.count != 4) return error.Unsupported;
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
            else => return error.Unsupported,
        };
        switch (c.*) {
            .red => reds += 1,
            .green => greens += 1,
            .blue => blues += 1,
        }
    }
    // A Bayer mosaic is exactly two greens on one diagonal, one red, one
    // blue — equivalently, no row or column of the 2x2 repeats a colour.
    if (greens != 2 or reds != 1 or blues != 1) return error.Unsupported;
    if (cfa[0] == cfa[1] or cfa[2] == cfa[3]) return error.Unsupported;
    if (cfa[0] == cfa[2] or cfa[1] == cfa[3]) return error.Unsupported;
    return cfa;
}

fn as_shot_neutral(r: *const Reader, ifd: *const Ifd) Error![3]f32 {
    const e = ifd.find(tag_as_shot_neutral) orelse return .{ 1, 1, 1 };
    if (e.count != 3) return error.Unsupported;
    var neutral: [3]f32 = undefined;
    for (&neutral, 0..) |*n, i| {
        n.* = try value_fraction(r, e, @intCast(i));
        if (!(n.* > 0)) return error.Corrupt;
    }
    return neutral;
}

fn bayer_read(
    gpa: std.mem.Allocator,
    r: *const Reader,
    ifd: *const Ifd,
    width: u32,
    height: u32,
) Error![]u16 {
    const offsets = ifd.find(tag_strip_offsets) orelse return error.Unsupported;
    const counts = ifd.find(tag_strip_byte_counts) orelse return error.Unsupported;
    if (offsets.count != counts.count) return error.Corrupt;
    if (offsets.count == 0 or offsets.count > strips_max) return error.Unsupported;

    const sample_count = @as(u64, width) * height;
    const bayer = try gpa.alloc(u16, @intCast(sample_count));
    errdefer gpa.free(bayer);

    var filled: u64 = 0;
    var strip: u32 = 0;
    while (strip < offsets.count) : (strip += 1) {
        const off = try value_scalar(r, offsets, strip);
        const byte_count = try value_scalar(r, counts, strip);
        if (byte_count % 2 != 0) return error.Corrupt;
        const data = try r.slice(off, byte_count);
        var i: u32 = 0;
        while (i < byte_count) : (i += 2) {
            if (filled >= sample_count) return error.Corrupt;
            bayer[@intCast(filled)] =
                std.mem.readInt(u16, data[i..][0..2], r.endian);
            filled += 1;
        }
    }
    if (filled != sample_count) return error.Corrupt;
    return bayer;
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
