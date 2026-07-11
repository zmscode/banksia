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

pub const Orientation = enum(u8) {
    normal = 1,
    mirror_horizontal = 2,
    rotate_180 = 3,
    mirror_vertical = 4,
    transpose = 5,
    rotate_90_clockwise = 6,
    transverse = 7,
    rotate_270_clockwise = 8,
};

pub const Rect = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
};

pub const Compression = enum { none, lossless_jpeg, proprietary };

pub const Matrix3x3 = [9]f32;

pub const Text = struct {
    bytes: [128]u8 = @splat(0),
    len: u8 = 0,

    pub fn init(value: []const u8) Text {
        var text = Text{};
        const len = @min(value.len, text.bytes.len);
        @memcpy(text.bytes[0..len], value[0..len]);
        text.len = @intCast(len);
        return text;
    }

    pub fn slice(text: *const Text) []const u8 {
        return text.bytes[0..text.len];
    }
};

/// Metadata shared by metadata-only import and full pixel decode. Crop origin
/// is relative to the active area's top-left, as defined by DNG.
pub const Metadata = struct {
    width: u32,
    height: u32,
    compression: Compression,
    cfa: [4]CfaColor,
    black_level: f32,
    white_level: f32,
    black_level_site: ?[4]f32 = null,
    white_level_site: ?[4]f32 = null,
    wb_neutral: [3]f32,
    orientation: Orientation,
    active_area: Rect,
    default_crop: Rect,
    make: Text = .{},
    model: Text = .{},
    unique_model: Text = .{},
    lens: Text = .{},
    iso: ?f32 = null,
    capture_time: ?i64 = null,
    capture_datetime: Text = .{},
    capture_subsecond: Text = .{},
    color_matrix_1: ?Matrix3x3 = null,
    color_matrix_2: ?Matrix3x3 = null,
    calibration_illuminant_1: ?u16 = null,
    calibration_illuminant_2: ?u16 = null,
    camera_calibration_1: ?Matrix3x3 = null,
    camera_calibration_2: ?Matrix3x3 = null,
    camera_calibration_signature: Text = .{},
    profile_calibration_signature: Text = .{},
    analog_balance: [3]f32 = .{ 1, 1, 1 },
    /// Backend-normalized camera-to-XYZ fallback for proprietary RAWs whose
    /// original DNG calibration tags are unavailable.
    camera_to_xyz: ?Matrix3x3 = null,
};

pub const SensorData = struct {
    width: u32,
    height: u32,
    /// Row-major 2x2 repeat pattern: [top-left, top-right, bot-left, bot-right].
    cfa: [4]CfaColor,
    black_level: f32,
    white_level: f32,
    /// Optional row-major 2×2 level maps for cameras with unequal sites.
    black_level_site: ?[4]f32 = null,
    white_level_site: ?[4]f32 = null,
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

pub const DecodedRaw = struct {
    sensor: SensorData,
    metadata: Metadata,

    pub fn deinit(self: *DecodedRaw, gpa: std.mem.Allocator) void {
        self.sensor.deinit(gpa);
        self.* = undefined;
    }
};

/// Malformed input is `Corrupt`; valid DNG using a feature this decoder
/// lacks gets an error naming the feature, so "cannot open" self-diagnoses
/// at the CLI and across the C ABI (both print the error name).
pub const Error = error{
    Corrupt,
    OutOfMemory,
    /// Canon CR2 is a valid proprietary RAW container, not malformed DNG.
    UnsupportedCr2,
    /// Canon CR3/CRX is a valid ISO-BMFF RAW container, not malformed DNG.
    UnsupportedCr3,
    /// Compression other than uncompressed (1) or lossless JPEG (7).
    UnsupportedCompression,
    /// Neither a strip layout nor a tile layout (or, corruptly, both).
    UnsupportedLayout,
    /// Sample storage other than 16 bits per sample, one sample per pixel.
    UnsupportedBitDepth,
    /// CFA patterns beyond the 2x2 Bayer family.
    UnsupportedCfa,
    /// Valid DNG containing already-demosaiced LinearRaw samples rather than
    /// the supported one-sample-per-pixel CFA mosaic.
    UnsupportedLinearRaw,
    /// Valid geometry that requires fractional crop coordinates or another
    /// transform outside the current integer crop profile.
    UnsupportedGeometry,
    /// Black-level repeat maps beyond the supported 2×2 CFA-site layout.
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
const tag_make: u16 = 271;
const tag_model: u16 = 272;
const tag_strip_offsets: u16 = 273;
const tag_orientation: u16 = 274;
const tag_samples_per_pixel: u16 = 277;
const tag_rows_per_strip: u16 = 278;
const tag_strip_byte_counts: u16 = 279;
const tag_datetime: u16 = 306;
const tag_sub_ifds: u16 = 330;
const tag_tile_width: u16 = 322;
const tag_tile_height: u16 = 323;
const tag_tile_offsets: u16 = 324;
const tag_tile_byte_counts: u16 = 325;
const tag_cfa_repeat_dim: u16 = 33421;
const tag_cfa_pattern: u16 = 33422;
const tag_exif_ifd: u16 = 34665;
const tag_iso_speed_ratings: u16 = 34855;
const tag_datetime_original: u16 = 36867;
const tag_subsec_time_original: u16 = 37521;
const tag_lens_model: u16 = 42036;
const tag_unique_camera_model: u16 = 50708;
const tag_black_level_repeat_dim: u16 = 50713;
const tag_black_level: u16 = 50714;
const tag_white_level: u16 = 50717;
const tag_default_crop_origin: u16 = 50719;
const tag_default_crop_size: u16 = 50720;
const tag_color_matrix_1: u16 = 50721;
const tag_color_matrix_2: u16 = 50722;
const tag_camera_calibration_1: u16 = 50723;
const tag_camera_calibration_2: u16 = 50724;
const tag_analog_balance: u16 = 50727;
const tag_as_shot_neutral: u16 = 50728;
const tag_calibration_illuminant_1: u16 = 50778;
const tag_calibration_illuminant_2: u16 = 50779;
const tag_active_area: u16 = 50829;
const tag_camera_calibration_signature: u16 = 50931;
const tag_profile_calibration_signature: u16 = 50932;

const photometric_cfa: u32 = 32803;
const photometric_linear_raw: u32 = 34892;

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
    if (bytes.len >= 12 and std.mem.eql(u8, bytes[8..12], "CR\x02\x00")) {
        return error.UnsupportedCr2;
    }
    if (bytes.len >= 12 and
        std.mem.eql(u8, bytes[4..8], "ftyp") and
        std.mem.eql(u8, bytes[8..12], "crx "))
    {
        return error.UnsupportedCr3;
    }
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

const IfdSelection = struct { raw: Ifd, first: Ifd, exif: ?Ifd };

/// Metadata-only import path: parses the same bounded IFD selection and the
/// same metadata function as full decode, without allocating or touching the
/// compressed pixel segments.
pub fn decode_metadata(bytes: []const u8) Error!Metadata {
    const r = try reader_init(bytes);
    const selected = try ifds_select(&r);
    return metadata_from_ifd(&r, &selected.raw, &selected.first, selected.exif);
}

/// Rich full decode. Engine v1 continues to consume `decode()` below, while
/// geometry and engine v2 can use the metadata without widening SensorData.
pub fn decode_raw(gpa: std.mem.Allocator, bytes: []const u8) Error!DecodedRaw {
    const r = try reader_init(bytes);
    const selected = try ifds_select(&r);
    const metadata = try metadata_from_ifd(
        &r,
        &selected.raw,
        &selected.first,
        selected.exif,
    );
    const sensor = try sensor_from_ifd(gpa, &r, &selected.raw, metadata);
    return .{ .sensor = sensor, .metadata = metadata };
}

/// Backward-compatible engine-v1 decode surface.
pub fn decode(gpa: std.mem.Allocator, bytes: []const u8) Error!SensorData {
    const raw = try decode_raw(gpa, bytes);
    return raw.sensor;
}

fn ifds_select(r: *const Reader) Error!IfdSelection {
    // Walk IFD0, its chain, and any SubIFDs, bounded by `ifd_visit_max` —
    // an explicit worklist, not recursion. The raw image is the first IFD
    // whose PhotometricInterpretation is CFA.
    var pending: [ifd_visit_max]u32 = undefined;
    var pending_len: u32 = 1;
    pending[0] = try r.read_u32(4);
    var visited: u32 = 0;
    var raw: ?Ifd = null;
    var linear_raw = false;
    var first: ?Ifd = null;

    while (pending_len > 0 and raw == null) {
        visited += 1;
        if (visited > ifd_visit_max) return error.UnsupportedStructure;
        pending_len -= 1;
        const off = pending[pending_len];
        if (off == 0) continue;

        const parsed = try ifd_parse(r, off);
        const ifd = parsed.ifd;
        if (first == null) first = ifd;
        if (ifd.find(tag_photometric)) |p| {
            const photometric = try value_scalar(r, p, 0);
            if (photometric == photometric_cfa) {
                raw = ifd;
                break;
            }
            linear_raw = linear_raw or photometric == photometric_linear_raw;
        }
        if (parsed.next != 0 and pending_len < ifd_visit_max) {
            pending[pending_len] = parsed.next;
            pending_len += 1;
        }
        if (ifd.find(tag_sub_ifds)) |subs| {
            var i: u32 = 0;
            while (i < subs.count and pending_len < ifd_visit_max) : (i += 1) {
                pending[pending_len] = try value_scalar(r, subs, i);
                pending_len += 1;
            }
        }
    }

    const first_ifd = first orelse return error.UnsupportedStructure;
    var exif: ?Ifd = null;
    if (first_ifd.find(tag_exif_ifd)) |entry| {
        if (entry.count != 1) return error.Corrupt;
        const parsed = try ifd_parse(r, try value_scalar(r, entry, 0));
        exif = parsed.ifd;
    }
    const raw_ifd = raw orelse {
        if (linear_raw) return error.UnsupportedLinearRaw;
        return error.UnsupportedStructure;
    };
    return .{
        .raw = raw_ifd,
        .first = first_ifd,
        .exif = exif,
    };
}

const compression_none: u32 = 1;
const compression_lossless_jpeg: u32 = 7;

fn metadata_from_ifd(
    r: *const Reader,
    ifd: *const Ifd,
    ifd0: *const Ifd,
    exif: ?Ifd,
) Error!Metadata {
    const exif_ptr: ?*const Ifd = if (exif) |*value| value else null;
    const width = try require_scalar(r, ifd, tag_image_width);
    const height = try require_scalar(r, ifd, tag_image_height);
    if (width == 0 or height == 0) return error.Corrupt;
    if (width > image.edge_px_max or height > image.edge_px_max) {
        return error.UnsupportedDimensions;
    }
    if (try require_scalar(r, ifd, tag_bits_per_sample) != 16) {
        return error.UnsupportedBitDepth;
    }
    if (try scalar_or(r, ifd, tag_samples_per_pixel, 1) != 1) {
        return error.UnsupportedBitDepth;
    }
    const compression_raw = try require_scalar(r, ifd, tag_compression);
    const compression: Compression = switch (compression_raw) {
        compression_none => .none,
        compression_lossless_jpeg => .lossless_jpeg,
        else => return error.UnsupportedCompression,
    };
    const cfa = try cfa_pattern(r, ifd);
    const black = try black_level_read(r, ifd);
    const white = try white_level_read(r, ifd);
    for (black.sites orelse @as([4]f32, @splat(black.scalar)), 0..) |level, index| {
        const white_level = if (white.sites) |sites| sites[index] else white.scalar;
        if (!(white_level > level)) return error.Corrupt;
    }
    const active_area = try active_area_read(r, ifd, width, height);
    const default_crop = try default_crop_read(r, ifd, active_area);

    return .{
        .width = width,
        .height = height,
        .compression = compression,
        .cfa = cfa,
        .black_level = black.scalar,
        .white_level = white.scalar,
        .black_level_site = black.sites,
        .white_level_site = white.sites,
        .wb_neutral = try as_shot_neutral(r, ifd, ifd0),
        .orientation = try orientation_read(r, ifd, ifd0),
        .active_area = active_area,
        .default_crop = default_crop,
        .make = try text_from_ifds(r, tag_make, ifd0, ifd, null),
        .model = try text_from_ifds(r, tag_model, ifd0, ifd, null),
        .unique_model = try text_from_ifds(
            r,
            tag_unique_camera_model,
            ifd0,
            ifd,
            null,
        ),
        .lens = try text_from_ifds(r, tag_lens_model, exif_ptr, ifd0, ifd),
        .iso = try fraction_from_ifds(r, tag_iso_speed_ratings, exif_ptr, ifd0, ifd),
        .capture_datetime = try capture_datetime_read(r, exif_ptr, ifd0),
        .capture_subsecond = try text_from_ifds(
            r,
            tag_subsec_time_original,
            exif_ptr,
            ifd0,
            null,
        ),
        .color_matrix_1 = try matrix_from_ifds(r, tag_color_matrix_1, ifd, ifd0),
        .color_matrix_2 = try matrix_from_ifds(r, tag_color_matrix_2, ifd, ifd0),
        .calibration_illuminant_1 = try integer_from_ifds(
            r,
            tag_calibration_illuminant_1,
            ifd,
            ifd0,
        ),
        .calibration_illuminant_2 = try integer_from_ifds(
            r,
            tag_calibration_illuminant_2,
            ifd,
            ifd0,
        ),
        .camera_calibration_1 = try matrix_from_ifds(
            r,
            tag_camera_calibration_1,
            ifd,
            ifd0,
        ),
        .camera_calibration_2 = try matrix_from_ifds(
            r,
            tag_camera_calibration_2,
            ifd,
            ifd0,
        ),
        .camera_calibration_signature = try signature_from_ifds(
            r,
            tag_camera_calibration_signature,
            ifd0,
            ifd,
            null,
        ),
        .profile_calibration_signature = try signature_from_ifds(
            r,
            tag_profile_calibration_signature,
            ifd0,
            ifd,
            null,
        ),
        .analog_balance = try analog_balance_read(r, ifd, ifd0),
    };
}

fn sensor_from_ifd(
    gpa: std.mem.Allocator,
    r: *const Reader,
    ifd: *const Ifd,
    metadata: Metadata,
) Error!SensorData {
    const compression: u32 = switch (metadata.compression) {
        .none => compression_none,
        .lossless_jpeg => compression_lossless_jpeg,
        .proprietary => unreachable,
    };
    const bayer = try bayer_read(gpa, r, ifd, metadata.width, metadata.height, compression);
    errdefer comptime unreachable; // no failure paths after this point

    assert(bayer.len == @as(usize, metadata.width) * metadata.height);
    assert(metadata.white_level > metadata.black_level);
    return .{
        .width = metadata.width,
        .height = metadata.height,
        .cfa = metadata.cfa,
        .black_level = metadata.black_level,
        .white_level = metadata.white_level,
        .black_level_site = metadata.black_level_site,
        .white_level_site = metadata.white_level_site,
        .wb_neutral = metadata.wb_neutral,
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

fn entry_from_ifds(
    tag: u16,
    first: ?*const Ifd,
    second: ?*const Ifd,
    third: ?*const Ifd,
) ?Entry {
    if (first) |ifd| if (ifd.find(tag)) |entry| return entry;
    if (second) |ifd| if (ifd.find(tag)) |entry| return entry;
    if (third) |ifd| if (ifd.find(tag)) |entry| return entry;
    return null;
}

fn text_from_ifds(
    r: *const Reader,
    tag: u16,
    first: ?*const Ifd,
    second: ?*const Ifd,
    third: ?*const Ifd,
) Error!Text {
    const entry = entry_from_ifds(tag, first, second, third) orelse return .{};
    if (entry.typ != type_ascii or entry.count == 0 or entry.count > 128) {
        return error.Corrupt;
    }
    const off = try value_off(r, entry, 0);
    const bytes = try r.slice(off, entry.count);
    const end = std.mem.indexOfScalar(u8, bytes, 0) orelse bytes.len;
    for (bytes[0..end]) |byte| {
        if (byte < 0x20 or byte > 0x7e) return error.Corrupt;
    }
    return Text.init(bytes[0..end]);
}

fn fraction_from_ifds(
    r: *const Reader,
    tag: u16,
    first: ?*const Ifd,
    second: ?*const Ifd,
    third: ?*const Ifd,
) Error!?f32 {
    const entry = entry_from_ifds(tag, first, second, third) orelse return null;
    if (entry.count == 0) return error.Corrupt;
    const value = try value_fraction(r, entry, 0);
    if (!(value > 0) or !std.math.isFinite(value)) return error.Corrupt;
    return value;
}

fn signature_from_ifds(
    r: *const Reader,
    tag: u16,
    first: ?*const Ifd,
    second: ?*const Ifd,
    third: ?*const Ifd,
) Error!Text {
    const entry = entry_from_ifds(tag, first, second, third) orelse return .{};
    if ((entry.typ != type_ascii and entry.typ != type_byte) or
        entry.count == 0 or entry.count > 128)
    {
        return error.Corrupt;
    }
    const off = try value_off(r, entry, 0);
    const bytes = try r.slice(off, entry.count);
    const end = std.mem.indexOfScalar(u8, bytes, 0) orelse bytes.len;
    if (!std.unicode.utf8ValidateSlice(bytes[0..end])) return error.Corrupt;
    return Text.init(bytes[0..end]);
}

fn capture_datetime_read(
    r: *const Reader,
    exif: ?*const Ifd,
    ifd0: *const Ifd,
) Error!Text {
    const original = try text_from_ifds(r, tag_datetime_original, exif, null, null);
    if (original.len != 0) return original;
    return text_from_ifds(r, tag_datetime, ifd0, null, null);
}

fn matrix_from_ifds(
    r: *const Reader,
    tag: u16,
    first: *const Ifd,
    second: *const Ifd,
) Error!?Matrix3x3 {
    const entry = first.find(tag) orelse second.find(tag) orelse return null;
    if (entry.typ != type_srational or entry.count != 9) return error.Corrupt;
    var matrix: Matrix3x3 = undefined;
    for (&matrix, 0..) |*value, index| {
        value.* = try value_fraction(r, entry, @intCast(index));
        if (!std.math.isFinite(value.*)) return error.Corrupt;
    }
    return matrix;
}

fn integer_from_ifds(
    r: *const Reader,
    tag: u16,
    first: *const Ifd,
    second: *const Ifd,
) Error!?u16 {
    const entry = first.find(tag) orelse second.find(tag) orelse return null;
    if (entry.typ != type_short or entry.count != 1) return error.Corrupt;
    const value = try value_scalar(r, entry, 0);
    if (value > std.math.maxInt(u16)) return error.Corrupt;
    return @intCast(value);
}

fn analog_balance_read(
    r: *const Reader,
    ifd: *const Ifd,
    ifd0: *const Ifd,
) Error![3]f32 {
    const entry = ifd.find(tag_analog_balance) orelse
        ifd0.find(tag_analog_balance) orelse return .{ 1, 1, 1 };
    if (entry.typ != type_rational or entry.count != 3) return error.Corrupt;
    var balance: [3]f32 = undefined;
    for (&balance, 0..) |*value, index| {
        value.* = try value_fraction(r, entry, @intCast(index));
        if (!(value.* > 0) or !std.math.isFinite(value.*)) return error.Corrupt;
    }
    return balance;
}

fn geometry_value(r: *const Reader, entry: Entry, index: u32) Error!u32 {
    const value = try value_fraction(r, entry, index);
    if (!std.math.isFinite(value) or value < 0) return error.Corrupt;
    if (@floor(value) != value) return error.UnsupportedGeometry;
    if (value > image.edge_px_max) return error.Corrupt;
    return @intFromFloat(value);
}

fn orientation_read(r: *const Reader, ifd: *const Ifd, ifd0: *const Ifd) Error!Orientation {
    const entry = ifd0.find(tag_orientation) orelse ifd.find(tag_orientation) orelse {
        return .normal;
    };
    if (entry.count != 1) return error.Corrupt;
    return switch (try value_scalar(r, entry, 0)) {
        1 => .normal,
        2 => .mirror_horizontal,
        3 => .rotate_180,
        4 => .mirror_vertical,
        5 => .transpose,
        6 => .rotate_90_clockwise,
        7 => .transverse,
        8 => .rotate_270_clockwise,
        else => error.Corrupt,
    };
}

fn active_area_read(
    r: *const Reader,
    ifd: *const Ifd,
    width: u32,
    height: u32,
) Error!Rect {
    const entry = ifd.find(tag_active_area) orelse {
        return .{ .x = 0, .y = 0, .width = width, .height = height };
    };
    if (entry.count != 4) return error.Corrupt;
    const top = try geometry_value(r, entry, 0);
    const left = try geometry_value(r, entry, 1);
    const bottom = try geometry_value(r, entry, 2);
    const right = try geometry_value(r, entry, 3);
    if (bottom <= top or right <= left) return error.Corrupt;
    if (bottom > height or right > width) return error.Corrupt;
    return .{ .x = left, .y = top, .width = right - left, .height = bottom - top };
}

fn default_crop_read(r: *const Reader, ifd: *const Ifd, active: Rect) Error!Rect {
    var x: u32 = 0;
    var y: u32 = 0;
    if (ifd.find(tag_default_crop_origin)) |entry| {
        if (entry.count != 2) return error.Corrupt;
        x = try geometry_value(r, entry, 0);
        y = try geometry_value(r, entry, 1);
    }
    var width = active.width;
    var height = active.height;
    if (ifd.find(tag_default_crop_size)) |entry| {
        if (entry.count != 2) return error.Corrupt;
        width = try geometry_value(r, entry, 0);
        height = try geometry_value(r, entry, 1);
    }
    if (width == 0 or height == 0) return error.Corrupt;
    if (@as(u64, x) + width > active.width) return error.Corrupt;
    if (@as(u64, y) + height > active.height) return error.Corrupt;
    return .{ .x = x, .y = y, .width = width, .height = height };
}

const Levels = struct { scalar: f32, sites: ?[4]f32 };

fn black_level_read(r: *const Reader, ifd: *const Ifd) Error!Levels {
    const entry = ifd.find(tag_black_level) orelse {
        return .{ .scalar = 0, .sites = null };
    };
    if (entry.count == 1) {
        return .{ .scalar = try value_fraction(r, entry, 0), .sites = null };
    }
    const repeat = ifd.find(tag_black_level_repeat_dim) orelse {
        return error.UnsupportedBlackLevel;
    };
    if (repeat.count != 2 or
        try value_scalar(r, repeat, 0) != 2 or
        try value_scalar(r, repeat, 1) != 2 or
        entry.count != 4)
    {
        return error.UnsupportedBlackLevel;
    }
    var sites: [4]f32 = undefined;
    var scalar = std.math.inf(f32);
    for (&sites, 0..) |*site, index| {
        site.* = try value_fraction(r, entry, @intCast(index));
        if (!std.math.isFinite(site.*) or site.* < 0) return error.Corrupt;
        scalar = @min(scalar, site.*);
    }
    return .{ .scalar = scalar, .sites = sites };
}

fn white_level_read(r: *const Reader, ifd: *const Ifd) Error!Levels {
    const entry = ifd.find(tag_white_level) orelse {
        return .{ .scalar = 65535, .sites = null };
    };
    if (entry.count != 1 and entry.count != 4) return error.Corrupt;
    var sites: [4]f32 = undefined;
    var scalar = std.math.inf(f32);
    for (0..entry.count) |index| {
        const value = try value_fraction(r, entry, @intCast(index));
        if (!std.math.isFinite(value) or value <= 0) return error.Corrupt;
        sites[index] = value;
        scalar = @min(scalar, value);
    }
    return .{
        .scalar = scalar,
        .sites = if (entry.count == 4) sites else null,
    };
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

test "proprietary Canon containers fail by actionable name" {
    const gpa = std.testing.allocator;
    try std.testing.expectError(
        error.UnsupportedCr2,
        decode(gpa, "II*\x00\x10\x00\x00\x00CR\x02\x00"),
    );
    try std.testing.expectError(
        error.UnsupportedCr3,
        decode(gpa, "\x00\x00\x00\x18ftypcrx "),
    );
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

fn test_entry_payload(blob: []const u8, tag: u16) u32 {
    const count = std.mem.readInt(u16, blob[8..10], .little);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const off = 10 + i * 12;
        if (std.mem.readInt(u16, blob[off..][0..2], .little) == tag) {
            return std.mem.readInt(u32, blob[off + 8 ..][0..4], .little);
        }
    }
    unreachable;
}

fn test_entry_type_patch(blob: []u8, tag: u16, typ: u16) void {
    const count = std.mem.readInt(u16, blob[8..10], .little);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const off = 10 + i * 12;
        if (std.mem.readInt(u16, blob[off..][0..2], .little) == tag) {
            std.mem.writeInt(u16, blob[off + 2 ..][0..2], typ, .little);
            return;
        }
    }
    unreachable;
}

fn test_entry_value_patch(blob: []u8, tag: u16, index: u32, value: u32) void {
    const count = std.mem.readInt(u16, blob[8..10], .little);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const off = 10 + i * 12;
        if (std.mem.readInt(u16, blob[off..][0..2], .little) != tag) continue;
        const typ = std.mem.readInt(u16, blob[off + 2 ..][0..2], .little);
        const value_count = std.mem.readInt(u32, blob[off + 4 ..][0..4], .little);
        assert(index < value_count);
        const size: u32 = switch (typ) {
            type_short => 2,
            type_long => 4,
            else => unreachable,
        };
        const base = if (size * value_count <= 4)
            off + 8
        else
            std.mem.readInt(u32, blob[off + 8 ..][0..4], .little);
        if (size == 2) {
            std.mem.writeInt(u16, blob[base + index * size ..][0..2], @intCast(value), .little);
        } else {
            std.mem.writeInt(u32, blob[base + index * size ..][0..4], value, .little);
        }
        return;
    }
    unreachable;
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
        .{
            .tag = tag_photometric,
            .payload = photometric_linear_raw,
            .expected = error.UnsupportedLinearRaw,
        },
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

test "geometry tags distinguish malformed bounds from unsupported fractions" {
    const gpa = std.testing.allocator;
    const dng_write = @import("dng_write.zig");
    const bayer = [_]u16{0} ** (6 * 4);
    const pristine = try dng_write.write(gpa, .{
        .width = 6,
        .height = 4,
        .wb_neutral = .{ 0.5, 1, 0.75 },
        .bayer = &bayer,
    });
    defer gpa.free(pristine);

    {
        const blob = try gpa.dupe(u8, pristine);
        defer gpa.free(blob);
        test_entry_patch(blob, tag_orientation, 9);
        try std.testing.expectError(error.Corrupt, decode_metadata(blob));
    }
    {
        const blob = try gpa.dupe(u8, pristine);
        defer gpa.free(blob);
        test_entry_value_patch(blob, tag_active_area, 2, 5);
        try std.testing.expectError(error.Corrupt, decode_metadata(blob));
    }
    {
        const blob = try gpa.dupe(u8, pristine);
        defer gpa.free(blob);
        test_entry_value_patch(blob, tag_default_crop_size, 0, 7);
        try std.testing.expectError(error.Corrupt, decode_metadata(blob));
    }
    {
        const blob = try gpa.dupe(u8, pristine);
        defer gpa.free(blob);
        const neutral_off = test_entry_payload(blob, tag_as_shot_neutral);
        test_entry_type_patch(blob, tag_default_crop_origin, type_rational);
        test_entry_patch(blob, tag_default_crop_origin, neutral_off);
        try std.testing.expectError(error.UnsupportedGeometry, decode_metadata(blob));
    }
}

fn test_ifd_entry(
    bytes: []u8,
    ifd: *Ifd,
    tag: u16,
    typ: u16,
    values_off: u32,
    count: u32,
) void {
    const payload_off = @as(u32, 4) * ifd.len;
    std.mem.writeInt(u32, bytes[payload_off..][0..4], values_off, .little);
    ifd.entries[ifd.len] = .{
        .tag = tag,
        .typ = typ,
        .count = count,
        .payload_off = payload_off,
    };
    ifd.len += 1;
}

fn test_srational_put(bytes: []u8, off: u32, numerator: i32, denominator: i32) void {
    std.mem.writeInt(u32, bytes[off..][0..4], @bitCast(numerator), .little);
    std.mem.writeInt(u32, bytes[off + 4 ..][0..4], @bitCast(denominator), .little);
}

test "identity, exposure, and calibration metadata values are bounded and typed" {
    var bytes: [1024]u8 = @splat(0);
    var ifd = Ifd{ .entries = undefined, .len = 0 };
    const make = "Banksia Camera\x00";
    @memcpy(bytes[128..][0..make.len], make);
    test_ifd_entry(&bytes, &ifd, tag_make, type_ascii, 128, make.len);

    const matrix = [9]i32{ 1, -2, 3, -4, 5, -6, 7, -8, 9 };
    for (matrix, 0..) |value, index| {
        test_srational_put(&bytes, 256 + @as(u32, @intCast(index)) * 8, value, 10);
    }
    test_ifd_entry(&bytes, &ifd, tag_color_matrix_1, type_srational, 256, 9);

    for ([3]u32{ 2, 1, 3 }, 0..) |value, index| {
        const off = 384 + @as(u32, @intCast(index)) * 8;
        std.mem.writeInt(u32, bytes[off..][0..4], value, .little);
        std.mem.writeInt(u32, bytes[off + 4 ..][0..4], 1, .little);
    }
    test_ifd_entry(&bytes, &ifd, tag_analog_balance, type_rational, 384, 3);

    const reader = Reader{ .bytes = &bytes, .endian = .little };
    const parsed_make = try text_from_ifds(&reader, tag_make, &ifd, null, null);
    try std.testing.expectEqualStrings("Banksia Camera", parsed_make.slice());
    const parsed_matrix = (try matrix_from_ifds(
        &reader,
        tag_color_matrix_1,
        &ifd,
        &ifd,
    )).?;
    for (parsed_matrix, matrix) |actual, numerator| {
        try std.testing.expectApproxEqAbs(
            @as(f32, @floatFromInt(numerator)) / 10,
            actual,
            1e-6,
        );
    }
    try std.testing.expectEqual(
        [3]f32{ 2, 1, 3 },
        try analog_balance_read(&reader, &ifd, &ifd),
    );
}

test "2x2 black and white maps retain every CFA site" {
    var bytes: [256]u8 = @splat(0);
    var ifd = Ifd{ .entries = undefined, .len = 0 };
    std.mem.writeInt(u32, bytes[128..132], 2, .little);
    std.mem.writeInt(u32, bytes[132..136], 2, .little);
    test_ifd_entry(&bytes, &ifd, tag_black_level_repeat_dim, type_long, 128, 2);
    for ([4]u32{ 100, 101, 102, 103 }, 0..) |value, index| {
        std.mem.writeInt(u32, bytes[144 + index * 4 ..][0..4], value, .little);
    }
    test_ifd_entry(&bytes, &ifd, tag_black_level, type_long, 144, 4);
    for ([4]u32{ 1000, 1001, 1002, 1003 }, 0..) |value, index| {
        std.mem.writeInt(u32, bytes[176 + index * 4 ..][0..4], value, .little);
    }
    test_ifd_entry(&bytes, &ifd, tag_white_level, type_long, 176, 4);

    const reader = Reader{ .bytes = &bytes, .endian = .little };
    const black = try black_level_read(&reader, &ifd);
    const white = try white_level_read(&reader, &ifd);
    try std.testing.expectEqual([4]f32{ 100, 101, 102, 103 }, black.sites.?);
    try std.testing.expectEqual([4]f32{ 1000, 1001, 1002, 1003 }, white.sites.?);
}
