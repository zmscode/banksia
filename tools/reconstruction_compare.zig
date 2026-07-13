//! Produce bounded reconstruction or camera-profile corpus pairs.

const std = @import("std");
const assert = std.debug.assert;
const emu = @import("emu");

const edge_px_max_out: u32 = 1440;
const file_bytes_max = std.Io.Limit.limited(64 * 1024 * 1024);

const Case = struct {
    id: []const u8,
    path: []const u8,
};

const Mode = enum {
    reconstruction,
    profile,
    film,
    safety,
};

const cases = [_]Case{
    .{ .id = "1dx2-backlight", .path = "tests/corpus/phase2b/canon-1dx2-backlight-action.dng" },
    .{ .id = "1dx2-detail", .path = "tests/corpus/phase2b/canon-1dx2-daylight-detail.dng" },
    .{ .id = "1dx2-contrast", .path = "tests/corpus/phase2b/canon-1dx2-high-contrast.dng" },
    .{ .id = "1dx2-iso12800", .path = "tests/corpus/phase2b/canon-1dx2-high-iso12800.dng" },
    .{ .id = "1dx2-skin", .path = "tests/corpus/phase2b/canon-1dx2-skin-iso1000.dng" },
    .{ .id = "1dx2-warm", .path = "tests/corpus/phase2b/canon-1dx2-warm-backlight.dng" },
    .{ .id = "r3-black-fabric", .path = "tests/corpus/phase2b/canon-r3-black-fabric.dng" },
    .{ .id = "r3-emerald-fabric", .path = "tests/corpus/phase2b/canon-r3-emerald-fabric.dng" },
};

pub fn main(init: std.process.Init) !void {
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    const mode_text = args.next() orelse return error.MissingMode;
    const mode = std.meta.stringToEnum(Mode, mode_text) orelse return error.InvalidMode;
    const output_directory = args.next() orelse return error.MissingOutputDirectory;
    var database = try emu.calibration.Database.open(emu.calibration.database_path_default);
    defer database.deinit();
    var case_count: u32 = 0;
    while (args.next()) |path| : (case_count += 1) {
        var id_buffer: [32]u8 = undefined;
        const id = try std.fmt.bufPrint(&id_buffer, "local-{d}", .{case_count});
        try compareCase(init.gpa, init.io, &database, output_directory, mode, .{
            .id = id,
            .path = path,
        });
    }
    if (case_count == 0) {
        for (cases) |case| {
            try compareCase(init.gpa, init.io, &database, output_directory, mode, case);
        }
        case_count = cases.len;
    }
    std.debug.print("{s}-compare: {d} visual pairs written to {s}\n", .{
        @tagName(mode),
        case_count,
        output_directory,
    });
}

fn compareCase(
    gpa: std.mem.Allocator,
    io: std.Io,
    database: *emu.calibration.Database,
    output_directory: []const u8,
    mode: Mode,
    case: Case,
) !void {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, case.path, gpa, file_bytes_max);
    defer gpa.free(bytes);
    var raw = try emu.raw.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    const resolved = try database.resolve(&raw.metadata, .{});
    const reconstruction = try emu.reconstruction.defaults(&resolved);

    var mft2 = if (mode == .reconstruction)
        null
    else
        try loadProfile(database, gpa, &resolved);
    defer if (mft2) |*profile| profile.deinit(gpa);
    const camera_profile = if (mft2) |*record|
        emu.pipeline.CameraProfile{ .nonlinear = try emu.icc_profile.Profile.init(record) }
    else
        emu.pipeline.CameraProfile.technical_matrix;
    var curve_record = if (mode == .film or mode == .safety)
        try loadFilmCurve(database, &resolved)
    else
        null;
    var curve_profile: ?emu.film_curve.Profile = null;
    if (curve_record) |*record| curve_profile = try emu.film_curve.Profile.init(record);
    const curve_rendering = if (curve_profile) |*profile|
        emu.film_curve.Rendering{ .capture_one_auto = .{
            .profile = profile,
            .base_gain = resolvedBaseGain(&resolved),
            .sensor_range_gain = resolvedSensorRangeGain(&resolved),
        } }
    else
        emu.film_curve.Rendering.linear;

    const left_recipe = emu.pipeline.Recipe{
        .engine_version = switch (mode) {
            .reconstruction => 2,
            .profile => 3,
            .film, .safety => 5,
        },
        .camera_profile = if (mode == .film) .resolved_nonlinear else .technical_matrix,
        .film_curve = .linear,
        .ops = &emu.recipe.default_ops,
    };
    var legacy = try emu.pipeline.render_decoded(gpa, &raw, left_recipe, .{
        .edge_px_max_out = edge_px_max_out,
        .reconstruction = if (mode == .reconstruction) .legacy else reconstruction,
        .camera_profile = if (mode == .film) camera_profile else .technical_matrix,
        .film_curve = .linear,
    });
    defer legacy.deinit(gpa);
    const legacy_snapshot = try gpa.dupe(u8, legacy.rgba);
    defer gpa.free(legacy_snapshot);
    var candidate = try emu.pipeline.render_decoded(gpa, &raw, .{
        .engine_version = switch (mode) {
            .reconstruction => 3,
            .profile => 4,
            .film, .safety => 5,
        },
        .camera_profile = if (mode == .reconstruction)
            .technical_matrix
        else
            .resolved_nonlinear,
        .film_curve = if (mode == .film or mode == .safety)
            .capture_one_auto
        else
            .linear,
        .ops = &emu.recipe.default_ops,
    }, .{
        .edge_px_max_out = edge_px_max_out,
        .reconstruction = reconstruction,
        .camera_profile = camera_profile,
        .film_curve = curve_rendering,
    });
    defer candidate.deinit(gpa);
    assert(legacy.width == candidate.width);
    assert(legacy.height == candidate.height);
    assert(std.mem.eql(u8, legacy_snapshot, legacy.rgba));

    const pair_width = legacy.width * 2;
    const pair = try gpa.alloc(u8, @as(usize, pair_width) * legacy.height * 4);
    defer gpa.free(pair);
    var difference_sum: u64 = 0;
    var difference_max: u8 = 0;
    for (0..legacy.height) |y| {
        const source_offset = y * @as(usize, legacy.width) * 4;
        const target_offset = y * @as(usize, pair_width) * 4;
        const row_bytes = @as(usize, legacy.width) * 4;
        @memcpy(pair[target_offset..][0..row_bytes], legacy.rgba[source_offset..][0..row_bytes]);
        @memcpy(
            pair[target_offset + row_bytes ..][0..row_bytes],
            candidate.rgba[source_offset..][0..row_bytes],
        );
    }
    for (legacy.rgba, candidate.rgba) |before, after| {
        const difference = @abs(@as(i16, before) - @as(i16, after));
        difference_sum += @intCast(difference);
        difference_max = @max(difference_max, @as(u8, @intCast(difference)));
    }
    const channel_count: f64 = @floatFromInt(legacy.rgba.len);
    const difference_mean = @as(f64, @floatFromInt(difference_sum)) / channel_count;

    const png = try emu.png.encode_rgba(gpa, pair_width, legacy.height, pair);
    defer gpa.free(png);
    const output_path = try std.fmt.allocPrint(
        gpa,
        "{s}/{s}-{s}.png",
        .{
            output_directory,
            case.id,
            switch (mode) {
                .reconstruction => "v2-left-v3-right",
                .profile => "matrix-left-profile-right",
                .film => "linear-left-auto-right",
                .safety => "safe-left-calibrated-right",
            },
        },
    );
    defer gpa.free(output_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = png });
    std.debug.print("{s}-compare: {s} mean_abs={d:.3} max={d}\n", .{
        @tagName(mode),
        case.id,
        difference_mean,
        difference_max,
    });
}

fn loadFilmCurve(
    database: *emu.calibration.Database,
    resolved: *const emu.calibration.ResolvedCalibration,
) !emu.calibration.FilmCurve {
    const curve_id = switch (resolved.camera) {
        .resolved => |camera| camera.film_curve_id.slice(),
        .generic_fallback => return error.FilmCurveUnavailable,
    };
    return database.loadFilmCurve(curve_id);
}

fn resolvedBaseGain(resolved: *const emu.calibration.ResolvedCalibration) f32 {
    const camera_gain = switch (resolved.camera) {
        .resolved => |camera| camera.base_gain,
        .generic_fallback => unreachable,
    };
    return switch (resolved.iso) {
        .resolved => |iso| if (iso.base_gain) |value| value.value else camera_gain,
        .skipped => camera_gain,
    };
}

fn resolvedSensorRangeGain(resolved: *const emu.calibration.ResolvedCalibration) f32 {
    const camera_gain = switch (resolved.camera) {
        .resolved => |camera| camera.sensor_range_gain,
        .generic_fallback => unreachable,
    };
    return switch (resolved.iso) {
        .resolved => |iso| if (iso.sensor_range_gain) |value| value.value else camera_gain,
        .skipped => camera_gain,
    };
}

fn loadProfile(
    database: *emu.calibration.Database,
    gpa: std.mem.Allocator,
    resolved: *const emu.calibration.ResolvedCalibration,
) !emu.calibration.Mft2 {
    const profile_id = switch (resolved.camera) {
        .resolved => |camera| camera.input_profile_id.slice(),
        .generic_fallback => return error.ProfileUnavailable,
    };
    return database.loadMft2(gpa, profile_id);
}
