//! Strict camera film-curve evaluation for calibrated engine versions.
//!
//! Capture One's version-6 records contain a main response plus CCD/pre-curve
//! and contrast components. The main response is the rendering curve; the two
//! auxiliary components stay distinct and inspectable rather than being
//! compounded into a second, much stronger tone operation.

const std = @import("std");
const assert = std.debug.assert;
const calibration = @import("calibration.zig");
const image = @import("image.zig");

pub const implementation_id = "banksia.film-curve.pchip-luma.v1";
pub const implementation_id_linear = "banksia.film-curve.linear.v1";
pub const format_version_capture_one: u32 = 6;
pub const flags_capture_one_auto: u32 = 0x23;

pub const Error = error{InvalidCalibration};

pub const Selection = enum {
    linear,
    capture_one_auto,
};

pub const Component = enum {
    film,
    ccd,
    contrast,
};

pub const Profile = struct {
    record: *const calibration.FilmCurve,
    film_slopes: [calibration.curve_points_max]f64,
    ccd_slopes: [calibration.curve_points_max]f64,
    contrast_slopes: [calibration.curve_points_max]f64,

    pub fn init(record: *const calibration.FilmCurve) Error!Profile {
        if (record.format_version != format_version_capture_one) {
            return error.InvalidCalibration;
        }
        if (record.flags != flags_capture_one_auto) return error.InvalidCalibration;
        var profile = Profile{
            .record = record,
            .film_slopes = @splat(0),
            .ccd_slopes = @splat(0),
            .contrast_slopes = @splat(0),
        };
        try slopesInit(
            record.film[0..record.film_count],
            profile.film_slopes[0..record.film_count],
        );
        try slopesInit(
            record.ccd[0..record.ccd_count],
            profile.ccd_slopes[0..record.ccd_count],
        );
        try slopesInit(
            record.contrast[0..record.contrast_count],
            profile.contrast_slopes[0..record.contrast_count],
        );
        return profile;
    }

    pub fn evaluate(profile: *const Profile, component: Component, input: f32) f32 {
        const points, const slopes = switch (component) {
            .film => .{
                profile.record.film[0..profile.record.film_count],
                profile.film_slopes[0..profile.record.film_count],
            },
            .ccd => .{
                profile.record.ccd[0..profile.record.ccd_count],
                profile.ccd_slopes[0..profile.record.ccd_count],
            },
            .contrast => .{
                profile.record.contrast[0..profile.record.contrast_count],
                profile.contrast_slopes[0..profile.record.contrast_count],
            },
        };
        return @floatCast(evaluateMonotonic(points, slopes, input));
    }
};

pub const Application = struct {
    profile: *const Profile,
    base_gain: f32,
    sensor_range_gain: f32,

    pub fn assertValid(application: Application) void {
        assert(std.math.isFinite(application.base_gain));
        assert(application.base_gain > 0);
        assert(application.base_gain <= 4);
        assert(std.math.isFinite(application.sensor_range_gain));
        assert(application.sensor_range_gain > 0);
        assert(application.sensor_range_gain <= 4);
    }

    pub fn apply(application: Application, planes: *image.Planes) void {
        application.assertValid();
        assert(planes.r.len == planes.g.len);
        assert(planes.r.len == planes.b.len);
        kernelApply(
            planes.r,
            planes.g,
            planes.b,
            application.profile,
            application.base_gain * application.sensor_range_gain,
        );
    }
};

pub const Rendering = union(enum) {
    linear,
    capture_one_auto: Application,

    pub fn assertValid(rendering: Rendering) void {
        switch (rendering) {
            .linear => {},
            .capture_one_auto => |application| application.assertValid(),
        }
    }

    pub fn apply(rendering: Rendering, planes: *image.Planes) void {
        rendering.assertValid();
        switch (rendering) {
            .linear => {},
            .capture_one_auto => |application| application.apply(planes),
        }
    }
};

fn slopesInit(points: []const calibration.Point, slopes: []f64) Error!void {
    if (points.len < 2) return error.InvalidCalibration;
    if (points.len > calibration.curve_points_max) return error.InvalidCalibration;
    if (slopes.len != points.len) return error.InvalidCalibration;

    var secants: [calibration.curve_points_max - 1]f64 = @splat(0);
    var index: u32 = 0;
    while (index < points.len) : (index += 1) {
        const point = points[index];
        if (!std.math.isFinite(point.x)) return error.InvalidCalibration;
        if (!std.math.isFinite(point.y)) return error.InvalidCalibration;
        if (point.x < 0) return error.InvalidCalibration;
        if (point.x > 1) return error.InvalidCalibration;
        if (point.y < 0) return error.InvalidCalibration;
        if (point.y > 1) return error.InvalidCalibration;
        if (index > 0) {
            const previous = points[index - 1];
            if (point.x <= previous.x) return error.InvalidCalibration;
            if (point.y < previous.y) return error.InvalidCalibration;
            secants[index - 1] = (point.y - previous.y) / (point.x - previous.x);
        }
    }
    if (points[0].x != 0) return error.InvalidCalibration;
    if (points[0].y != 0) return error.InvalidCalibration;
    if (points[points.len - 1].x != 1) return error.InvalidCalibration;
    if (points[points.len - 1].y != 1) return error.InvalidCalibration;

    if (points.len == 2) {
        slopes[0] = secants[0];
        slopes[1] = secants[0];
        return;
    }

    slopes[0] = endpointSlope(
        points[1].x - points[0].x,
        points[2].x - points[1].x,
        secants[0],
        secants[1],
    );
    index = 1;
    while (index + 1 < points.len) : (index += 1) {
        const left = secants[index - 1];
        const right = secants[index];
        if (left == 0 or right == 0 or std.math.signbit(left) != std.math.signbit(right)) {
            slopes[index] = 0;
        } else {
            const left_width = points[index].x - points[index - 1].x;
            const right_width = points[index + 1].x - points[index].x;
            const weight_left = 2 * right_width + left_width;
            const weight_right = right_width + 2 * left_width;
            slopes[index] = (weight_left + weight_right) /
                (weight_left / left + weight_right / right);
        }
    }
    const last = points.len - 1;
    slopes[last] = endpointSlope(
        points[last].x - points[last - 1].x,
        points[last - 1].x - points[last - 2].x,
        secants[last - 1],
        secants[last - 2],
    );
}

fn endpointSlope(width_near: f64, width_far: f64, near: f64, far: f64) f64 {
    assert(width_near > 0);
    assert(width_far > 0);
    const slope = ((2 * width_near + width_far) * near - width_near * far) /
        (width_near + width_far);
    if (std.math.signbit(slope) != std.math.signbit(near)) return 0;
    if (std.math.signbit(near) != std.math.signbit(far)) {
        if (@abs(slope) > 3 * @abs(near)) return 3 * near;
    }
    return slope;
}

fn evaluateMonotonic(
    points: []const calibration.Point,
    slopes: []const f64,
    input: f32,
) f64 {
    assert(points.len >= 2);
    assert(points.len == slopes.len);
    if (!std.math.isFinite(input)) return 0;
    if (input <= 0) return input;
    if (input >= 1) return 1;

    const input_f64: f64 = input;
    var index: u32 = 0;
    while (index + 1 < points.len) : (index += 1) {
        if (input_f64 <= points[index + 1].x) break;
    }
    assert(index + 1 < points.len);
    const left = points[index];
    const right = points[index + 1];
    const width = right.x - left.x;
    const position = (input_f64 - left.x) / width;
    const position_2 = position * position;
    const position_3 = position_2 * position;
    const basis_left = 2 * position_3 - 3 * position_2 + 1;
    const basis_left_slope = position_3 - 2 * position_2 + position;
    const basis_right = -2 * position_3 + 3 * position_2;
    const basis_right_slope = position_3 - position_2;
    return basis_left * left.y +
        basis_left_slope * width * slopes[index] +
        basis_right * right.y +
        basis_right_slope * width * slopes[index + 1];
}

fn kernelApply(
    red: []f32,
    green: []f32,
    blue: []f32,
    profile: *const Profile,
    technical_gain: f32,
) void {
    assert(red.len == green.len);
    assert(red.len == blue.len);
    assert(std.math.isFinite(technical_gain));
    assert(technical_gain > 0);
    assert(technical_gain <= 16);

    var index: u32 = 0;
    while (index < red.len) : (index += 1) {
        if (!std.math.isFinite(red[index]) or
            !std.math.isFinite(green[index]) or
            !std.math.isFinite(blue[index]))
        {
            red[index] = 0;
            green[index] = 0;
            blue[index] = 0;
            continue;
        }
        const luminance = 0.2627 * red[index] +
            0.6780 * green[index] +
            0.0593 * blue[index];
        if (luminance <= 0) {
            red[index] *= technical_gain;
            green[index] *= technical_gain;
            blue[index] *= technical_gain;
            continue;
        }
        const curved = profile.evaluate(.film, luminance * technical_gain);
        const scale = curved / luminance;
        red[index] *= scale;
        green[index] *= scale;
        blue[index] *= scale;
    }
}

test "bootstrap records preserve exact fixed-point points and flags" {
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    const curve = try database.loadFilmCurve(
        "curve.capture-one.CanonEOSR3-Auto.v1",
    );
    try std.testing.expectEqual(flags_capture_one_auto, curve.flags);
    try std.testing.expectEqual(format_version_capture_one, curve.format_version);
    try std.testing.expectEqual(@as(u8, 10), curve.film_count);
    try std.testing.expectEqual(@as(u8, 10), curve.ccd_count);
    try std.testing.expectEqual(@as(u8, 4), curve.contrast_count);
    try std.testing.expectApproxEqAbs(
        @as(f64, 103_606_663.0 / 4_294_967_295.0),
        curve.film[1].x,
        0.000000000000001,
    );
    try std.testing.expectApproxEqAbs(
        @as(f64, 180_941_103.0 / 4_294_967_295.0),
        curve.film[1].y,
        0.000000000000001,
    );
    try std.testing.expectApproxEqAbs(
        @as(f64, 235_007_647.0 / 4_294_967_295.0),
        curve.contrast[1].y,
        0.000000000000001,
    );
}

test "monotonic interpolation matches known vectors and boundary policy" {
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    const curve = try database.loadFilmCurve(
        "curve.capture-one.CanonEOS1DX2-Auto.v1",
    );
    const profile = try Profile.init(&curve);

    try std.testing.expectEqual(@as(f32, -0.25), profile.evaluate(.film, -0.25));
    try std.testing.expectEqual(@as(f32, 0), profile.evaluate(.film, 0));
    try std.testing.expectEqual(@as(f32, 1), profile.evaluate(.film, 1));
    try std.testing.expectEqual(@as(f32, 1), profile.evaluate(.film, 1.25));
    try std.testing.expectApproxEqAbs(
        @as(f32, 0.27164322),
        profile.evaluate(.film, 0.1),
        0.0000001,
    );
    try std.testing.expectApproxEqAbs(
        @as(f32, 0.6146044),
        profile.evaluate(.ccd, 0.25),
        0.0000001,
    );
    try std.testing.expectApproxEqAbs(
        @as(f32, 0.47484505),
        profile.evaluate(.contrast, 0.5),
        0.0000001,
    );

    var previous: f32 = -1;
    var sample: u32 = 0;
    while (sample <= 1024) : (sample += 1) {
        const input: f32 = @as(f32, @floatFromInt(sample)) / 1024;
        const output = profile.evaluate(.film, input);
        try std.testing.expect(output >= previous);
        try std.testing.expect(output >= 0);
        try std.testing.expect(output <= 1);
        previous = output;
    }
}

test "film application preserves chroma direction and rolls off luminance" {
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    const curve = try database.loadFilmCurve(
        "curve.capture-one.CanonEOSR3-Auto.v1",
    );
    const profile = try Profile.init(&curve);
    var red = [_]f32{ 0.2, 2.0, -0.2, std.math.nan(f32) };
    var green = [_]f32{ 0.1, 1.0, -0.1, 0.2 };
    var blue = [_]f32{ 0.05, 0.5, -0.05, 0.3 };
    var planes = image.Planes{
        .width = 4,
        .height = 1,
        .r = &red,
        .g = &green,
        .b = &blue,
    };
    const application = Application{
        .profile = &profile,
        .base_gain = 1.07,
        .sensor_range_gain = 1,
    };
    application.apply(&planes);
    try std.testing.expectApproxEqAbs(@as(f32, 2), red[0] / green[0], 0.000001);
    try std.testing.expectApproxEqAbs(@as(f32, 2), red[1] / green[1], 0.000001);
    try std.testing.expect(red[1] < 2);
    try std.testing.expectApproxEqAbs(@as(f32, -0.214), red[2], 0.000001);
    try std.testing.expectEqual(@as(f32, 0), red[3]);
    try std.testing.expectEqual(@as(f32, 0), green[3]);
    try std.testing.expectEqual(@as(f32, 0), blue[3]);
}
