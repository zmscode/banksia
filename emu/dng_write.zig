//! Synthetic DNG writer: the test-fixture generator.
//!
//! Writes the minimal valid little-endian CFA DNG that `dng.decode` reads
//! back, in every container shape the decoder supports: strip or tiled
//! layout, uncompressed or lossless-JPEG samples. The write/decode pair is
//! the format's pair assertion — a golden scene goes through the real
//! container path, so the decoder is exercised by every golden render, not
//! just by its own tests.

const std = @import("std");
const assert = std.debug.assert;
const dng = @import("dng.zig");
const image = @import("image.zig");
const jpeg_lossless = @import("jpeg_lossless.zig");

pub const Compression = enum { none, lossless_jpeg };

pub const Tile = struct { width: u32, height: u32 };

const identity_matrix: dng.Matrix3x3 = .{
    1, 0, 0,
    0, 1, 0,
    0, 0, 1,
};

pub const Description = struct {
    width: u32,
    height: u32,
    cfa: [4]dng.CfaColor = .{ .red, .green, .green, .blue },
    black_level: u16 = 0,
    white_level: u16 = 65535,
    wb_neutral: [3]f32 = .{ 1, 1, 1 },
    color_matrix_1: dng.Matrix3x3 = identity_matrix,
    camera_calibration_1: dng.Matrix3x3 = identity_matrix,
    analog_balance: [3]f32 = .{ 1, 1, 1 },
    calibration_illuminant_1: u16 = 23,
    orientation: dng.Orientation = .normal,
    /// Sensor-relative active pixels; null selects the full sensor.
    active_area: ?dng.Rect = null,
    /// Sensor-relative output crop; null selects the active area.
    default_crop: ?dng.Rect = null,
    /// Row-major mosaic, exactly `width * height` samples.
    bayer: []const u16,
    compression: Compression = .none,
    /// null writes one strip; set writes a tile grid, edges zero-padded
    /// like real DNGs pad theirs.
    tile: ?Tile = null,
};

const ifd_off: u32 = 8;
const tiles_max: u32 = 4096;

/// Fixed denominator for encoding f32 as RATIONAL. One part per million is
/// far below anything the pipeline can distinguish.
const fraction_denominator: u32 = 1_000_000;

const Geometry = struct {
    active_area: dng.Rect,
    default_crop: dng.Rect,
};

const Grid = struct {
    segment_width: u32,
    segment_height: u32,
    across: u32,
    down: u32,

    fn count(self: Grid) u32 {
        return self.across * self.down;
    }
};

pub fn write(gpa: std.mem.Allocator, desc: Description) ![]u8 {
    // Fixture descriptions come from our own tests; asserts, not errors.
    assert(desc.width > 0);
    assert(desc.height > 0);
    assert(desc.width <= image.edge_px_max);
    assert(desc.height <= image.edge_px_max);
    assert(desc.bayer.len == @as(usize, desc.width) * desc.height);
    assert(desc.white_level > desc.black_level);
    for (desc.wb_neutral) |n| assert(n > 0);
    const orientation = @intFromEnum(desc.orientation);
    assert(orientation >= 1 and orientation <= 8);
    const geometry = geometry_of(desc);

    const grid = grid_of(desc);
    assert(grid.count() >= 1);
    assert(grid.count() <= tiles_max);

    // Segment payloads build in an arena — sizes are unknowable up front
    // for lossless JPEG, and everything dies together after assembly.
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const payloads = try arena.alloc([]const u8, grid.count());
    for (payloads, 0..) |*payload, index| {
        payload.* = try segment_payload(arena, desc, grid, @intCast(index));
    }

    return assemble(gpa, desc, geometry, grid, payloads);
}

fn geometry_of(desc: Description) Geometry {
    const sensor = dng.Rect{ .x = 0, .y = 0, .width = desc.width, .height = desc.height };
    const active = desc.active_area orelse sensor;
    assert(active.width > 0);
    assert(active.height > 0);
    assert(active.width <= sensor.width);
    assert(active.height <= sensor.height);
    assert(active.x <= sensor.width - active.width);
    assert(active.y <= sensor.height - active.height);

    const crop = desc.default_crop orelse active;
    assert(crop.width > 0);
    assert(crop.height > 0);
    assert(crop.x >= active.x);
    assert(crop.y >= active.y);
    assert(crop.width <= active.width);
    assert(crop.height <= active.height);
    assert(crop.x - active.x <= active.width - crop.width);
    assert(crop.y - active.y <= active.height - crop.height);
    return .{ .active_area = active, .default_crop = crop };
}

fn grid_of(desc: Description) Grid {
    if (desc.tile) |tile| {
        assert(tile.width > 0);
        assert(tile.height > 0);
        return .{
            .segment_width = tile.width,
            .segment_height = tile.height,
            .across = (desc.width + tile.width - 1) / tile.width,
            .down = (desc.height + tile.height - 1) / tile.height,
        };
    }
    return .{
        .segment_width = desc.width,
        .segment_height = desc.height,
        .across = 1,
        .down = 1,
    };
}

/// One segment's stored bytes: samples gathered (zero-padded past the
/// border for tiles), then encoded per the description's compression.
fn segment_payload(
    arena: std.mem.Allocator,
    desc: Description,
    grid: Grid,
    index: u32,
) ![]const u8 {
    const x0 = (index % grid.across) * grid.segment_width;
    const y0 = (index / grid.across) * grid.segment_height;
    assert(x0 < desc.width);
    assert(y0 < desc.height);

    const samples = try arena.alloc(
        u16,
        @as(usize, grid.segment_width) * grid.segment_height,
    );
    @memset(samples, 0);
    var row: u32 = 0;
    while (row < grid.segment_height and y0 + row < desc.height) : (row += 1) {
        const copy_width = @min(grid.segment_width, desc.width - x0);
        const source = desc.bayer[@as(usize, y0 + row) * desc.width + x0 ..][0..copy_width];
        @memcpy(samples[@as(usize, row) * grid.segment_width ..][0..copy_width], source);
    }

    switch (desc.compression) {
        .none => {
            const bytes = try arena.alloc(u8, samples.len * 2);
            for (samples, 0..) |sample, i| {
                std.mem.writeInt(u16, bytes[i * 2 ..][0..2], sample, .little);
            }
            return bytes;
        },
        .lossless_jpeg => {
            // Two interleaved components when the width splits evenly —
            // the shape real DNGs use — otherwise one.
            const components: u32 = if (grid.segment_width % 2 == 0) 2 else 1;
            return jpeg_lossless.encode(
                arena,
                samples,
                grid.segment_width,
                grid.segment_height,
                components,
                16,
            );
        },
    }
}

/// Byte offsets of everything in the output, all even (TIFF wants
/// word-aligned values): header, IFD, out-of-line values, segment data.
const Assembly = struct {
    entry_count: u32,
    black_off: u32,
    neutral_off: u32,
    default_crop_origin_off: u32,
    default_crop_size_off: u32,
    color_matrix_1_off: u32,
    camera_calibration_1_off: u32,
    analog_balance_off: u32,
    active_area_off: u32,
    /// 0 when the single segment's values are stored inline.
    offsets_array_off: u32,
    byte_counts_array_off: u32,
    data_off: u32,
    total: u32,
};

fn assembly_plan(grid: Grid, payloads: []const []const u8, tiled: bool) Assembly {
    const entry_count: u32 = if (tiled) 25 else 24;
    const arrays = grid.count() > 1;
    const array_bytes: u64 = if (arrays) 4 * @as(u64, grid.count()) else 0;
    const values_off = @as(u64, ifd_off) + 2 + @as(u64, entry_count) * 12 + 4;
    const black_off = values_off;
    const neutral_off = black_off + 8;
    const default_crop_origin_off = neutral_off + 24;
    const default_crop_size_off = default_crop_origin_off + 8;
    const color_matrix_1_off = default_crop_size_off + 8;
    const camera_calibration_1_off = color_matrix_1_off + 72;
    const analog_balance_off = camera_calibration_1_off + 72;
    const active_area_off = analog_balance_off + 24;
    const offsets_array_off = active_area_off + 16;
    const byte_counts_array_off = offsets_array_off + array_bytes;
    const data_off = byte_counts_array_off + array_bytes;
    assert(data_off % 2 == 0);

    var total = data_off;
    for (payloads) |payload| {
        total += @as(u64, payload.len) + payload.len % 2;
    }
    assert(total <= std.math.maxInt(u32));
    return .{
        .entry_count = entry_count,
        .black_off = @intCast(black_off),
        .neutral_off = @intCast(neutral_off),
        .default_crop_origin_off = @intCast(default_crop_origin_off),
        .default_crop_size_off = @intCast(default_crop_size_off),
        .color_matrix_1_off = @intCast(color_matrix_1_off),
        .camera_calibration_1_off = @intCast(camera_calibration_1_off),
        .analog_balance_off = @intCast(analog_balance_off),
        .active_area_off = @intCast(active_area_off),
        .offsets_array_off = if (arrays) @intCast(offsets_array_off) else 0,
        .byte_counts_array_off = if (arrays) @intCast(byte_counts_array_off) else 0,
        .data_off = @intCast(data_off),
        .total = @intCast(total),
    };
}

fn assemble(
    gpa: std.mem.Allocator,
    desc: Description,
    geometry: Geometry,
    grid: Grid,
    payloads: []const []const u8,
) ![]u8 {
    const plan = assembly_plan(grid, payloads, desc.tile != null);
    const out = try gpa.alloc(u8, @intCast(plan.total));
    errdefer comptime unreachable; // single allocation; all writes below succeed
    @memset(out, 0);

    out[0] = 'I';
    out[1] = 'I';
    put_u16(out, 2, 42);
    put_u32(out, 4, ifd_off);
    entries_put(out, desc, grid, payloads, plan);

    fraction_put(out, plan.black_off, @floatFromInt(desc.black_level));
    for (desc.wb_neutral, 0..) |n, i| {
        fraction_put(out, plan.neutral_off + 8 * @as(u32, @intCast(i)), n);
    }
    const active = geometry.active_area;
    const crop = geometry.default_crop;
    put_u32(out, plan.default_crop_origin_off, crop.x - active.x);
    put_u32(out, plan.default_crop_origin_off + 4, crop.y - active.y);
    put_u32(out, plan.default_crop_size_off, crop.width);
    put_u32(out, plan.default_crop_size_off + 4, crop.height);
    for (desc.color_matrix_1, 0..) |value, index| {
        signed_fraction_put(
            out,
            plan.color_matrix_1_off + 8 * @as(u32, @intCast(index)),
            value,
        );
    }
    for (desc.camera_calibration_1, 0..) |value, index| {
        signed_fraction_put(
            out,
            plan.camera_calibration_1_off + 8 * @as(u32, @intCast(index)),
            value,
        );
    }
    for (desc.analog_balance, 0..) |value, index| {
        fraction_put(
            out,
            plan.analog_balance_off + 8 * @as(u32, @intCast(index)),
            value,
        );
    }
    put_u32(out, plan.active_area_off, active.y);
    put_u32(out, plan.active_area_off + 4, active.x);
    put_u32(out, plan.active_area_off + 8, active.y + active.height);
    put_u32(out, plan.active_area_off + 12, active.x + active.width);

    // Segment data, with the offset/byte-count arrays when out-of-line.
    var data_cursor: u64 = plan.data_off;
    for (payloads, 0..) |payload, index| {
        const i: u32 = @intCast(index);
        const data_off: u32 = @intCast(data_cursor);
        const payload_len: u32 = @intCast(payload.len);
        if (grid.count() > 1) {
            put_u32(out, plan.offsets_array_off + 4 * i, data_off);
            put_u32(out, plan.byte_counts_array_off + 4 * i, payload_len);
        }
        @memcpy(out[data_off..][0..payload.len], payload);
        data_cursor += @as(u64, payload_len) + payload_len % 2;
    }
    assert(data_cursor == plan.total);
    return out;
}

fn entries_put(
    out: []u8,
    desc: Description,
    grid: Grid,
    payloads: []const []const u8,
    plan: Assembly,
) void {
    const single = grid.count() == 1;
    const offsets_payload: u32 =
        if (single) plan.data_off else plan.offsets_array_off;
    const byte_counts_payload: u32 =
        if (single) @intCast(payloads[0].len) else plan.byte_counts_array_off;
    const compression: u32 = switch (desc.compression) {
        .none => 1,
        .lossless_jpeg => 7,
    };
    var pattern: u32 = 0;
    for (desc.cfa, 0..) |c, i| {
        pattern |= @as(u32, @intFromEnum(c)) << @intCast(8 * i);
    }

    put_u16(out, ifd_off, @intCast(plan.entry_count));
    var sink = EntrySink{ .out = out, .total = plan.entry_count };
    sink.put(254, type_long, 1, 0); // NewSubfileType: primary
    sink.put(256, type_long, 1, desc.width); // ImageWidth
    sink.put(257, type_long, 1, desc.height); // ImageLength
    sink.put(258, type_short, 1, 16); // BitsPerSample
    sink.put(259, type_short, 1, compression); // Compression
    sink.put(262, type_short, 1, 32803); // Photometric: CFA
    if (desc.tile == null) {
        sink.put(273, type_long, grid.count(), offsets_payload); // StripOffsets
    }
    sink.put(274, type_short, 1, @intCast(@intFromEnum(desc.orientation))); // Orientation
    sink.put(277, type_short, 1, 1); // SamplesPerPixel
    if (desc.tile == null) {
        sink.put(278, type_long, 1, desc.height); // RowsPerStrip
        sink.put(279, type_long, grid.count(), byte_counts_payload); // StripByteCounts
    } else {
        sink.put(322, type_long, 1, grid.segment_width); // TileWidth
        sink.put(323, type_long, 1, grid.segment_height); // TileLength
        sink.put(324, type_long, grid.count(), offsets_payload); // TileOffsets
        sink.put(325, type_long, grid.count(), byte_counts_payload); // TileByteCounts
    }
    sink.put(33421, type_short, 2, 2 | (2 << 16)); // CFARepeatPatternDim
    sink.put(33422, type_byte, 4, pattern); // CFAPattern
    sink.put(50706, type_byte, 4, 1 | (4 << 8)); // DNGVersion 1.4.0.0
    sink.put(50714, type_rational, 1, plan.black_off); // BlackLevel
    sink.put(50717, type_long, 1, desc.white_level); // WhiteLevel
    sink.put(50719, type_long, 2, plan.default_crop_origin_off); // DefaultCropOrigin
    sink.put(50720, type_long, 2, plan.default_crop_size_off); // DefaultCropSize
    sink.put(50721, type_srational, 9, plan.color_matrix_1_off); // ColorMatrix1
    sink.put(50723, type_srational, 9, plan.camera_calibration_1_off); // CameraCalibration1
    sink.put(50727, type_rational, 3, plan.analog_balance_off); // AnalogBalance
    sink.put(50728, type_rational, 3, plan.neutral_off); // AsShotNeutral
    sink.put(50778, type_short, 1, desc.calibration_illuminant_1); // CalibrationIlluminant1
    sink.put(50829, type_long, 4, plan.active_area_off); // ActiveArea
    assert(sink.index == plan.entry_count);
    put_u32(out, ifd_off + 2 + plan.entry_count * 12, 0); // no next IFD
}

const type_byte: u16 = 1;
const type_short: u16 = 3;
const type_long: u16 = 4;
const type_rational: u16 = 5;
const type_srational: u16 = 10;

const EntrySink = struct {
    out: []u8,
    total: u32,
    index: u32 = 0,

    fn put(self: *EntrySink, tag: u16, typ: u16, count: u32, payload: u32) void {
        assert(self.index < self.total);
        if (self.index > 0) {
            // Ascending tag order is a TIFF invariant; check against the
            // previous entry (negative space: also catches duplicates).
            const prev_off = ifd_off + 2 + (self.index - 1) * 12;
            const prev = std.mem.readInt(u16, self.out[prev_off..][0..2], .little);
            assert(tag > prev);
        }
        const off = ifd_off + 2 + self.index * 12;
        put_u16(self.out, off, tag);
        put_u16(self.out, off + 2, typ);
        put_u32(self.out, off + 4, count);
        put_u32(self.out, off + 8, payload);
        self.index += 1;
    }
};

fn put_u16(out: []u8, off: u32, v: u16) void {
    std.mem.writeInt(u16, out[off..][0..2], v, .little);
}

fn put_u32(out: []u8, off: u32, v: u32) void {
    std.mem.writeInt(u32, out[off..][0..4], v, .little);
}

fn fraction_put(out: []u8, off: u32, v: f32) void {
    assert(v >= 0);
    assert(v < 4000); // numerator must fit u32 at the fixed denominator
    const numerator: u32 = @intFromFloat(@round(v * fraction_denominator));
    put_u32(out, off, numerator);
    put_u32(out, off + 4, fraction_denominator);
}

fn signed_fraction_put(out: []u8, off: u32, v: f32) void {
    assert(v > -2000);
    assert(v < 2000);
    const numerator: i32 = @intFromFloat(@round(v * fraction_denominator));
    put_u32(out, off, @bitCast(numerator));
    put_u32(out, off + 4, fraction_denominator);
}

fn expect_tag_values(
    blob: []const u8,
    tag: u16,
    typ: u16,
    expected: []const u32,
) !void {
    const ifd = std.mem.readInt(u32, blob[4..8], .little);
    const count = std.mem.readInt(u16, blob[ifd..][0..2], .little);
    var entry_off: ?u32 = null;
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const off = ifd + 2 + i * 12;
        if (std.mem.readInt(u16, blob[off..][0..2], .little) == tag) {
            entry_off = off;
            break;
        }
    }
    const off = entry_off orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(typ, std.mem.readInt(u16, blob[off + 2 ..][0..2], .little));
    try std.testing.expectEqual(
        @as(u32, @intCast(expected.len)),
        std.mem.readInt(u32, blob[off + 4 ..][0..4], .little),
    );
    const value_size: u32 = switch (typ) {
        type_short => 2,
        type_long => 4,
        else => unreachable,
    };
    const value_bytes = @as(u64, value_size) * @as(u64, @intCast(expected.len));
    const value_off = if (value_bytes <= 4)
        off + 8
    else
        std.mem.readInt(u32, blob[off + 8 ..][0..4], .little);
    for (expected, 0..) |value, index| {
        const item_off = value_off + value_size * @as(u32, @intCast(index));
        const actual: u32 = switch (typ) {
            type_short => std.mem.readInt(u16, blob[item_off..][0..2], .little),
            type_long => std.mem.readInt(u32, blob[item_off..][0..4], .little),
            else => unreachable,
        };
        try std.testing.expectEqual(value, actual);
    }
}

test "write/decode roundtrip preserves every field and every sample" {
    const gpa = std.testing.allocator;
    var bayer: [6 * 4]u16 = undefined;
    for (&bayer, 0..) |*s, i| s.* = @intCast(100 + i * 37);

    const blob = try write(gpa, .{
        .width = 6,
        .height = 4,
        .cfa = .{ .blue, .green, .green, .red },
        .black_level = 128,
        .white_level = 16000,
        .wb_neutral = .{ 0.5, 1.0, 0.75 },
        .active_area = .{ .x = 1, .y = 1, .width = 4, .height = 2 },
        .default_crop = .{ .x = 2, .y = 1, .width = 2, .height = 2 },
        .bayer = &bayer,
    });
    defer gpa.free(blob);

    try expect_tag_values(blob, 274, type_short, &.{1});
    try expect_tag_values(blob, 50719, type_long, &.{ 1, 0 });
    try expect_tag_values(blob, 50720, type_long, &.{ 2, 2 });
    try expect_tag_values(blob, 50778, type_short, &.{23});
    try expect_tag_values(blob, 50829, type_long, &.{ 1, 1, 3, 5 });

    var raw = try dng.decode_raw(gpa, blob);
    defer raw.deinit(gpa);
    const sensor = &raw.sensor;
    const metadata = try dng.decode_metadata(blob);
    try std.testing.expectEqual(raw.metadata, metadata);
    try std.testing.expectEqual(dng.Orientation.normal, metadata.orientation);
    try std.testing.expectEqual(
        dng.Rect{ .x = 1, .y = 1, .width = 4, .height = 2 },
        metadata.active_area,
    );
    try std.testing.expectEqual(
        dng.Rect{ .x = 1, .y = 0, .width = 2, .height = 2 },
        metadata.default_crop,
    );
    try std.testing.expectEqual(identity_matrix, metadata.color_matrix_1.?);
    try std.testing.expectEqual(identity_matrix, metadata.camera_calibration_1.?);
    try std.testing.expectEqual([3]f32{ 1, 1, 1 }, metadata.analog_balance);
    try std.testing.expectEqual(@as(?u16, 23), metadata.calibration_illuminant_1);

    try std.testing.expectEqual(@as(u32, 6), sensor.width);
    try std.testing.expectEqual(@as(u32, 4), sensor.height);
    try std.testing.expectEqual(dng.CfaColor.blue, sensor.cfa[0]);
    try std.testing.expectEqual(dng.CfaColor.red, sensor.cfa[3]);
    try std.testing.expectEqual(@as(f32, 128), sensor.black_level);
    try std.testing.expectEqual(@as(f32, 16000), sensor.white_level);
    for (sensor.wb_neutral, [3]f32{ 0.5, 1.0, 0.75 }) |actual, expected| {
        try std.testing.expectApproxEqAbs(expected, actual, 1e-6);
    }
    try std.testing.expectEqualSlices(u16, &bayer, sensor.bayer);
}

test "all eight TIFF orientations roundtrip through metadata-only decode" {
    const gpa = std.testing.allocator;
    const bayer = [_]u16{ 100, 200, 300, 400 };
    const orientations = [_]dng.Orientation{
        .normal,
        .mirror_horizontal,
        .rotate_180,
        .mirror_vertical,
        .transpose,
        .rotate_90_clockwise,
        .transverse,
        .rotate_270_clockwise,
    };
    for (orientations) |orientation| {
        const blob = try write(gpa, .{
            .width = 2,
            .height = 2,
            .orientation = orientation,
            .bayer = &bayer,
        });
        defer gpa.free(blob);
        const metadata = try dng.decode_metadata(blob);
        try std.testing.expectEqual(orientation, metadata.orientation);
    }
}

test "roundtrip across every container shape the decoder supports" {
    const gpa = std.testing.allocator;
    // Odd dimensions and a tile grid that clips on both edges: 13 wide in
    // 8-wide tiles, 9 tall in 4-tall tiles (partial right column, partial
    // bottom row).
    var bayer: [13 * 9]u16 = undefined;
    for (&bayer, 0..) |*s, i| s.* = @intCast((i * 2654435761) % 65536);

    const shapes = [_]struct { compression: Compression, tile: ?Tile }{
        .{ .compression = .none, .tile = .{ .width = 8, .height = 4 } },
        .{ .compression = .lossless_jpeg, .tile = null },
        .{ .compression = .lossless_jpeg, .tile = .{ .width = 8, .height = 4 } },
    };
    for (shapes) |shape| {
        const blob = try write(gpa, .{
            .width = 13,
            .height = 9,
            .bayer = &bayer,
            .compression = shape.compression,
            .tile = shape.tile,
        });
        defer gpa.free(blob);
        var sensor = try dng.decode(gpa, blob);
        defer sensor.deinit(gpa);
        try std.testing.expectEqualSlices(u16, &bayer, sensor.bayer);
    }
}

test "the decoder rejects a corrupted fixture (negative space)" {
    const gpa = std.testing.allocator;
    const bayer = [_]u16{0} ** 4;
    const blob = try write(gpa, .{ .width = 2, .height = 2, .bayer = &bayer });
    defer gpa.free(blob);

    // Truncating the strip must be Corrupt, not a short read.
    const truncated = blob[0 .. blob.len - 2];
    // Import can still inspect intact metadata without touching pixel bytes.
    const metadata = try dng.decode_metadata(truncated);
    try std.testing.expectEqual(@as(u32, 2), metadata.width);
    try std.testing.expectError(error.Corrupt, dng.decode(gpa, truncated));
}
