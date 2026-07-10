//! Minimal PNG encoder: RGBA8, filter 0, stored (uncompressed) deflate
//! blocks inside a zlib stream. Zero dependencies; std.hash provides the
//! CRC-32 and Adler-32. Compression is deliberately absent — this exists
//! so the CLI and golden harness have a viewable, lossless output format,
//! not to win a size contest.

const std = @import("std");
const assert = std.debug.assert;
const image = @import("image.zig");

const signature = [8]u8{ 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n' };

/// A stored deflate block carries at most 65535 bytes.
const stored_block_bytes_max: usize = 65535;

pub fn encode_rgba(
    gpa: std.mem.Allocator,
    width: u32,
    height: u32,
    rgba: []const u8,
) ![]u8 {
    assert(width > 0);
    assert(height > 0);
    assert(width <= image.edge_px_max);
    assert(height <= image.edge_px_max);
    assert(rgba.len == @as(usize, width) * height * 4);

    // Raw scanline stream: each row is one filter byte (0 = none) + pixels.
    const row_bytes = 1 + @as(usize, width) * 4;
    const raw = try gpa.alloc(u8, row_bytes * height);
    defer gpa.free(raw);
    var y: usize = 0;
    while (y < height) : (y += 1) {
        raw[y * row_bytes] = 0;
        const src = rgba[y * @as(usize, width) * 4 ..][0 .. @as(usize, width) * 4];
        @memcpy(raw[y * row_bytes + 1 ..][0..src.len], src);
    }

    const idat = try zlib_stored(gpa, raw);
    defer gpa.free(idat);

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(gpa);
    try out.appendSlice(gpa, &signature);

    var ihdr: [13]u8 = undefined;
    std.mem.writeInt(u32, ihdr[0..4], width, .big);
    std.mem.writeInt(u32, ihdr[4..8], height, .big);
    ihdr[8] = 8; // bit depth
    ihdr[9] = 6; // color type: RGBA
    ihdr[10] = 0; // compression
    ihdr[11] = 0; // filter method
    ihdr[12] = 0; // no interlace
    try chunk_append(gpa, &out, "IHDR", &ihdr);
    try chunk_append(gpa, &out, "IDAT", idat);
    try chunk_append(gpa, &out, "IEND", "");
    return out.toOwnedSlice(gpa);
}

/// zlib wrapper around stored deflate blocks: header, N stored blocks,
/// Adler-32 of the raw stream.
fn zlib_stored(gpa: std.mem.Allocator, raw: []const u8) ![]u8 {
    assert(raw.len > 0);
    const block_count = std.math.divCeil(usize, raw.len, stored_block_bytes_max) catch unreachable;
    assert(block_count > 0);

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(gpa);
    try out.ensureTotalCapacity(gpa, 2 + raw.len + block_count * 5 + 4);
    // CMF/FLG: 32K window deflate, no dict, check bits valid (0x78 0x01).
    out.appendSliceAssumeCapacity(&.{ 0x78, 0x01 });

    var off: usize = 0;
    while (off < raw.len) {
        const len = @min(stored_block_bytes_max, raw.len - off);
        const final: u8 = if (off + len == raw.len) 1 else 0;
        out.appendAssumeCapacity(final); // BFINAL + BTYPE=00 (stored)
        var header: [4]u8 = undefined;
        std.mem.writeInt(u16, header[0..2], @intCast(len), .little);
        std.mem.writeInt(u16, header[2..4], ~@as(u16, @intCast(len)), .little);
        out.appendSliceAssumeCapacity(&header);
        out.appendSliceAssumeCapacity(raw[off..][0..len]);
        off += len;
    }
    assert(off == raw.len);

    var adler: [4]u8 = undefined;
    std.mem.writeInt(u32, &adler, std.hash.Adler32.hash(raw), .big);
    out.appendSliceAssumeCapacity(&adler);
    return out.toOwnedSlice(gpa);
}

fn chunk_append(
    gpa: std.mem.Allocator,
    out: *std.ArrayList(u8),
    kind: *const [4]u8,
    data: []const u8,
) !void {
    assert(data.len <= std.math.maxInt(u32));
    var word: [4]u8 = undefined;
    std.mem.writeInt(u32, &word, @intCast(data.len), .big);
    try out.appendSlice(gpa, &word);
    try out.appendSlice(gpa, kind);
    try out.appendSlice(gpa, data);

    var crc = std.hash.Crc32.init();
    crc.update(kind);
    crc.update(data);
    std.mem.writeInt(u32, &word, crc.final(), .big);
    try out.appendSlice(gpa, &word);
}

test "encode produces a structurally valid PNG that roundtrips its pixels" {
    const gpa = std.testing.allocator;
    const width = 3;
    const height = 2;
    const pixels = [width * height * 4]u8{
        255, 0,   0,   255, 0,   255, 0,   255, 0,   0,   255, 255,
        10,  20,  30,  255, 200, 200, 200, 255, 0,   0,   0,   255,
    };
    const png = try encode_rgba(gpa, width, height, &pixels);
    defer gpa.free(png);

    try std.testing.expectEqualSlices(u8, &signature, png[0..8]);

    // Walk the chunks: IHDR dims, then reconstruct the raw stream from the
    // stored deflate blocks and compare every pixel byte (the roundtrip is
    // the pair assertion for the writer).
    const ihdr_len = std.mem.readInt(u32, png[8..12], .big);
    try std.testing.expectEqual(@as(u32, 13), ihdr_len);
    try std.testing.expectEqualStrings("IHDR", png[12..16]);
    try std.testing.expectEqual(width, std.mem.readInt(u32, png[16..20], .big));
    try std.testing.expectEqual(height, std.mem.readInt(u32, png[20..24], .big));

    const idat_off = 8 + 12 + 13;
    const idat_len = std.mem.readInt(u32, png[idat_off..][0..4], .big);
    try std.testing.expectEqualStrings("IDAT", png[idat_off + 4 ..][0..4]);
    const zlib = png[idat_off + 8 ..][0..idat_len];

    // One stored block expected at this size: 0x78 0x01, BFINAL|stored,
    // LEN, ~LEN, payload.
    try std.testing.expectEqual(@as(u8, 0x78), zlib[0]);
    try std.testing.expectEqual(@as(u8, 1), zlib[2]);
    const len = std.mem.readInt(u16, zlib[3..5], .little);
    const raw = zlib[7..][0..len];
    const row_bytes = 1 + width * 4;
    try std.testing.expectEqual(@as(usize, row_bytes * height), raw.len);
    for (0..height) |row| {
        try std.testing.expectEqual(@as(u8, 0), raw[row * row_bytes]);
        try std.testing.expectEqualSlices(
            u8,
            pixels[row * width * 4 ..][0 .. width * 4],
            raw[row * row_bytes + 1 ..][0 .. width * 4],
        );
    }
}
