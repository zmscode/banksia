//! Produce bounded v2/v3 corpus pairs for the Phase 2D.4 visual gate.

const std = @import("std");
const assert = std.debug.assert;
const emu = @import("emu");

const edge_px_max_out: u32 = 1440;
const file_bytes_max = std.Io.Limit.limited(64 * 1024 * 1024);

const Case = struct {
    id: []const u8,
    path: []const u8,
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
    const output_directory = args.next() orelse return error.MissingOutputDirectory;
    if (args.next() != null) return error.TooManyArguments;

    var database = try emu.calibration.Database.open(emu.calibration.database_path_default);
    defer database.deinit();
    for (cases) |case| {
        try compareCase(init.gpa, init.io, &database, output_directory, case);
    }
    std.debug.print("2d4-compare: {d} visual pairs written to {s}\n", .{
        cases.len,
        output_directory,
    });
}

fn compareCase(
    gpa: std.mem.Allocator,
    io: std.Io,
    database: *emu.calibration.Database,
    output_directory: []const u8,
    case: Case,
) !void {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, case.path, gpa, file_bytes_max);
    defer gpa.free(bytes);
    var raw = try emu.dng.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    const resolved = try database.resolve(&raw.metadata, .{});
    const reconstruction = try emu.reconstruction.defaults(&resolved);

    var legacy = try emu.pipeline.render_decoded(
        gpa,
        &raw,
        .{ .engine_version = 2, .ops = &emu.recipe.default_ops },
        .{ .edge_px_max_out = edge_px_max_out },
    );
    defer legacy.deinit(gpa);
    var candidate = try emu.pipeline.render_decoded(
        gpa,
        &raw,
        .{ .engine_version = 3, .ops = &emu.recipe.default_ops },
        .{ .edge_px_max_out = edge_px_max_out, .reconstruction = reconstruction },
    );
    defer candidate.deinit(gpa);
    assert(legacy.width == candidate.width);
    assert(legacy.height == candidate.height);

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
        "{s}/{s}-v2-left-v3-right.png",
        .{ output_directory, case.id },
    );
    defer gpa.free(output_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = png });
    std.debug.print("2d4-compare: {s} mean_abs={d:.3} max={d}\n", .{
        case.id,
        difference_mean,
        difference_max,
    });
}
