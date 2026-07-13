//! Resolve calibration records into the compact Bayer reconstruction defaults.
//!
//! SQLite remains control-plane storage. This module is the single boundary
//! that converts a resolved snapshot into primitive values consumed by the CPU
//! and Metal data planes.

const std = @import("std");
const assert = std.debug.assert;
const calibration = @import("calibration.zig");
const pipeline = @import("pipeline.zig");

pub const Error = error{InvalidCalibration};

const camera_id_one_dx = "camera.capture-one.canon-eos-1d-x-mark-ii.v1";
const camera_id_r3 = "camera.capture-one.canon-eos-r3.v1";

pub fn defaults(
    resolved: *const calibration.ResolvedCalibration,
) Error!pipeline.ReconstructionDefaults {
    var result = pipeline.ReconstructionDefaults{
        .enabled = true,
        .highlight_recovery_start = pipeline.highlight_recovery_start_bootstrap,
    };
    switch (resolved.camera) {
        .generic_fallback => {},
        .resolved => |camera| {
            result.adaptive_green_enabled = camera.adaptive_green_enabled;
            if (std.mem.eql(u8, camera.camera_id.slice(), camera_id_one_dx)) {
                result.anti_color_aliasing_strength = 0;
            } else if (std.mem.eql(u8, camera.camera_id.slice(), camera_id_r3)) {
                result.anti_color_aliasing_strength = 1;
            } else {
                return error.InvalidCalibration;
            }
        },
    }
    switch (resolved.iso) {
        .skipped => {},
        .resolved => |iso| {
            if (iso.long_exposure_cleanup) |value| {
                if (value.value < 0) return error.InvalidCalibration;
                if (value.value > 100) return error.InvalidCalibration;
                result.hot_pixel_cleanup_amount = value.value;
            }
            if (iso.anti_color_aliasing) |value| {
                if (value.value < 0) return error.InvalidCalibration;
                if (value.value > 1) return error.InvalidCalibration;
                result.anti_color_aliasing_strength = value.value;
            }
            // At high ISO the extracted anti-alias value otherwise classifies
            // stochastic sensor noise as coherent moire. Until 2D.7 supplies
            // the calibrated noise model, retain a conservative bounded blend.
            if (iso.requested_iso >= 6400) {
                result.anti_color_aliasing_strength = @min(
                    result.anti_color_aliasing_strength,
                    0.25,
                );
            }
        },
    }
    result.assertValid();
    assert(result.enabled);
    return result;
}

test "generic reconstruction fallback is explicit and bounded" {
    const resolved = calibration.ResolvedCalibration{
        .bundle_id = try calibration.Text.init("bundle.test"),
        .processing_graph_id = try calibration.Text.init("graph.test"),
        .camera = .{ .generic_fallback = .unsupported_camera },
        .iso = .{ .skipped = .unsupported_camera },
        .lens = .{ .correction_off = .unsupported_lens },
        .state = .generic_fallback,
    };
    const result = try defaults(&resolved);
    try std.testing.expect(result.enabled);
    try std.testing.expect(!result.adaptive_green_enabled);
    try std.testing.expectEqual(@as(f32, 0), result.hot_pixel_cleanup_amount);
    try std.testing.expectEqual(@as(f32, 1), result.anti_color_aliasing_strength);
    try std.testing.expectEqual(
        pipeline.highlight_recovery_start_bootstrap,
        result.highlight_recovery_start,
    );
}
