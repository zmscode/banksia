//! Synthetic DNG writer: the test-fixture generator.
//!
//! Writes the minimal valid little-endian uncompressed CFA DNG that
//! `dng.decode` reads back. The write/decode pair is the format's pair
//! assertion: a golden scene goes through the real container path, so the
//! decoder is exercised by every golden render, not just by its own tests.

const std = @import("std");
const assert = std.debug.assert;
const dng = @import("dng.zig");
const image = @import("image.zig");

pub const Description = struct {
    width: u32,
    height: u32,
    cfa: [4]dng.CfaColor = .{ .red, .green, .green, .blue },
    black_level: u16 = 0,
    white_level: u16 = 65535,
    wb_neutral: [3]f32 = .{ 1, 1, 1 },
    /// Row-major mosaic, exactly `width * height` samples.
    bayer: []const u16,
};

const entry_count: u32 = 16;
const ifd_off: u32 = 8;
const values_off: u32 = ifd_off + 2 + entry_count * 12 + 4;
const black_off: u32 = values_off; // RATIONAL, 8 bytes
const neutral_off: u32 = black_off + 8; // RATIONAL x3, 24 bytes
const data_off: u32 = neutral_off + 24;

comptime {
    // TIFF wants even value offsets; the strip must start word-aligned.
    assert(values_off % 2 == 0);
    assert(data_off % 2 == 0);
}

/// Fixed denominator for encoding f32 as RATIONAL. One part per million is
/// far below anything the pipeline can distinguish.
const fraction_denominator: u32 = 1_000_000;

pub fn write(gpa: std.mem.Allocator, desc: Description) ![]u8 {
    // Fixture descriptions come from our own tests; asserts, not errors.
    assert(desc.width > 0);
    assert(desc.height > 0);
    assert(desc.width <= image.edge_px_max);
    assert(desc.height <= image.edge_px_max);
    assert(desc.bayer.len == @as(usize, desc.width) * desc.height);
    assert(desc.white_level > desc.black_level);
    for (desc.wb_neutral) |n| assert(n > 0);

    const data_len = @as(u64, desc.width) * desc.height * 2;
    const total = @as(u64, data_off) + data_len;
    const out = try gpa.alloc(u8, @intCast(total));
    errdefer comptime unreachable; // single allocation; all writes below succeed

    // Header: little-endian, magic 42, IFD0 at offset 8.
    out[0] = 'I';
    out[1] = 'I';
    put_u16(out, 2, 42);
    put_u32(out, 4, ifd_off);
    put_u16(out, ifd_off, @intCast(entry_count));

    const w = desc.width;
    const h = desc.height;
    var pattern: u32 = 0;
    for (desc.cfa, 0..) |c, i| {
        pattern |= @as(u32, @intFromEnum(c)) << @intCast(8 * i);
    }

    // Entries, ascending tag order as TIFF requires.
    var index: u32 = 0;
    entry_put(out, &index, 254, type_long, 1, 0); // NewSubfileType: primary
    entry_put(out, &index, 256, type_long, 1, w); // ImageWidth
    entry_put(out, &index, 257, type_long, 1, h); // ImageLength
    entry_put(out, &index, 258, type_short, 1, 16); // BitsPerSample
    entry_put(out, &index, 259, type_short, 1, 1); // Compression: none
    entry_put(out, &index, 262, type_short, 1, 32803); // Photometric: CFA
    entry_put(out, &index, 273, type_long, 1, data_off); // StripOffsets
    entry_put(out, &index, 277, type_short, 1, 1); // SamplesPerPixel
    entry_put(out, &index, 278, type_long, 1, h); // RowsPerStrip
    entry_put(out, &index, 279, type_long, 1, @intCast(data_len)); // StripByteCounts
    entry_put(out, &index, 33421, type_short, 2, 2 | (2 << 16)); // CFARepeatPatternDim
    entry_put(out, &index, 33422, type_byte, 4, pattern); // CFAPattern
    entry_put(out, &index, 50706, type_byte, 4, 1 | (4 << 8)); // DNGVersion 1.4.0.0
    entry_put(out, &index, 50714, type_rational, 1, black_off); // BlackLevel
    entry_put(out, &index, 50717, type_long, 1, desc.white_level); // WhiteLevel
    entry_put(out, &index, 50728, type_rational, 3, neutral_off); // AsShotNeutral
    assert(index == entry_count);
    put_u32(out, ifd_off + 2 + entry_count * 12, 0); // no next IFD

    fraction_put(out, black_off, @floatFromInt(desc.black_level));
    for (desc.wb_neutral, 0..) |n, i| {
        fraction_put(out, neutral_off + 8 * @as(u32, @intCast(i)), n);
    }

    for (desc.bayer, 0..) |sample, i| {
        put_u16(out, data_off + 2 * @as(u32, @intCast(i)), sample);
    }
    return out;
}

const type_byte: u16 = 1;
const type_short: u16 = 3;
const type_long: u16 = 4;
const type_rational: u16 = 5;

fn entry_put(out: []u8, index: *u32, tag: u16, typ: u16, count: u32, payload: u32) void {
    assert(index.* < entry_count);
    if (index.* > 0) {
        // Ascending tag order is a TIFF invariant; check against the
        // previous entry (negative space: also catches duplicate tags).
        const prev = std.mem.readInt(u16, out[ifd_off + 2 + (index.* - 1) * 12 ..][0..2], .little);
        assert(tag > prev);
    }
    const off = ifd_off + 2 + index.* * 12;
    put_u16(out, off, tag);
    put_u16(out, off + 2, typ);
    put_u32(out, off + 4, count);
    put_u32(out, off + 8, payload);
    index.* += 1;
}

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
        .bayer = &bayer,
    });
    defer gpa.free(blob);

    var sensor = try dng.decode(gpa, blob);
    defer sensor.deinit(gpa);

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

test "the decoder rejects a corrupted fixture (negative space)" {
    const gpa = std.testing.allocator;
    const bayer = [_]u16{0} ** 4;
    const blob = try write(gpa, .{ .width = 2, .height = 2, .bayer = &bayer });
    defer gpa.free(blob);

    // Truncating the strip must be Corrupt, not a short read.
    try std.testing.expectError(
        error.Corrupt,
        dng.decode(gpa, blob[0 .. blob.len - 2]),
    );
}
