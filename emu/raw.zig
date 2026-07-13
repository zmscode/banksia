//! Unified RAW decode dispatch.
//!
//! Native DNG is the deterministic reference backend. Recognized Canon CR2
//! and CR3 containers fall back to LibRaw at the sensor-mosaic boundary.

const std = @import("std");
const dng = @import("dng.zig");
const libraw = @import("libraw.zig");

pub const Error = dng.Error || libraw.Error;

pub fn decode_metadata(bytes: []const u8) Error!dng.Metadata {
    return dng.decode_metadata(bytes) catch |err| switch (err) {
        error.UnsupportedCr2,
        error.UnsupportedCr3,
        error.UnsupportedLinearRaw,
        => libraw.decode_metadata(bytes),
        else => return err,
    };
}

pub fn decode_raw(gpa: std.mem.Allocator, bytes: []const u8) Error!dng.DecodedRaw {
    return dng.decode_raw(gpa, bytes) catch |err| switch (err) {
        error.UnsupportedCr2,
        error.UnsupportedCr3,
        error.UnsupportedLinearRaw,
        => libraw.decode_raw(gpa, bytes),
        else => return err,
    };
}

pub fn decode(gpa: std.mem.Allocator, bytes: []const u8) Error!dng.SensorData {
    var decoded = try decode_raw(gpa, bytes);
    if (decoded.linear != null) {
        decoded.deinit(gpa);
        return error.UnsupportedLinearRaw;
    }
    return decoded.sensor;
}

test "synthetic DNG stays on the native backend" {
    const gpa = std.testing.allocator;
    const dng_write = @import("dng_write.zig");
    const bayer = [_]u16{ 1, 2, 3, 4 };
    const bytes = try dng_write.write(gpa, .{ .width = 2, .height = 2, .bayer = &bayer });
    defer gpa.free(bytes);

    const metadata = try decode_metadata(bytes);
    try std.testing.expectEqual(dng.Compression.none, metadata.compression);
    var sensor = try decode(gpa, bytes);
    defer sensor.deinit(gpa);
    try std.testing.expectEqualSlices(u16, &bayer, sensor.bayer);
}
