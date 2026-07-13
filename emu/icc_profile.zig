//! Strict ICC `mft2` camera-profile reference.
//!
//! The immutable database record retains all big-endian ICC payloads. This
//! module evaluates the A2B0 transform as input shapers, matrix, tetrahedral
//! three-dimensional CLUT, output tables, ICC v2 Lab PCS decode, D50 XYZ, and
//! finally linear Rec.2020. Camera RGB inputs are bounded to the ICC device
//! domain; finite out-of-gamut working values remain unclipped.

const std = @import("std");
const assert = std.debug.assert;
const calibration = @import("calibration.zig");
const color = @import("color.zig");
const image = @import("image.zig");

pub const Error = error{
    UnsupportedChannels,
    InvalidGrid,
    InvalidTable,
    InvalidMatrix,
};

pub const Lab = struct {
    l: f32,
    a: f32,
    b: f32,
};

pub const Profile = struct {
    mft2: *const calibration.Mft2,
    matrix: color.Mat3,

    pub fn init(mft2: *const calibration.Mft2) Error!Profile {
        if (mft2.input_channels != 3 or mft2.output_channels != 3) {
            return error.UnsupportedChannels;
        }
        if (mft2.grid_points < 2) return error.InvalidGrid;
        if (mft2.input_entries < 2 or mft2.output_entries < 2) {
            return error.InvalidTable;
        }
        if (mft2.matrix_s15fixed16.len != 9 * 4) return error.InvalidMatrix;
        const matrix = decodeMatrix(mft2.matrix_s15fixed16);
        for (matrix.values) |value| {
            if (!std.math.isFinite(value)) return error.InvalidMatrix;
        }
        return .{ .mft2 = mft2, .matrix = matrix };
    }

    pub fn isBootstrapCanonical(profile: Profile) bool {
        return profile.mft2.grid_points == 33 and
            profile.mft2.input_entries == 1025 and
            profile.mft2.output_entries == 2;
    }

    pub fn evaluateLab(profile: Profile, camera_rgb: [3]f32) Lab {
        var shaped: [3]f32 = undefined;
        for (&shaped, camera_rgb, 0..) |*target, value, channel| {
            target.* = table(
                profile.mft2.input_tables_u16be,
                profile.mft2.input_entries,
                channel,
                bounded(value),
            );
        }

        const coordinates = profile.matrix.vector(shaped);
        var bounded_coordinates: [3]f32 = undefined;
        for (&bounded_coordinates, coordinates) |*target, value| {
            target.* = bounded(value);
        }
        var encoded = profile.tetrahedral(bounded_coordinates);
        for (&encoded, 0..) |*value, channel| {
            value.* = table(
                profile.mft2.output_tables_u16be,
                profile.mft2.output_entries,
                channel,
                value.*,
            );
        }

        // ICC v2 Lab16: L* spans 0x0000..0xff00; a*/b* are unsigned values
        // with 0x8000 representing zero and one code step equal to 1/256.
        return .{
            .l = encoded[0] * (65_535.0 / 65_280.0) * 100,
            .a = encoded[1] * (65_535.0 / 256.0) - 128,
            .b = encoded[2] * (65_535.0 / 256.0) - 128,
        };
    }

    pub fn evaluateWorking(profile: Profile, camera_rgb: [3]f32) [3]f32 {
        const lab = profile.evaluateLab(camera_rgb);
        return color.pcs_xyz_d50_to_working(labToXyzD50(lab));
    }

    pub fn apply(profile: Profile, planes: *image.Planes) void {
        assert(planes.r.len == planes.g.len);
        assert(planes.r.len == planes.b.len);
        for (planes.r, planes.g, planes.b) |*red, *green, *blue| {
            const working = profile.evaluateWorking(.{ red.*, green.*, blue.* });
            red.* = working[0];
            green.* = working[1];
            blue.* = working[2];
        }
    }

    fn tetrahedral(profile: Profile, coordinate: [3]f32) [3]f32 {
        const grid: usize = profile.mft2.grid_points;
        var lower: [3]usize = undefined;
        var upper: [3]usize = undefined;
        var fraction: [3]f32 = undefined;
        for (coordinate, 0..) |value, axis| {
            const position = bounded(value) * @as(f32, @floatFromInt(grid - 1));
            lower[axis] = @intFromFloat(@floor(position));
            upper[axis] = @min(lower[axis] + 1, grid - 1);
            fraction[axis] = position - @as(f32, @floatFromInt(lower[axis]));
        }

        const c000 = profile.sample(lower[0], lower[1], lower[2]);
        const c111 = profile.sample(upper[0], upper[1], upper[2]);
        const x, const y, const z = fraction;
        if (x >= y) {
            if (y >= z) {
                return tetraMix(
                    c000,
                    profile.sample(upper[0], lower[1], lower[2]),
                    profile.sample(upper[0], upper[1], lower[2]),
                    c111,
                    x,
                    y,
                    z,
                );
            }
            if (x >= z) {
                return tetraMix(
                    c000,
                    profile.sample(upper[0], lower[1], lower[2]),
                    profile.sample(upper[0], lower[1], upper[2]),
                    c111,
                    x,
                    z,
                    y,
                );
            }
            return tetraMix(
                c000,
                profile.sample(lower[0], lower[1], upper[2]),
                profile.sample(upper[0], lower[1], upper[2]),
                c111,
                z,
                x,
                y,
            );
        }
        if (x >= z) {
            return tetraMix(
                c000,
                profile.sample(lower[0], upper[1], lower[2]),
                profile.sample(upper[0], upper[1], lower[2]),
                c111,
                y,
                x,
                z,
            );
        }
        if (y >= z) {
            return tetraMix(
                c000,
                profile.sample(lower[0], upper[1], lower[2]),
                profile.sample(lower[0], upper[1], upper[2]),
                c111,
                y,
                z,
                x,
            );
        }
        return tetraMix(
            c000,
            profile.sample(lower[0], lower[1], upper[2]),
            profile.sample(lower[0], upper[1], upper[2]),
            c111,
            z,
            y,
            x,
        );
    }

    fn sample(profile: Profile, red: usize, green: usize, blue: usize) [3]f32 {
        const grid: usize = profile.mft2.grid_points;
        const base = ((red * grid + green) * grid + blue) * 3 * 2;
        return .{
            readUnit(profile.mft2.clut_u16be, base),
            readUnit(profile.mft2.clut_u16be, base + 2),
            readUnit(profile.mft2.clut_u16be, base + 4),
        };
    }
};

fn tetraMix(
    first: [3]f32,
    second: [3]f32,
    third: [3]f32,
    fourth: [3]f32,
    first_weight: f32,
    second_weight: f32,
    third_weight: f32,
) [3]f32 {
    var result: [3]f32 = undefined;
    for (&result, first, second, third, fourth) |*target, c0, c1, c2, c3| {
        target.* = c0 + first_weight * (c1 - c0) +
            second_weight * (c2 - c1) + third_weight * (c3 - c2);
    }
    return result;
}

fn table(
    tables: []const u8,
    entries: u16,
    channel: usize,
    input: f32,
) f32 {
    assert(channel < 3);
    assert(entries >= 2);
    const position = bounded(input) * @as(f32, @floatFromInt(entries - 1));
    const lower: usize = @intFromFloat(@floor(position));
    const upper = @min(lower + 1, @as(usize, entries - 1));
    const fraction = position - @as(f32, @floatFromInt(lower));
    const channel_start = channel * @as(usize, entries) * 2;
    const first = readUnit(tables, channel_start + lower * 2);
    const second = readUnit(tables, channel_start + upper * 2);
    return first + (second - first) * fraction;
}

fn decodeMatrix(bytes: []const u8) color.Mat3 {
    assert(bytes.len == 36);
    var values: [9]f32 = undefined;
    for (&values, 0..) |*target, index| {
        const start = index * 4;
        const fixed = std.mem.readInt(i32, bytes[start..][0..4], .big);
        target.* = @as(f32, @floatFromInt(fixed)) / 65_536.0;
    }
    return .{ .values = values };
}

fn readUnit(bytes: []const u8, offset: usize) f32 {
    assert(offset + 2 <= bytes.len);
    const value = std.mem.readInt(u16, bytes[offset..][0..2], .big);
    return @as(f32, @floatFromInt(value)) / 65_535.0;
}

fn bounded(value: f32) f32 {
    if (!std.math.isFinite(value)) return 0;
    return std.math.clamp(value, 0, 1);
}

fn labToXyzD50(lab: Lab) [3]f32 {
    const fy = (lab.l + 16) / 116;
    const fx = fy + lab.a / 500;
    const fz = fy - lab.b / 200;
    return .{
        0.96422 * labInverse(fx),
        labInverse(fy),
        0.82521 * labInverse(fz),
    };
}

fn labInverse(value: f32) f32 {
    const delta: f32 = 6.0 / 29.0;
    if (value > delta) return value * value * value;
    return 3 * delta * delta * (value - 4.0 / 29.0);
}

test "both bootstrap profiles match canonical dimensions and LittleCMS vectors" {
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    const cases = [_]struct {
        id: []const u8,
        red: Lab,
        green: Lab,
        blue: Lab,
        mixed: Lab,
    }{
        .{
            .id = "profile.capture-one.CanonEOS1DX2-ProStandard.v1",
            .red = .{ .l = 60.3523, .a = 127.9961, .b = 88.9805 },
            .green = .{ .l = 84.7626, .a = -128, .b = 100.8711 },
            .blue = .{ .l = 29.2662, .a = 110.3750, .b = -128 },
            .mixed = .{ .l = 56.9547, .a = -7.6289, .b = -69.8242 },
        },
        .{
            .id = "profile.capture-one.CanonEOSR3-ProStandard.v1",
            .red = .{ .l = 60.3523, .a = 106.5078, .b = 75.0313 },
            .green = .{ .l = 84.7626, .a = -128, .b = 99.1133 },
            .blue = .{ .l = 27.5781, .a = 109.8984, .b = -128 },
            .mixed = .{ .l = 55.7782, .a = -10.6523, .b = -61.7734 },
        },
    };
    for (cases) |case| {
        var mft2 = try database.loadMft2(std.testing.allocator, case.id);
        defer mft2.deinit(std.testing.allocator);
        const profile = try Profile.init(&mft2);
        try std.testing.expect(profile.isBootstrapCanonical());
        try expectLab(case.red, profile.evaluateLab(.{ 1, 0, 0 }));
        try expectLab(case.green, profile.evaluateLab(.{ 0, 1, 0 }));
        try expectLab(case.blue, profile.evaluateLab(.{ 0, 0, 1 }));
        try expectLab(
            case.mixed,
            profile.evaluateLab(.{ 64.0 / 255.0, 128.0 / 255.0, 192.0 / 255.0 }),
        );
    }
}

test "profile boundaries gradients and out of gamut inputs stay finite" {
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    var mft2 = try database.loadMft2(
        std.testing.allocator,
        "profile.capture-one.CanonEOSR3-ProStandard.v1",
    );
    defer mft2.deinit(std.testing.allocator);
    const profile = try Profile.init(&mft2);

    var previous_l: f32 = -1;
    for (0..1025) |index| {
        const value = @as(f32, @floatFromInt(index)) / 1024;
        const lab = profile.evaluateLab(.{ value, value, value });
        try std.testing.expect(lab.l >= previous_l);
        try std.testing.expectApproxEqAbs(@as(f32, 0), lab.a, 2.0 / 256.0);
        try std.testing.expectApproxEqAbs(@as(f32, 0), lab.b, 2.0 / 256.0);
        previous_l = lab.l;
    }
    for ([_][3]f32{
        .{ -10, 0.5, 20 },
        .{ std.math.inf(f32), 0, std.math.nan(f32) },
        .{ 1, 1, 1 },
    }) |input| {
        for (profile.evaluateWorking(input)) |value| {
            try std.testing.expect(std.math.isFinite(value));
        }
    }
}

fn expectLab(expected: Lab, actual: Lab) !void {
    try std.testing.expectApproxEqAbs(expected.l, actual.l, 0.02);
    try std.testing.expectApproxEqAbs(expected.a, actual.a, 0.02);
    try std.testing.expectApproxEqAbs(expected.b, actual.b, 0.02);
}
