//! LibRaw sensor-data backend for proprietary RAW containers.
//!
//! This wrapper stops after `libraw_unpack`: it copies the visible CFA mosaic
//! and metadata into Banksia-owned structures. LibRaw's demosaic, colour,
//! brightness, and output encoding are deliberately not used.

const std = @import("std");
const color_math = @import("color.zig");
const dng = @import("dng.zig");
const image = @import("image.zig");

const c = @cImport({
    @cInclude("libraw/libraw.h");
});

pub const Error = error{
    OutOfMemory,
    LibRawInitFailed,
    LibRawOpenFailed,
    LibRawUnpackFailed,
    UnsupportedDimensions,
    UnsupportedCfa,
    UnsupportedRawLayout,
    InvalidMetadata,
};

pub fn version() []const u8 {
    return std.mem.span(c.libraw_version());
}

pub fn decode_metadata(bytes: []const u8) Error!dng.Metadata {
    const context = try context_open(bytes);
    defer c.libraw_close(context);
    // Proprietary maker metadata such as cblack may only settle during unpack.
    if (c.libraw_unpack(context) != 0) return error.LibRawUnpackFailed;
    return metadata_from_context(context);
}

pub fn decode_raw(gpa: std.mem.Allocator, bytes: []const u8) Error!dng.DecodedRaw {
    const context = try context_open(bytes);
    defer c.libraw_close(context);
    if (c.libraw_unpack(context) != 0) return error.LibRawUnpackFailed;

    const metadata = try metadata_from_context(context);
    if (context.idata.filters == 0) {
        return decode_linear_raw(gpa, context, metadata);
    }
    const sizes = context.sizes;
    const raw = context.rawdata.raw_image orelse return error.UnsupportedRawLayout;
    const pitch_samples = sizes.raw_pitch / @sizeOf(u16);
    if (sizes.raw_pitch % @sizeOf(u16) != 0) return error.UnsupportedRawLayout;
    if (pitch_samples < sizes.raw_width) return error.UnsupportedRawLayout;
    if (@as(u32, sizes.left_margin) + sizes.width > sizes.raw_width) {
        return error.InvalidMetadata;
    }
    if (@as(u32, sizes.top_margin) + sizes.height > sizes.raw_height) {
        return error.InvalidMetadata;
    }

    const count = @as(usize, metadata.width) * metadata.height;
    const bayer = try gpa.alloc(u16, count);
    errdefer gpa.free(bayer);
    var y: u32 = 0;
    while (y < metadata.height) : (y += 1) {
        const source_row = @as(usize, sizes.top_margin + y) * pitch_samples;
        const source_start = source_row + sizes.left_margin;
        const target_start = @as(usize, y) * metadata.width;
        @memcpy(
            bayer[target_start..][0..metadata.width],
            raw[source_start..][0..metadata.width],
        );
    }

    return .{
        .metadata = metadata,
        .sensor = .{
            .width = metadata.width,
            .height = metadata.height,
            .cfa = metadata.cfa,
            .black_level = metadata.black_level,
            .white_level = metadata.white_level,
            .black_level_site = metadata.black_level_site,
            .white_level_site = metadata.white_level_site,
            .wb_neutral = metadata.wb_neutral,
            .bayer = bayer,
        },
    };
}

fn decode_linear_raw(
    gpa: std.mem.Allocator,
    context: *c.libraw_data_t,
    metadata: dng.Metadata,
) Error!dng.DecodedRaw {
    const sizes = context.sizes;
    const source3 = context.rawdata.color3_image;
    const source4 = context.rawdata.color4_image;
    if (source3 == null and source4 == null) return error.UnsupportedRawLayout;
    const pixel_size: u32 = if (source3 != null)
        3 * @sizeOf(u16)
    else
        4 * @sizeOf(u16);
    if (sizes.raw_pitch % pixel_size != 0) return error.UnsupportedRawLayout;
    const pitch_pixels = sizes.raw_pitch / pixel_size;
    if (pitch_pixels < sizes.raw_width) return error.UnsupportedRawLayout;
    if (@as(u32, sizes.left_margin) + metadata.width > sizes.raw_width) {
        return error.InvalidMetadata;
    }
    if (@as(u32, sizes.top_margin) + metadata.height > sizes.raw_height) {
        return error.InvalidMetadata;
    }

    const sample_count = @as(usize, metadata.width) * metadata.height * 3;
    const rgb = try gpa.alloc(u16, sample_count);
    errdefer gpa.free(rgb);
    var y: u32 = 0;
    while (y < metadata.height) : (y += 1) {
        const source_row = @as(usize, sizes.top_margin + y) * pitch_pixels;
        const source_start = source_row + sizes.left_margin;
        var x: u32 = 0;
        while (x < metadata.width) : (x += 1) {
            const target = (@as(usize, y) * metadata.width + x) * 3;
            if (source3) |pixels| {
                const source_pixel = pixels[source_start + x];
                rgb[target] = source_pixel[0];
                rgb[target + 1] = source_pixel[1];
                rgb[target + 2] = source_pixel[2];
            } else if (source4) |pixels| {
                const source_pixel = pixels[source_start + x];
                rgb[target] = source_pixel[0];
                rgb[target + 1] = source_pixel[1];
                rgb[target + 2] = source_pixel[2];
            } else unreachable;
        }
    }

    const empty_bayer = try gpa.alloc(u16, 0);
    errdefer gpa.free(empty_bayer);
    return .{
        .metadata = metadata,
        .sensor = .{
            .width = metadata.width,
            .height = metadata.height,
            .cfa = metadata.cfa,
            .black_level = metadata.black_level,
            .white_level = metadata.white_level,
            .wb_neutral = metadata.wb_neutral,
            .bayer = empty_bayer,
        },
        .linear = .{
            .width = metadata.width,
            .height = metadata.height,
            .black_level = metadata.black_level,
            .white_level = metadata.white_level,
            .baseline_exposure_ev = context.color.dng_levels.baseline_exposure,
            .wb_neutral = metadata.wb_neutral,
            .rgb = rgb,
        },
    };
}

fn context_open(bytes: []const u8) Error!*c.libraw_data_t {
    const context = c.libraw_init(0) orelse return error.LibRawInitFailed;
    errdefer c.libraw_close(context);
    if (c.libraw_open_buffer(context, bytes.ptr, bytes.len) != 0) {
        return error.LibRawOpenFailed;
    }
    return context;
}

fn metadata_from_context(context: *c.libraw_data_t) Error!dng.Metadata {
    const sizes = context.sizes;
    const width: u32 = sizes.width;
    const height: u32 = sizes.height;
    if (width == 0 or height == 0) return error.InvalidMetadata;
    if (width > image.edge_px_max or height > image.edge_px_max) {
        return error.UnsupportedDimensions;
    }
    if (@as(u64, width) * height > image.pixel_count_max) {
        return error.UnsupportedDimensions;
    }

    const is_linear = context.idata.filters == 0;
    const black_sites = if (is_linear)
        @as([4]f32, @splat(@floatFromInt(context.color.black)))
    else
        try black_levels_read(context);
    const white: f32 = @floatFromInt(context.color.maximum);
    var black = black_sites[0];
    for (black_sites[1..]) |value| black = @min(black, value);
    for (black_sites) |value| {
        if (!(white > value)) return error.InvalidMetadata;
    }
    const default_crop = try default_crop_read(context);

    return .{
        .width = width,
        .height = height,
        .compression = .proprietary,
        .cfa = if (is_linear)
            .{ .red, .green, .green, .blue }
        else
            try cfa_read(context),
        .black_level = black,
        .white_level = white,
        .black_level_site = if (is_linear) null else black_sites,
        .white_level_site = if (is_linear) null else @splat(white),
        .wb_neutral = neutral_read(context),
        .orientation = orientation_from_flip(sizes.flip),
        .active_area = .{ .x = 0, .y = 0, .width = width, .height = height },
        .default_crop = default_crop,
        .make = c_text(&context.idata.make),
        .model = c_text(&context.idata.model),
        .lens = c_text(&context.lens.Lens),
        .lens_id = optional_identifier(context.lens.makernotes.LensID),
        .focal_length_mm = optional_positive(context.other.focal_len),
        .aperture_f_number = optional_positive(context.other.aperture),
        .iso = if (context.other.iso_speed > 0) context.other.iso_speed else null,
        .effective_iso = optional_positive(context.makernotes.common.real_ISO),
        .sensor_mode = if (context.makernotes.canon.SRAWQuality >= 0)
            @intCast(context.makernotes.canon.SRAWQuality)
        else
            null,
        .capture_time = if (context.other.timestamp > 0)
            @intCast(context.other.timestamp)
        else
            null,
        .camera_to_xyz = if (is_linear)
            try camera_to_xyz_linear_read(context)
        else
            try camera_to_xyz_read(context),
    };
}

fn optional_positive(value: anytype) ?f32 {
    const converted: f32 = @floatCast(value);
    if (!(converted > 0) or !std.math.isFinite(converted)) return null;
    return converted;
}

fn optional_identifier(value: anytype) ?u64 {
    const converted: u64 = @intCast(value);
    if (converted == 0 or converted == std.math.maxInt(u64)) return null;
    return converted;
}

fn default_crop_read(context: *const c.libraw_data_t) Error!dng.Rect {
    const sizes = context.sizes;
    const crop = sizes.raw_inset_crops[0];
    if (crop.cwidth == 0 or crop.cheight == 0) {
        return .{ .x = 0, .y = 0, .width = sizes.width, .height = sizes.height };
    }
    var x: u32 = crop.cleft;
    var y: u32 = crop.ctop;
    const width: u32 = crop.cwidth;
    const height: u32 = crop.cheight;
    if (@as(u64, x) + width > sizes.width or @as(u64, y) + height > sizes.height) {
        if (x < sizes.left_margin or y < sizes.top_margin) {
            return error.InvalidMetadata;
        }
        x -= sizes.left_margin;
        y -= sizes.top_margin;
    }
    if (@as(u64, x) + width > sizes.width or @as(u64, y) + height > sizes.height) {
        return error.InvalidMetadata;
    }
    return .{ .x = x, .y = y, .width = width, .height = height };
}

fn camera_to_xyz_read(context: *const c.libraw_data_t) Error!?dng.Matrix3x3 {
    return camera_to_xyz_from_libraw(context.color.cam_xyz);
}

fn camera_to_xyz_linear_read(context: *const c.libraw_data_t) Error!?dng.Matrix3x3 {
    if (try camera_to_xyz_read(context)) |matrix| return matrix;
    return camera_to_xyz_from_rgb_cam(context.color.rgb_cam);
}

fn camera_to_xyz_from_rgb_cam(rgb_cam: anytype) Error!?dng.Matrix3x3 {
    var camera_to_srgb: dng.Matrix3x3 = undefined;
    var nonzero = false;
    for (0..3) |srgb| {
        for (0..3) |camera| {
            const value = rgb_cam[srgb][camera];
            if (!std.math.isFinite(value)) return error.InvalidMetadata;
            nonzero = nonzero or value != 0;
            camera_to_srgb[srgb * 3 + camera] = value;
        }
    }
    if (!nonzero) return null;
    const linear_srgb_to_xyz_d65 = color_math.Mat3.init(.{
        0.4124564, 0.3575761, 0.1804375,
        0.2126729, 0.7151522, 0.0721750,
        0.0193339, 0.1191920, 0.9503041,
    });
    const result = linear_srgb_to_xyz_d65.multiply(color_math.Mat3.init(camera_to_srgb));
    return result.values;
}

fn camera_to_xyz_from_libraw(cam_xyz: anytype) Error!?dng.Matrix3x3 {
    var xyz_to_camera: dng.Matrix3x3 = undefined;
    var nonzero = false;
    for (0..3) |camera| {
        for (0..3) |xyz| {
            // Despite the historical cam_xyz name and API documentation,
            // LibRaw's per-camera table is the DNG-style XYZ-to-camera
            // matrix, indexed [camera channel][XYZ component]. Its own
            // raw-identify tool reports the same values as XYZ->CamRGB.
            const value = cam_xyz[camera][xyz];
            if (!std.math.isFinite(value)) return error.InvalidMetadata;
            nonzero = nonzero or value != 0;
            xyz_to_camera[camera * 3 + xyz] = value;
        }
    }
    if (!nonzero) return null;
    return (color_math.Mat3.init(xyz_to_camera).inverse() catch {
        return error.InvalidMetadata;
    }).values;
}

fn cfa_read(context: *c.libraw_data_t) Error![4]dng.CfaColor {
    if (context.idata.filters == 0) return error.UnsupportedCfa;
    const sizes = context.sizes;
    var pattern: [4]dng.CfaColor = undefined;
    var counts: [3]u8 = @splat(0);
    for (&pattern, 0..) |*site, index| {
        const y: c_int = @intCast(sizes.top_margin + index / 2);
        const x: c_int = @intCast(sizes.left_margin + index % 2);
        const color_index = c.libraw_COLOR(context, y, x);
        if (color_index < 0 or color_index >= 4) return error.UnsupportedCfa;
        const color = context.idata.cdesc[@intCast(color_index)];
        site.* = switch (color) {
            'R' => .red,
            'G' => .green,
            'B' => .blue,
            else => return error.UnsupportedCfa,
        };
        counts[@intFromEnum(site.*)] += 1;
    }
    if (!std.mem.eql(u8, &counts, &[3]u8{ 1, 2, 1 })) return error.UnsupportedCfa;
    return pattern;
}

fn black_levels_read(context: *c.libraw_data_t) Error![4]f32 {
    const cblack = context.color.cblack;
    const rows = cblack[4];
    const columns = cblack[5];
    const pattern_count = @as(u64, rows) * columns;
    if (pattern_count > cblack.len - 6) return error.InvalidMetadata;

    const sizes = context.sizes;
    var levels: [4]f32 = undefined;
    for (&levels, 0..) |*level, site| {
        const y = @as(u32, sizes.top_margin) + @as(u32, @intCast(site / 2));
        const x = @as(u32, sizes.left_margin) + @as(u32, @intCast(site % 2));
        const color = c.libraw_COLOR(context, @intCast(y), @intCast(x));
        if (color < 0 or color >= 4) return error.UnsupportedCfa;
        var value = context.color.black + cblack[@intCast(color)];
        if (rows > 0 and columns > 0) {
            const pattern_index = 6 + (y % rows) * columns + (x % columns);
            value += cblack[pattern_index];
        }
        level.* = @floatFromInt(value);
    }
    return levels;
}

fn neutral_read(context: *const c.libraw_data_t) [3]f32 {
    const multipliers = [3]f32{
        context.color.cam_mul[0],
        context.color.cam_mul[1],
        context.color.cam_mul[2],
    };
    for (multipliers) |value| {
        if (!(value > 0) or !std.math.isFinite(value)) return .{ 1, 1, 1 };
    }
    return .{ 1 / multipliers[0], 1 / multipliers[1], 1 / multipliers[2] };
}

fn orientation_from_flip(flip: c_int) dng.Orientation {
    return switch (flip) {
        3 => .rotate_180,
        5 => .rotate_270_clockwise,
        6 => .rotate_90_clockwise,
        else => .normal,
    };
}

fn c_text(array: anytype) dng.Text {
    const ptr: [*:0]const u8 = @ptrCast(array);
    return dng.Text.init(std.mem.span(ptr));
}

test "installed LibRaw exposes a supported version" {
    try std.testing.expect(std.mem.startsWith(u8, version(), "0.22."));
}

test "LibRaw XYZ-to-camera table is inverted at the backend boundary" {
    const cam_xyz = [4][3]f32{
        .{ 1, 2, 0 },
        .{ 0, 1, 3 },
        .{ 0, 0, 1 },
        .{ 0, 0, 0 },
    };
    const actual = (try camera_to_xyz_from_libraw(cam_xyz)).?;
    try std.testing.expectEqualSlices(f32, &.{
        1, -2, 6,
        0, 1,  -3,
        0, 0,  1,
    }, &actual);
}

test "native DNG and LibRaw agree at the sensor boundary" {
    const gpa = std.testing.allocator;
    const dng_write = @import("dng_write.zig");
    const bayer = try gpa.alloc(u16, 512 * 384);
    defer gpa.free(bayer);
    for (bayer, 0..) |*sample, index| sample.* = @intCast(1000 + index % 13000);
    const bytes = try dng_write.write(gpa, .{
        .width = 512,
        .height = 384,
        .black_level = 512,
        .white_level = 15000,
        .wb_neutral = .{ 0.5, 1, 0.75 },
        .bayer = bayer,
    });
    defer gpa.free(bytes);

    var native = try dng.decode_raw(gpa, bytes);
    defer native.deinit(gpa);
    var fallback = try decode_raw(gpa, bytes);
    defer fallback.deinit(gpa);

    try std.testing.expectEqual(native.metadata.width, fallback.metadata.width);
    try std.testing.expectEqual(native.metadata.height, fallback.metadata.height);
    try std.testing.expectEqual(native.metadata.cfa, fallback.metadata.cfa);
    try std.testing.expectEqual(native.metadata.orientation, fallback.metadata.orientation);
    try std.testing.expectEqual(native.metadata.default_crop, fallback.metadata.default_crop);
    try std.testing.expectEqualSlices(u16, native.sensor.bayer, fallback.sensor.bayer);
    try std.testing.expectApproxEqAbs(
        native.metadata.black_level,
        fallback.metadata.black_level,
        1,
    );
    try std.testing.expectApproxEqAbs(
        native.metadata.white_level,
        fallback.metadata.white_level,
        1,
    );
    // This intentionally anonymous synthetic camera has no LibRaw table.
    // Known proprietary cameras exercise the direct camera-to-XYZ fallback.
    try std.testing.expect(fallback.metadata.camera_to_xyz == null);
}
