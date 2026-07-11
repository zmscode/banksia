//! Sensor, crop, and oriented-output coordinate transforms.

const std = @import("std");
const assert = std.debug.assert;
const dng = @import("dng.zig");

pub const Point = struct { x: u32, y: u32 };
pub const Dimensions = struct { width: u32, height: u32 };

/// Maps the DNG default crop to an upright output lattice. Sensor coordinates
/// address the decoded mosaic; output coordinates address the oriented crop.
pub const Transform = struct {
    crop: dng.Rect,
    orientation: dng.Orientation,

    pub fn init(metadata: dng.Metadata) Transform {
        const crop = dng.Rect{
            .x = metadata.active_area.x + metadata.default_crop.x,
            .y = metadata.active_area.y + metadata.default_crop.y,
            .width = metadata.default_crop.width,
            .height = metadata.default_crop.height,
        };
        assert(crop.x + crop.width <= metadata.width);
        assert(crop.y + crop.height <= metadata.height);
        return .{ .crop = crop, .orientation = metadata.orientation };
    }

    pub fn output_dimensions(self: Transform) Dimensions {
        return switch (self.orientation) {
            .normal, .mirror_horizontal, .rotate_180, .mirror_vertical => .{
                .width = self.crop.width,
                .height = self.crop.height,
            },
            .transpose, .rotate_90_clockwise, .transverse, .rotate_270_clockwise => .{
                .width = self.crop.height,
                .height = self.crop.width,
            },
        };
    }

    pub fn output_to_sensor(self: Transform, output: Point) Point {
        const dimensions = self.output_dimensions();
        assert(output.x < dimensions.width);
        assert(output.y < dimensions.height);
        const w = self.crop.width;
        const h = self.crop.height;
        const local: Point = switch (self.orientation) {
            .normal => .{ .x = output.x, .y = output.y },
            .mirror_horizontal => .{ .x = w - 1 - output.x, .y = output.y },
            .rotate_180 => .{ .x = w - 1 - output.x, .y = h - 1 - output.y },
            .mirror_vertical => .{ .x = output.x, .y = h - 1 - output.y },
            .transpose => .{ .x = output.y, .y = output.x },
            .rotate_90_clockwise => .{ .x = output.y, .y = h - 1 - output.x },
            .transverse => .{ .x = w - 1 - output.y, .y = h - 1 - output.x },
            .rotate_270_clockwise => .{ .x = w - 1 - output.y, .y = output.x },
        };
        return .{ .x = self.crop.x + local.x, .y = self.crop.y + local.y };
    }

    pub fn sensor_to_output(self: Transform, sensor: Point) Point {
        assert(sensor.x >= self.crop.x and sensor.x < self.crop.x + self.crop.width);
        assert(sensor.y >= self.crop.y and sensor.y < self.crop.y + self.crop.height);
        const local = Point{ .x = sensor.x - self.crop.x, .y = sensor.y - self.crop.y };
        const w = self.crop.width;
        const h = self.crop.height;
        return switch (self.orientation) {
            .normal => local,
            .mirror_horizontal => .{ .x = w - 1 - local.x, .y = local.y },
            .rotate_180 => .{ .x = w - 1 - local.x, .y = h - 1 - local.y },
            .mirror_vertical => .{ .x = local.x, .y = h - 1 - local.y },
            .transpose => .{ .x = local.y, .y = local.x },
            .rotate_90_clockwise => .{ .x = h - 1 - local.y, .y = local.x },
            .transverse => .{ .x = h - 1 - local.y, .y = w - 1 - local.x },
            .rotate_270_clockwise => .{ .x = local.y, .y = w - 1 - local.x },
        };
    }
};

fn test_metadata(orientation: dng.Orientation) dng.Metadata {
    return .{
        .width = 7,
        .height = 6,
        .compression = .none,
        .cfa = .{ .red, .green, .green, .blue },
        .black_level = 0,
        .white_level = 100,
        .wb_neutral = .{ 1, 1, 1 },
        .orientation = orientation,
        .active_area = .{ .x = 1, .y = 2, .width = 5, .height = 3 },
        .default_crop = .{ .x = 1, .y = 0, .width = 3, .height = 2 },
    };
}

test "all TIFF orientations are bijections over the default crop" {
    const orientations = std.enums.values(dng.Orientation);
    for (orientations) |orientation| {
        const transform = Transform.init(test_metadata(orientation));
        const dimensions = transform.output_dimensions();
        var y: u32 = 0;
        while (y < dimensions.height) : (y += 1) {
            var x: u32 = 0;
            while (x < dimensions.width) : (x += 1) {
                const output = Point{ .x = x, .y = y };
                const sensor = transform.output_to_sensor(output);
                try std.testing.expectEqual(output, transform.sensor_to_output(sensor));
            }
        }
    }
}

test "orientation mappings match TIFF's eight visual layouts" {
    const expected = [_][]const u8{
        "abcdef",
        "cbafed",
        "fedcba",
        "defabc",
        "adbecf",
        "daebfc",
        "fcebda",
        "cfbead",
    };
    for (std.enums.values(dng.Orientation), expected) |orientation, layout| {
        var metadata = test_metadata(orientation);
        metadata.active_area = .{ .x = 0, .y = 0, .width = 3, .height = 2 };
        metadata.default_crop = metadata.active_area;
        const transform = Transform.init(metadata);
        var actual: [6]u8 = undefined;
        const dimensions = transform.output_dimensions();
        for (&actual, 0..) |*value, index| {
            const output = Point{
                .x = @intCast(index % dimensions.width),
                .y = @intCast(index / dimensions.width),
            };
            const sensor = transform.output_to_sensor(output);
            value.* = "abcdef"[sensor.y * 3 + sensor.x];
        }
        try std.testing.expectEqualStrings(layout, &actual);
    }
}
