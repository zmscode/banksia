//! Mandatory Phase 2B committed-corpus conformance gate.

const std = @import("std");
const emu = @import("emu");

const file_bytes_max = std.Io.Limit.limited(64 * 1024 * 1024);

const Case = struct {
    path: []const u8,
    source_sha256: []const u8,
    render_sha256: []const u8,
    width: u32,
    height: u32,
    output_width: u32,
    output_height: u32,
    orientation: emu.dng.Orientation,
    compression: emu.dng.Compression,
    make: []const u8,
    model: []const u8,
    iso: u16,
};

const cases = [_]Case{
    .{
        .path = "tests/corpus/phase2b/canon-1dx2-backlight-action.dng",
        .source_sha256 = "05e53b59e51049747675877c979e4493be3cd6ce3d13d5b057069105a4434fe1",
        .render_sha256 = "e4c971a70df89b693cc34a83c7ac9cd16f0f1a883fd07375d6bd8b19b7b49065",
        .width = 5496,
        .height = 3670,
        .output_width = 3648,
        .output_height = 5472,
        .orientation = .rotate_270_clockwise,
        .compression = .lossless_jpeg,
        .make = "Canon",
        .model = "EOS-1D X Mark II",
        .iso = 100,
    },
    .{
        .path = "tests/corpus/phase2b/canon-1dx2-daylight-detail.dng",
        .source_sha256 = "3673bf27cf382b3669fbeca33ab93a8cd6b80fd8c36e77ca3a5a6dfa79c5eb16",
        .render_sha256 = "b86ffdc49b25faf75a81e5cda325660458393b44116eed115d54a40a345769ee",
        .width = 5496,
        .height = 3670,
        .output_width = 5472,
        .output_height = 3648,
        .orientation = .normal,
        .compression = .none,
        .make = "Canon",
        .model = "EOS-1D X Mark II",
        .iso = 100,
    },
    .{
        .path = "tests/corpus/phase2b/canon-1dx2-high-contrast.dng",
        .source_sha256 = "d1f5d56c1279b319fbca4eb11facc25f5885c2d5580d20e879e3846505a0d7fd",
        .render_sha256 = "bc91771b01f532beff73321f36ff5995a57f118ad0bbd9d15189e5fb7bb74b4d",
        .width = 5496,
        .height = 3670,
        .output_width = 5472,
        .output_height = 3648,
        .orientation = .normal,
        .compression = .none,
        .make = "Canon",
        .model = "EOS-1D X Mark II",
        .iso = 500,
    },
    .{
        .path = "tests/corpus/phase2b/canon-1dx2-high-iso12800.dng",
        .source_sha256 = "377aaf48024398323fee31686b133378e00ee3b8b50b22e7707729cf73439b5f",
        .render_sha256 = "a825a3d7f13322e916b47cacc83a274f33423405f6bc33a9cd4df778233919da",
        .width = 5496,
        .height = 3670,
        .output_width = 5472,
        .output_height = 3648,
        .orientation = .normal,
        .compression = .lossless_jpeg,
        .make = "Canon",
        .model = "EOS-1D X Mark II",
        .iso = 12800,
    },
    .{
        .path = "tests/corpus/phase2b/canon-1dx2-skin-iso1000.dng",
        .source_sha256 = "a205bb8496d6a527b37d989a72f9f5831106f1310f1e6f3cc869536768137e39",
        .render_sha256 = "ceaeb1be41be49e61bd55d5adff4f834f1dcee3839da544f493dc07b883f14c4",
        .width = 5496,
        .height = 3670,
        .output_width = 3648,
        .output_height = 5472,
        .orientation = .rotate_270_clockwise,
        .compression = .lossless_jpeg,
        .make = "Canon",
        .model = "EOS-1D X Mark II",
        .iso = 1000,
    },
    .{
        .path = "tests/corpus/phase2b/canon-1dx2-warm-backlight.dng",
        .source_sha256 = "ea90d5c5b7e668b1b0e4abc42ca2279d5374c073bf9f0d52d80ba7a803fa47c2",
        .render_sha256 = "58a72213b271e3c14d23eb89fb9a2caf6248ef989ee2b631e1f8771363f87ced",
        .width = 5496,
        .height = 3670,
        .output_width = 3648,
        .output_height = 5472,
        .orientation = .rotate_270_clockwise,
        .compression = .lossless_jpeg,
        .make = "Canon",
        .model = "EOS-1D X Mark II",
        .iso = 1600,
    },
    .{
        .path = "tests/corpus/phase2b/canon-r3-black-fabric.dng",
        .source_sha256 = "3ffb3f58b61a47d54567c85917428032a197a7de3dcdb5c6020c8b3803998bc9",
        .render_sha256 = "a4342306286cf7ca68b3aa8347b83987d131a20595dc8b12e4ad2e5548cbebff",
        .width = 6032,
        .height = 4032,
        .output_width = 4000,
        .output_height = 6000,
        .orientation = .rotate_270_clockwise,
        .compression = .lossless_jpeg,
        .make = "Canon",
        .model = "EOS R3",
        .iso = 100,
    },
    .{
        .path = "tests/corpus/phase2b/canon-r3-emerald-fabric.dng",
        .source_sha256 = "c3706b854bc04d5d1fa593af018ac16b1aad8c372a69cf9df378efbcaa895bd3",
        .render_sha256 = "a40773e62d28015511908ea028e9051a52576d2494b3152c28df502aa117670b",
        .width = 6032,
        .height = 4032,
        .output_width = 4000,
        .output_height = 6000,
        .orientation = .rotate_270_clockwise,
        .compression = .lossless_jpeg,
        .make = "Canon",
        .model = "EOS R3",
        .iso = 100,
    },
};

pub fn main(init: std.process.Init) !void {
    const print_only = options_parse(init);
    var passed: u32 = 0;
    for (cases) |case| {
        try case_run(init.gpa, init.io, case, print_only);
        passed += 1;
    }
    std.debug.print("ci-corpus: {d} full native-DNG renders passed\n", .{passed});
}

fn options_parse(init: std.process.Init) bool {
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    const first = args.next() orelse return false;
    if (!std.mem.eql(u8, first, "--print")) return false;
    return args.next() == null;
}

fn case_run(gpa: std.mem.Allocator, io: std.Io, case: Case, print_only: bool) !void {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, case.path, gpa, file_bytes_max);
    defer gpa.free(bytes);
    try hash_check(case.path, bytes, case.source_sha256);
    var raw = try emu.dng.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    try metadata_check(raw.metadata, case);

    var rendered = try emu.pipeline.render_decoded(
        gpa,
        &raw,
        .{ .engine_version = 2, .ops = &emu.recipe.default_ops },
        .{},
    );
    defer rendered.deinit(gpa);
    try std.testing.expectEqual(case.output_width, rendered.width);
    try std.testing.expectEqual(case.output_height, rendered.height);
    const render_hash = render_hash_make(rendered);
    if (print_only) {
        std.debug.print("{s}  {s}\n", .{ render_hash, case.path });
    } else if (!std.mem.eql(u8, &render_hash, case.render_sha256)) {
        std.debug.print("ci-corpus: render drift {s}: {s}\n", .{ case.path, render_hash });
        return error.RenderRegression;
    }
}

fn metadata_check(metadata: emu.dng.Metadata, case: Case) !void {
    try std.testing.expectEqual(case.width, metadata.width);
    try std.testing.expectEqual(case.height, metadata.height);
    try std.testing.expectEqual(case.orientation, metadata.orientation);
    try std.testing.expectEqual(case.compression, metadata.compression);
    try std.testing.expectEqualStrings(case.make, metadata.make.slice());
    try std.testing.expectEqualStrings(case.model, metadata.model.slice());
    try std.testing.expectEqual(@as(f32, @floatFromInt(case.iso)), metadata.iso.?);
    try std.testing.expect(metadata.color_matrix_1 != null);
}

fn hash_check(path: []const u8, bytes: []const u8, expected: []const u8) !void {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, expected)) {
        std.debug.print("ci-corpus: source drift {s}: {s}\n", .{ path, actual });
        return error.SourceRegression;
    }
}

fn render_hash_make(rendered: emu.pipeline.Rendered) [64]u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var dimensions: [8]u8 = undefined;
    std.mem.writeInt(u32, dimensions[0..4], rendered.width, .little);
    std.mem.writeInt(u32, dimensions[4..8], rendered.height, .little);
    hasher.update(&dimensions);
    hasher.update(rendered.rgba);
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}
