//! DNG baseline colour for engine v2.
//!
//! The DNG convention is `XYZtoCamera = AB * CC * CM`. Banksia inverts
//! that matrix, Bradford-adapts the selected white to D50, then converts to
//! linear Rec.2020. Output conversion maps Rec.2020 to linear sRGB; transfer
//! encoding and clipping remain the pipeline packer's responsibility.

const std = @import("std");
const dng = @import("dng.zig");
const image = @import("image.zig");

pub const Error = error{
    MissingColorMatrix,
    InvalidColorMatrix,
    InvalidIlluminant,
    SingularColorMatrix,
};

pub const Mat3 = struct {
    values: [9]f32,

    pub const identity: Mat3 = .{ .values = .{
        1, 0, 0,
        0, 1, 0,
        0, 0, 1,
    } };

    pub fn init(values: dng.Matrix3x3) Mat3 {
        return .{ .values = values };
    }

    pub fn diagonal(values: [3]f32) Mat3 {
        return .{ .values = .{
            values[0], 0,         0,
            0,         values[1], 0,
            0,         0,         values[2],
        } };
    }

    pub fn multiply(a: Mat3, b: Mat3) Mat3 {
        var result: Mat3 = undefined;
        for (0..3) |row| {
            for (0..3) |column| {
                var value: f32 = 0;
                for (0..3) |k| {
                    value += a.values[row * 3 + k] * b.values[k * 3 + column];
                }
                result.values[row * 3 + column] = value;
            }
        }
        return result;
    }

    pub fn vector(matrix: Mat3, value: [3]f32) [3]f32 {
        return .{
            matrix.values[0] * value[0] +
                matrix.values[1] * value[1] +
                matrix.values[2] * value[2],
            matrix.values[3] * value[0] +
                matrix.values[4] * value[1] +
                matrix.values[5] * value[2],
            matrix.values[6] * value[0] +
                matrix.values[7] * value[1] +
                matrix.values[8] * value[2],
        };
    }

    pub fn lerp(a: Mat3, b: Mat3, weight_b: f32) Mat3 {
        var result: Mat3 = undefined;
        for (&result.values, a.values, b.values) |*out, av, bv| {
            out.* = av + (bv - av) * weight_b;
        }
        return result;
    }

    pub fn inverse(matrix: Mat3) Error!Mat3 {
        const m = matrix.values;
        const determinant = m[0] * (m[4] * m[8] - m[5] * m[7]) -
            m[1] * (m[3] * m[8] - m[5] * m[6]) +
            m[2] * (m[3] * m[7] - m[4] * m[6]);
        if (!std.math.isFinite(determinant) or @abs(determinant) < 1e-10) {
            return error.SingularColorMatrix;
        }
        const scale = 1 / determinant;
        const result = Mat3{ .values = .{
            (m[4] * m[8] - m[5] * m[7]) * scale,
            (m[2] * m[7] - m[1] * m[8]) * scale,
            (m[1] * m[5] - m[2] * m[4]) * scale,
            (m[5] * m[6] - m[3] * m[8]) * scale,
            (m[0] * m[8] - m[2] * m[6]) * scale,
            (m[2] * m[3] - m[0] * m[5]) * scale,
            (m[3] * m[7] - m[4] * m[6]) * scale,
            (m[1] * m[6] - m[0] * m[7]) * scale,
            (m[0] * m[4] - m[1] * m[3]) * scale,
        } };
        try validate_matrix(result);
        return result;
    }
};

pub const Transform = struct {
    camera_to_rec2020: Mat3,
    /// LibRaw's normalized camera matrix expects its recorded channel gains
    /// before conversion; native DNG's AB*CC*CM path incorporates white
    /// selection through chromatic adaptation instead.
    apply_as_shot_white_balance: bool,

    pub fn init(metadata: dng.Metadata) Error!Transform {
        if (metadata.camera_to_xyz) |values| {
            const camera_to_source_xyz = Mat3.init(values);
            try validate_matrix(camera_to_source_xyz);
            const source_xyz = camera_to_source_xyz.vector(.{ 1, 1, 1 });
            const source_xy = try xyz_to_xy(source_xyz);
            const source_to_d50 = try bradford(source_xy, d50_xy);
            const d50_to_d65 = try bradford(d50_xy, d65_xy);
            const camera_to_rec2020 = xyz_d65_to_rec2020.multiply(
                d50_to_d65.multiply(source_to_d50.multiply(camera_to_source_xyz)),
            );
            try validate_matrix(camera_to_rec2020);
            return .{
                .camera_to_rec2020 = camera_to_rec2020,
                .apply_as_shot_white_balance = true,
            };
        }
        const profile = try Profile.init(metadata);
        const source_xy = try profile.white_xy(metadata.wb_neutral);
        const xyz_to_camera = try profile.xyz_to_camera(cct_from_xy(source_xy));
        const camera_to_source_xyz = try xyz_to_camera.inverse();
        const source_to_d50 = try bradford(source_xy, d50_xy);
        const d50_to_d65 = try bradford(d50_xy, d65_xy);
        const camera_to_d65 = d50_to_d65.multiply(
            source_to_d50.multiply(camera_to_source_xyz),
        );
        const camera_to_rec2020 = xyz_d65_to_rec2020.multiply(camera_to_d65);
        try validate_matrix(camera_to_rec2020);
        return .{
            .camera_to_rec2020 = camera_to_rec2020,
            .apply_as_shot_white_balance = false,
        };
    }

    pub fn camera_to_working(self: Transform, planes: *image.Planes) void {
        apply_matrix(planes, self.camera_to_rec2020);
    }
};

pub fn working_to_linear_srgb(planes: *image.Planes) void {
    apply_matrix(planes, rec2020_to_linear_srgb);
}

/// Convert ICC's D50 PCS XYZ into Banksia's linear Rec.2020 working space.
/// Negative finite components are retained for later gamut handling.
pub fn pcs_xyz_d50_to_working(xyz: [3]f32) [3]f32 {
    const result = xyz_d50_to_rec2020.vector(xyz);
    var sanitized: [3]f32 = undefined;
    for (&sanitized, result) |*target, value| {
        target.* = sanitize(value);
    }
    return sanitized;
}

pub fn working_luminance(rgb: [3]f32) f32 {
    return rec2020_to_xyz_d65.values[3] * rgb[0] +
        rec2020_to_xyz_d65.values[4] * rgb[1] +
        rec2020_to_xyz_d65.values[5] * rgb[2];
}

const Profile = struct {
    color_1: Mat3,
    color_2: ?Mat3,
    calibration_1: Mat3,
    calibration_2: Mat3,
    analog_balance: Mat3,
    temperature_1: ?f32,
    temperature_2: ?f32,

    fn init(metadata: dng.Metadata) Error!Profile {
        const color_1 = Mat3.init(metadata.color_matrix_1 orelse {
            return error.MissingColorMatrix;
        });
        try validate_matrix(color_1);
        const color_2 = if (metadata.color_matrix_2) |values| Mat3.init(values) else null;
        if (color_2) |matrix| try validate_matrix(matrix);

        const signatures_match = std.mem.eql(
            u8,
            metadata.camera_calibration_signature.slice(),
            metadata.profile_calibration_signature.slice(),
        );
        const calibration_1 = if (signatures_match)
            Mat3.init(metadata.camera_calibration_1 orelse Mat3.identity.values)
        else
            Mat3.identity;
        const calibration_2 = if (signatures_match)
            Mat3.init(metadata.camera_calibration_2 orelse Mat3.identity.values)
        else
            Mat3.identity;
        try validate_matrix(calibration_1);
        try validate_matrix(calibration_2);
        for (metadata.analog_balance) |value| {
            if (!(value > 0) or !std.math.isFinite(value)) {
                return error.InvalidColorMatrix;
            }
        }

        var temperature_1: ?f32 = null;
        var temperature_2: ?f32 = null;
        if (color_2 != null) {
            temperature_1 = try illuminant_temperature(
                metadata.calibration_illuminant_1 orelse return error.InvalidIlluminant,
            );
            temperature_2 = try illuminant_temperature(
                metadata.calibration_illuminant_2 orelse return error.InvalidIlluminant,
            );
            if (temperature_1.? == temperature_2.?) return error.InvalidIlluminant;
        }
        return .{
            .color_1 = color_1,
            .color_2 = color_2,
            .calibration_1 = calibration_1,
            .calibration_2 = calibration_2,
            .analog_balance = Mat3.diagonal(metadata.analog_balance),
            .temperature_1 = temperature_1,
            .temperature_2 = temperature_2,
        };
    }

    fn xyz_to_camera(self: Profile, temperature: f32) Error!Mat3 {
        const weight = if (self.color_2 != null)
            inverse_temperature_weight(
                temperature,
                self.temperature_1.?,
                self.temperature_2.?,
            )
        else
            0;
        const color_matrix = if (self.color_2) |second|
            Mat3.lerp(self.color_1, second, weight)
        else
            self.color_1;
        const calibration = Mat3.lerp(
            self.calibration_1,
            self.calibration_2,
            weight,
        );
        const result = self.analog_balance.multiply(
            calibration.multiply(color_matrix),
        );
        try validate_matrix(result);
        return result;
    }

    fn white_xy(self: Profile, neutral: [3]f32) Error![2]f32 {
        for (neutral) |value| {
            if (!(value > 0) or !std.math.isFinite(value)) {
                return error.InvalidColorMatrix;
            }
        }
        var xy = d50_xy;
        for (0..12) |_| {
            const matrix = try self.xyz_to_camera(cct_from_xy(xy));
            const xyz = (try matrix.inverse()).vector(neutral);
            const sum = xyz[0] + xyz[1] + xyz[2];
            if (!(sum > 0) or !std.math.isFinite(sum)) {
                return error.InvalidColorMatrix;
            }
            const next = [2]f32{ xyz[0] / sum, xyz[1] / sum };
            if (!(next[0] > 0) or !(next[1] > 0) or next[0] + next[1] >= 1) {
                return error.InvalidColorMatrix;
            }
            const distance = @abs(next[0] - xy[0]) + @abs(next[1] - xy[1]);
            xy = next;
            if (distance < 1e-7) break;
        }
        return xy;
    }
};

fn validate_matrix(matrix: Mat3) Error!void {
    for (matrix.values) |value| {
        if (!std.math.isFinite(value)) return error.InvalidColorMatrix;
    }
}

fn apply_matrix(planes: *image.Planes, matrix: Mat3) void {
    for (planes.r, planes.g, planes.b) |*r, *g, *b| {
        const result = matrix.vector(.{ r.*, g.*, b.* });
        r.* = sanitize(result[0]);
        g.* = sanitize(result[1]);
        b.* = sanitize(result[2]);
    }
}

fn sanitize(value: f32) f32 {
    return if (std.math.isFinite(value)) value else 0;
}

fn inverse_temperature_weight(temperature: f32, first: f32, second: f32) f32 {
    const inverse = 1 / temperature;
    const denominator = 1 / second - 1 / first;
    return std.math.clamp((inverse - 1 / first) / denominator, 0, 1);
}

fn illuminant_temperature(illuminant: u16) Error!f32 {
    return switch (illuminant) {
        1, 4, 9 => 5500,
        3 => 2850,
        10 => 6500,
        11 => 7500,
        12 => 6430,
        13 => 5000,
        14 => 4230,
        15 => 3450,
        17 => 2856,
        18 => 4874,
        19 => 6774,
        20 => 5503,
        21 => 6504,
        22 => 7504,
        23 => 5003,
        24 => 3200,
        else => error.InvalidIlluminant,
    };
}

fn cct_from_xy(xy: [2]f32) f32 {
    const n = (xy[0] - 0.3320) / (0.1858 - xy[1]);
    const temperature = -449 * n * n * n + 3525 * n * n - 6823.3 * n + 5520.33;
    return std.math.clamp(temperature, 2000, 50_000);
}

fn xy_to_xyz(xy: [2]f32) [3]f32 {
    return .{ xy[0] / xy[1], 1, (1 - xy[0] - xy[1]) / xy[1] };
}

fn xyz_to_xy(xyz: [3]f32) Error![2]f32 {
    const sum = xyz[0] + xyz[1] + xyz[2];
    if (!(sum > 0) or !std.math.isFinite(sum)) return error.InvalidColorMatrix;
    const xy = [2]f32{ xyz[0] / sum, xyz[1] / sum };
    if (!(xy[0] > 0) or !(xy[1] > 0) or xy[0] + xy[1] >= 1) {
        return error.InvalidColorMatrix;
    }
    return xy;
}

fn bradford(source_xy: [2]f32, target_xy: [2]f32) Error!Mat3 {
    const source_cone = bradford_matrix.vector(xy_to_xyz(source_xy));
    const target_cone = bradford_matrix.vector(xy_to_xyz(target_xy));
    var scale: [3]f32 = undefined;
    for (&scale, source_cone, target_cone) |*value, source, target| {
        if (@abs(source) < 1e-10) return error.InvalidIlluminant;
        value.* = target / source;
    }
    const result = bradford_inverse.multiply(
        Mat3.diagonal(scale).multiply(bradford_matrix),
    );
    try validate_matrix(result);
    return result;
}

const d50_xy = [2]f32{ 0.3457, 0.3585 };
const d65_xy = [2]f32{ 0.3127, 0.3290 };

const bradford_matrix = Mat3{ .values = .{
    0.8951,  0.2664,  -0.1614,
    -0.7502, 1.7135,  0.0367,
    0.0389,  -0.0685, 1.0296,
} };
const bradford_inverse = Mat3{ .values = .{
    0.9869929,  -0.1470543, 0.1599627,
    0.4323053,  0.5183603,  0.0492912,
    -0.0085287, 0.0400428,  0.9684867,
} };
const xyz_d65_to_rec2020 = Mat3{ .values = .{
    1.7166512,  -0.3556708, -0.2533663,
    -0.6666844, 1.6164812,  0.0157685,
    0.0176399,  -0.0427706, 0.9421031,
} };
const pcs_d50_to_d65 = bradford(d50_xy, d65_xy) catch unreachable;
const xyz_d50_to_rec2020 = xyz_d65_to_rec2020.multiply(pcs_d50_to_d65);
const rec2020_to_xyz_d65 = Mat3{ .values = .{
    0.6369580, 0.1446169, 0.1688810,
    0.2627002, 0.6779981, 0.0593017,
    0.0000000, 0.0280727, 1.0609851,
} };
const xyz_d65_to_linear_srgb = Mat3{ .values = .{
    3.2404542,  -1.5371385, -0.4985314,
    -0.9692660, 1.8760108,  0.0415560,
    0.0556434,  -0.2040259, 1.0572252,
} };
const rec2020_to_linear_srgb = xyz_d65_to_linear_srgb.multiply(rec2020_to_xyz_d65);

fn test_metadata() dng.Metadata {
    return .{
        .width = 2,
        .height = 2,
        .compression = .none,
        .cfa = .{ .red, .green, .green, .blue },
        .black_level = 0,
        .white_level = 1,
        .wb_neutral = xy_to_xyz(d50_xy),
        .orientation = .normal,
        .active_area = .{ .x = 0, .y = 0, .width = 2, .height = 2 },
        .default_crop = .{ .x = 0, .y = 0, .width = 2, .height = 2 },
        .color_matrix_1 = Mat3.identity.values,
        .calibration_illuminant_1 = 23,
    };
}

test "matrix inverse roundtrips a known vector" {
    const matrix = Mat3{ .values = .{
        2, 1, 0,
        0, 3, 1,
        1, 0, 4,
    } };
    const value = [3]f32{ 0.2, 0.4, 0.8 };
    const roundtrip = (try matrix.inverse()).vector(matrix.vector(value));
    for (roundtrip, value) |actual, expected| {
        try std.testing.expectApproxEqAbs(expected, actual, 1e-6);
    }
}

test "inverse-CCT interpolation reaches both endpoints and its midpoint" {
    try std.testing.expectEqual(@as(f32, 0), inverse_temperature_weight(3000, 3000, 6000));
    try std.testing.expectEqual(@as(f32, 1), inverse_temperature_weight(6000, 3000, 6000));
    try std.testing.expectApproxEqAbs(
        @as(f32, 0.5),
        inverse_temperature_weight(4000, 3000, 6000),
        1e-6,
    );
}

test "Bradford adaptation maps its source white onto its target white" {
    const adaptation = try bradford(d65_xy, d50_xy);
    const actual = adaptation.vector(xy_to_xyz(d65_xy));
    const expected = xy_to_xyz(d50_xy);
    for (actual, expected) |value, target| {
        try std.testing.expectApproxEqAbs(target, value, 2e-4);
    }
}

test "identity D50 camera maps its neutral to equal Rec.2020" {
    const metadata = test_metadata();
    const transform = try Transform.init(metadata);
    const white = transform.camera_to_rec2020.vector(metadata.wb_neutral);
    for (white) |value| try std.testing.expectApproxEqAbs(@as(f32, 1), value, 3e-4);
}

test "backend camera matrix consumes an as-shot-balanced neutral" {
    var metadata = test_metadata();
    metadata.color_matrix_1 = null;
    metadata.camera_to_xyz = Mat3.identity.values;
    metadata.wb_neutral = .{ 0.5, 1, 0.75 };
    const transform = try Transform.init(metadata);
    try std.testing.expect(transform.apply_as_shot_white_balance);
    const balanced_neutral = [3]f32{
        metadata.wb_neutral[0] * metadata.wb_neutral[1] / metadata.wb_neutral[0],
        metadata.wb_neutral[1],
        metadata.wb_neutral[2] * metadata.wb_neutral[1] / metadata.wb_neutral[2],
    };
    const white = transform.camera_to_rec2020.vector(balanced_neutral);
    for (white) |value| {
        try std.testing.expectApproxEqAbs(white[1], value, 3e-4);
    }
}

test "DNG matrix order is analog balance times calibration times color" {
    var metadata = test_metadata();
    metadata.color_matrix_1 = Mat3.diagonal(.{ 2, 3, 4 }).values;
    metadata.camera_calibration_1 = Mat3.diagonal(.{ 5, 6, 7 }).values;
    metadata.analog_balance = .{ 8, 9, 10 };
    var profile = try Profile.init(metadata);
    try std.testing.expectEqual(
        Mat3.diagonal(.{ 80, 162, 280 }).values,
        (try profile.xyz_to_camera(5000)).values,
    );

    metadata.camera_calibration_signature = dng.Text.init("camera");
    metadata.profile_calibration_signature = dng.Text.init("profile");
    profile = try Profile.init(metadata);
    try std.testing.expectEqual(
        Mat3.diagonal(.{ 16, 27, 40 }).values,
        (try profile.xyz_to_camera(5000)).values,
    );
}

test "two-illuminant profile interpolates matrices in inverse CCT" {
    var metadata = test_metadata();
    metadata.color_matrix_1 = Mat3.diagonal(.{ 1, 1, 1 }).values;
    metadata.color_matrix_2 = Mat3.diagonal(.{ 3, 3, 3 }).values;
    metadata.calibration_illuminant_1 = 17;
    metadata.calibration_illuminant_2 = 21;
    const profile = try Profile.init(metadata);
    const first: f32 = 2856;
    const second: f32 = 6504;
    const midpoint = 1 / ((1 / first + 1 / second) * 0.5);
    const actual = try profile.xyz_to_camera(midpoint);
    for (actual.values, Mat3.diagonal(.{ 2, 2, 2 }).values) |value, expected| {
        try std.testing.expectApproxEqAbs(expected, value, 1e-6);
    }
}

test "non-finite plane values are sanitized by every colour transform" {
    var r = [1]f32{std.math.inf(f32)};
    var g = [1]f32{1};
    var b = [1]f32{1};
    var planes = image.Planes{
        .width = 1,
        .height = 1,
        .r = &r,
        .g = &g,
        .b = &b,
    };
    apply_matrix(&planes, Mat3.identity);
    try std.testing.expectEqual(@as(f32, 0), planes.r[0]);
    try std.testing.expect(std.math.isFinite(planes.g[0]));
    try std.testing.expect(std.math.isFinite(planes.b[0]));
}
