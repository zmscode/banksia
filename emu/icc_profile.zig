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

    /// Capture One selects its film curve separately from the input profile.
    /// Preserve the technical matrix's scene luminance here so the ICC A2B0
    /// transform contributes nonlinear hue/chroma without silently becoming a
    /// second tone curve. Native DNG matrices already incorporate white-point
    /// adaptation, whereas LibRaw matrices consume balanced camera channels.
    pub fn applyPreservingTechnicalLuminance(
        profile: Profile,
        scratch_gpa: std.mem.Allocator,
        planes: *image.Planes,
        technical: color.Transform,
        white_balance_gains: ?[3]f32,
    ) std.mem.Allocator.Error!void {
        assert(planes.r.len == planes.g.len);
        assert(planes.r.len == planes.b.len);
        assert(planes.r.len == @as(usize, planes.width) * planes.height);
        const corrections = try scratch_gpa.alloc(f32, planes.r.len * 3);
        defer scratch_gpa.free(corrections);
        const correction_r = corrections[0..planes.r.len];
        const correction_g = corrections[planes.r.len .. planes.r.len * 2];
        const correction_b = corrections[planes.r.len * 2 ..];

        for (planes.r, planes.g, planes.b, 0..) |red, green, blue, index| {
            const camera_rgb = [3]f32{ red, green, blue };
            const reference = technicalReference(technical, white_balance_gains, camera_rgb);
            const mapped = profile.evaluateWorking(camera_rgb);
            const profiled = preserveLuminance(
                reference,
                mapped,
                color.working_luminance(reference),
                color.working_luminance(mapped),
            );
            correction_r[index] = profiled[0] - reference[0];
            correction_g[index] = profiled[1] - reference[1];
            correction_b[index] = profiled[2] - reference[2];
        }

        for (planes.r, planes.g, planes.b, 0..) |*red, *green, *blue, index| {
            const reference = technicalReference(
                technical,
                white_balance_gains,
                .{ red.*, green.*, blue.* },
            );
            const correction = localCorrection(
                .{ correction_r, correction_g, correction_b },
                planes.width,
                planes.height,
                index,
            );
            const strength = neutralProtectedStrength(reference) *
                profile_correction_strength;
            const candidate = [3]f32{
                reference[0] + correction[0] * strength,
                reference[1] + correction[1] * strength,
                reference[2] + correction[2] * strength,
            };
            const result = preserveLuminance(
                reference,
                candidate,
                color.working_luminance(reference),
                color.working_luminance(candidate),
            );
            red.* = finiteOr(result[0], reference[0]);
            green.* = finiteOr(result[1], reference[1]);
            blue.* = finiteOr(result[2], reference[2]);
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

fn technicalReference(
    technical: color.Transform,
    white_balance_gains: ?[3]f32,
    balanced: [3]f32,
) [3]f32 {
    var technical_input = balanced;
    if (!technical.apply_as_shot_white_balance) {
        if (white_balance_gains) |gains| {
            for (&technical_input, gains) |*value, gain| {
                assert(gain > 0);
                assert(std.math.isFinite(gain));
                value.* /= gain;
            }
        }
    }
    return technical.camera_to_rec2020.vector(technical_input);
}

/// The bootstrap profiles were recovered as behavioral oracles, not tuned as
/// final Banksia defaults. A conservative chroma fraction keeps their useful
/// hue separation without magnifying residual reconstruction chroma; changing
/// this value requires a new immutable implementation ID.
const profile_correction_strength: f32 = 0.4;

comptime {
    assert(profile_correction_strength > 0);
    assert(profile_correction_strength <= 1);
}

fn localCorrection(
    corrections: [3][]const f32,
    width: u32,
    height: u32,
    center_index: usize,
) [3]f32 {
    assert(center_index < corrections[0].len);
    assert(corrections[0].len == corrections[1].len);
    assert(corrections[0].len == corrections[2].len);
    assert(corrections[0].len == @as(usize, width) * height);
    const center_x: u32 = @intCast(center_index % width);
    const center_y: u32 = @intCast(center_index / width);
    const x_start = center_x -| 2;
    const y_start = center_y -| 2;
    const x_end = @min(center_x + 2, width - 1);
    const y_end = @min(center_y + 2, height - 1);
    var sum: [3]f32 = @splat(0);
    var count: u8 = 0;
    for (y_start..y_end + 1) |y| {
        for (x_start..x_end + 1) |x| {
            const index = y * @as(usize, width) + x;
            for (&sum, corrections) |*value, channel| value.* += channel[index];
            count += 1;
        }
    }
    assert(count > 0);
    assert(count <= 25);
    const scale = 1 / @as(f32, @floatFromInt(count));
    return .{ sum[0] * scale, sum[1] * scale, sum[2] * scale };
}

fn finiteOr(value: f32, fallback: f32) f32 {
    return if (std.math.isFinite(value)) value else fallback;
}

fn neutralProtectedStrength(reference: [3]f32) f32 {
    const channel_max = @max(reference[0], @max(reference[1], reference[2]));
    const channel_min = @min(reference[0], @min(reference[1], reference[2]));
    const luminance = @max(@abs(color.working_luminance(reference)), 0.02);
    const chroma = @max(0, channel_max - channel_min) / luminance;
    const position = std.math.clamp((chroma - 0.04) / 0.14, 0, 1);
    return position * position * (3 - 2 * position);
}

fn preserveLuminance(
    reference: [3]f32,
    mapped: [3]f32,
    reference_y: f32,
    mapped_y: f32,
) [3]f32 {
    if (!std.math.isFinite(reference_y)) return @splat(0);
    if (!std.math.isFinite(mapped_y)) return reference;
    if (mapped_y <= 1e-7) return reference;
    const scale = reference_y / mapped_y;
    if (!std.math.isFinite(scale)) return reference;
    var result: [3]f32 = undefined;
    for (&result, mapped, reference) |*target, value, fallback| {
        const scaled = value * scale;
        target.* = if (std.math.isFinite(scaled)) scaled else fallback;
    }
    return result;
}

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
        skin: Lab,
    }{
        .{
            .id = "profile.capture-one.CanonEOS1DX2-ProStandard.v1",
            .red = .{ .l = 60.3523, .a = 127.9961, .b = 88.9805 },
            .green = .{ .l = 84.7626, .a = -128, .b = 100.8711 },
            .blue = .{ .l = 29.2662, .a = 110.3750, .b = -128 },
            .mixed = .{ .l = 56.9547, .a = -7.6289, .b = -69.8242 },
            .skin = .{ .l = 63.0025, .a = 35.6758, .b = 35.7774 },
        },
        .{
            .id = "profile.capture-one.CanonEOSR3-ProStandard.v1",
            .red = .{ .l = 60.3523, .a = 106.5078, .b = 75.0313 },
            .green = .{ .l = 84.7626, .a = -128, .b = 99.1133 },
            .blue = .{ .l = 27.5781, .a = 109.8984, .b = -128 },
            .mixed = .{ .l = 55.7782, .a = -10.6523, .b = -61.7734 },
            .skin = .{ .l = 63.0025, .a = 34.3164, .b = 34.3789 },
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
        try expectLab(
            case.skin,
            profile.evaluateLab(.{ 179.0 / 255.0, 115.0 / 255.0, 89.0 / 255.0 }),
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

    // Traverse all CLUT cell boundaries along saturated device-space edges.
    // Adjacent samples must remain finite and locally continuous.
    for ([_][3]f32{
        .{ 1, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, 1 },
    }) |axis| {
        var previous = profile.evaluateLab(.{ 0, 0, 0 });
        for (1..1025) |index| {
            const amount = @as(f32, @floatFromInt(index)) / 1024;
            const current = profile.evaluateLab(.{
                axis[0] * amount,
                axis[1] * amount,
                axis[2] * amount,
            });
            try std.testing.expect(labDistance(previous, current) < 2);
            previous = current;
        }
    }
}

test "neutral protection is smooth bounded and rejects isolated chroma" {
    try std.testing.expectEqual(@as(f32, 0), neutralProtectedStrength(.{ 0.5, 0.5, 0.5 }));
    try std.testing.expectEqual(@as(f32, 1), neutralProtectedStrength(.{ 0.8, 0.1, 0.1 }));

    var previous: f32 = 0;
    for (0..101) |index| {
        const chroma = @as(f32, @floatFromInt(index)) / 100;
        const strength = neutralProtectedStrength(.{ 0.5 + chroma * 0.2, 0.5, 0.5 });
        try std.testing.expect(strength >= previous);
        try std.testing.expect(strength >= 0);
        try std.testing.expect(strength <= 1);
        previous = strength;
    }
}

test "active profile application preserves neutral and uniform-field continuity" {
    const gpa = std.testing.allocator;
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    var mft2 = try database.loadMft2(
        gpa,
        "profile.capture-one.CanonEOSR3-ProStandard.v1",
    );
    defer mft2.deinit(gpa);
    const profile = try Profile.init(&mft2);
    var planes = try image.Planes.init(gpa, 7, 5);
    defer planes.deinit(gpa);
    const technical = color.Transform{
        .camera_to_rec2020 = .identity,
        .apply_as_shot_white_balance = false,
    };

    @memset(planes.r, 0.5);
    @memset(planes.g, 0.5);
    @memset(planes.b, 0.5);
    try profile.applyPreservingTechnicalLuminance(gpa, &planes, technical, null);
    for (planes.r, planes.g, planes.b) |red, green, blue| {
        try std.testing.expectEqual(@as(f32, 0.5), red);
        try std.testing.expectEqual(@as(f32, 0.5), green);
        try std.testing.expectEqual(@as(f32, 0.5), blue);
    }

    @memset(planes.r, 0.8);
    @memset(planes.g, 0.2);
    @memset(planes.b, 0.1);
    try profile.applyPreservingTechnicalLuminance(gpa, &planes, technical, null);
    const expected = [3]f32{ planes.r[0], planes.g[0], planes.b[0] };
    for (planes.r, planes.g, planes.b) |red, green, blue| {
        try std.testing.expectApproxEqAbs(expected[0], red, 1e-6);
        try std.testing.expectApproxEqAbs(expected[1], green, 1e-6);
        try std.testing.expectApproxEqAbs(expected[2], blue, 1e-6);
        try std.testing.expect(std.math.isFinite(red));
        try std.testing.expect(std.math.isFinite(green));
        try std.testing.expect(std.math.isFinite(blue));
    }
    try std.testing.expectApproxEqAbs(
        color.working_luminance(.{ 0.8, 0.2, 0.1 }),
        color.working_luminance(expected),
        1e-6,
    );
}

fn labDistance(first: Lab, second: Lab) f32 {
    const delta_l = second.l - first.l;
    const delta_a = second.a - first.a;
    const delta_b = second.b - first.b;
    return @sqrt(delta_l * delta_l + delta_a * delta_a + delta_b * delta_b);
}

fn expectLab(expected: Lab, actual: Lab) !void {
    try std.testing.expectApproxEqAbs(expected.l, actual.l, 0.02);
    try std.testing.expectApproxEqAbs(expected.a, actual.a, 0.02);
    try std.testing.expectApproxEqAbs(expected.b, actual.b, 0.02);
}
