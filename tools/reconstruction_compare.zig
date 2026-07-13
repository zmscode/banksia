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
    if (args.next() != null) return error.TooManyArguments;

    var database = try emu.calibration.Database.open(emu.calibration.database_path_default);
    defer database.deinit();
    for (cases) |case| {
        try compareCase(init.gpa, init.io, &database, output_directory, mode, case);
    }
    std.debug.print("{s}-compare: {d} visual pairs written to {s}\n", .{
        @tagName(mode),
        cases.len,
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
    var raw = try emu.dng.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    const resolved = try database.resolve(&raw.metadata, .{});
    const reconstruction = try emu.reconstruction.defaults(&resolved);

    const left_recipe = emu.pipeline.Recipe{
        .engine_version = if (mode == .reconstruction) 2 else 3,
        .ops = &emu.recipe.default_ops,
    };
    var legacy = try emu.pipeline.render_decoded(gpa, &raw, left_recipe, .{
        .edge_px_max_out = edge_px_max_out,
        .reconstruction = if (mode == .reconstruction) .legacy else reconstruction,
    });
    defer legacy.deinit(gpa);
    const legacy_snapshot = try gpa.dupe(u8, legacy.rgba);
    defer gpa.free(legacy_snapshot);
    var mft2 = if (mode == .profile)
        try loadProfile(database, gpa, &resolved)
    else
        null;
    defer if (mft2) |*profile| profile.deinit(gpa);
    const camera_profile = if (mft2) |*record|
        emu.pipeline.CameraProfile{ .nonlinear = try emu.icc_profile.Profile.init(record) }
    else
        emu.pipeline.CameraProfile.technical_matrix;
    var candidate = try emu.pipeline.render_decoded(gpa, &raw, .{
        .engine_version = if (mode == .reconstruction) 3 else 4,
        .camera_profile = if (mode == .profile) .resolved_nonlinear else .technical_matrix,
        .ops = &emu.recipe.default_ops,
    }, .{
        .edge_px_max_out = edge_px_max_out,
        .reconstruction = reconstruction,
        .camera_profile = camera_profile,
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
            if (mode == .reconstruction) "v2-left-v3-right" else "matrix-left-profile-right",
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
