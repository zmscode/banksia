//! The golden-render conformance harness: banksia's speedometer.
//!
//! Synthetic scenes are written as real DNG blobs (`emu.dng_write`), decoded
//! by the real decoder, rendered by the real pipeline, and SHA-256 hashed.
//! Hashes are compared against `golden/baseline.json`; any drift fails CI.
//!
//!   zig build golden              compare against the committed baseline
//!   zig build golden -- --update  rewrite the baseline (then commit it)
//!
//! The corpus is synthetic and the oracle is "byte-identical to what this
//! engine produced when the baseline was blessed" — an anti-regression
//! ratchet. Perceptual scoring against dcraw/darktable-cli references
//! arrives with a vendored real-camera corpus (plan.md, Phase 0 deviation).

const std = @import("std");
const assert = std.debug.assert;
const emu = @import("emu");
const wombat = @import("wombat");

const baseline_path = "golden/baseline.json";
const file_bytes_max = std.Io.Limit.limited(16 * 1024 * 1024);

const black_level: u16 = 1024;
const white_level: u16 = 15360;

const rggb = [4]emu.dng.CfaColor{ .red, .green, .green, .blue };
const bggr = [4]emu.dng.CfaColor{ .blue, .green, .green, .red };

const Scene = struct {
    name: []const u8,
    width: u32,
    height: u32,
    cfa: [4]emu.dng.CfaColor = rggb,
    wb_neutral: [3]f32 = .{ 0.55, 1.0, 0.7 },
    generate: *const fn (x: u32, y: u32, width: u32, height: u32, color: emu.dng.CfaColor) u16,
};

/// Odd dimensions on purpose: they exercise the demosaic borders and the
/// kernels' scalar tails.
const scenes = [_]Scene{
    .{ .name = "gradient", .width = 64, .height = 48, .generate = generate_gradient },
    .{ .name = "patches", .width = 64, .height = 48, .generate = generate_patches },
    .{ .name = "noise", .width = 97, .height = 61, .generate = generate_noise },
    .{ .name = "checker", .width = 33, .height = 21, .generate = generate_checker },
    .{
        .name = "highlight",
        .width = 80,
        .height = 59,
        .cfa = bggr,
        .generate = generate_highlight,
    },
};

const pushed_ops = [_]emu.pipeline.Op{
    .{ .black_point = .{} },
    .{ .white_balance = .{ .as_shot = false, .gain_r = 2.0, .gain_g = 1.0, .gain_b = 1.5 } },
    .{ .demosaic = .{} },
    .{ .exposure = .{ .ev = 0.8 } },
    .{ .tone_curve = .{ .contrast = 0.5 } },
    .{ .srgb_encode = .{} },
};

const Variant = struct {
    name: []const u8,
    recipe: emu.pipeline.Recipe,
    /// Longest output edge; 0 renders at full resolution (pipeline contract).
    edge_px_max_out: u32 = 0,
    compression: emu.dng_write.Compression = .none,
    tile: ?emu.dng_write.Tile = null,
    /// Container-only variants must render bit-identically to `neutral`:
    /// the runner enforces it, beyond the baseline hashes.
    must_match_neutral: bool = false,
};

const variants = [_]Variant{
    .{ .name = "neutral", .recipe = .{ .ops = &emu.recipe.default_ops } },
    .{ .name = "pushed", .recipe = .{ .ops = &pushed_ops } },
    // Baselines the box-downsample kernel through the whole engine; 24 is
    // small enough that every scene actually downsamples.
    .{
        .name = "preview",
        .recipe = .{ .ops = &emu.recipe.default_ops },
        .edge_px_max_out = 24,
    },
    // The same sensor through the real-camera container: lossless JPEG in
    // a tile grid that clips at every scene's edges.
    .{
        .name = "lj-tiled",
        .recipe = .{ .ops = &emu.recipe.default_ops },
        .compression = .lossless_jpeg,
        .tile = .{ .width = 32, .height = 16 },
        .must_match_neutral = true,
    },
};

const case_count = scenes.len * variants.len;

const Result = struct {
    name: []const u8,
    hash_hex: [64]u8,
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next(); // argv[0]
    var update = false;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--update")) update = true else {
            std.debug.print("golden: unknown argument '{s}'\n", .{arg});
            return error.Usage;
        }
    }

    var results: [case_count]Result = undefined;
    var index: usize = 0;
    defer for (results[0..index]) |result| gpa.free(result.name);
    for (scenes) |scene| {
        var neutral_hash: ?[64]u8 = null;
        for (variants) |variant| {
            results[index] = try case_run(gpa, scene, variant);
            if (std.mem.eql(u8, variant.name, "neutral")) {
                neutral_hash = results[index].hash_hex;
            }
            // Same sensor, different container: any divergence is a decode
            // bug, catchable without touching the baseline.
            if (variant.must_match_neutral and
                !std.mem.eql(u8, &results[index].hash_hex, &neutral_hash.?))
            {
                std.debug.print("FAIL {s}: container changed the pixels\n", .{
                    results[index].name,
                });
                index += 1;
                return error.GoldenRegression;
            }
            index += 1;
        }
    }
    assert(index == case_count);

    if (update) return baseline_write(gpa, io, &results);
    return baseline_compare(gpa, io, &results);
}

fn case_run(gpa: std.mem.Allocator, scene: Scene, variant: Variant) !Result {
    const count = @as(usize, scene.width) * scene.height;
    const bayer = try gpa.alloc(u16, count);
    defer gpa.free(bayer);
    var y: u32 = 0;
    while (y < scene.height) : (y += 1) {
        var x: u32 = 0;
        while (x < scene.width) : (x += 1) {
            const color = scene.cfa[((y & 1) << 1) | (x & 1)];
            bayer[@as(usize, y) * scene.width + x] =
                scene.generate(x, y, scene.width, scene.height, color);
        }
    }

    // Through the *whole* engine: container write, container decode,
    // render. The decoder is exercised by every golden case.
    const blob = try emu.dng_write.write(gpa, .{
        .width = scene.width,
        .height = scene.height,
        .cfa = scene.cfa,
        .black_level = black_level,
        .white_level = white_level,
        .wb_neutral = scene.wb_neutral,
        .bayer = bayer,
        .compression = variant.compression,
        .tile = variant.tile,
    });
    defer gpa.free(blob);

    var sensor = try emu.dng.decode(gpa, blob);
    defer sensor.deinit(gpa);
    var rendered = try emu.pipeline.render(gpa, &sensor, variant.recipe, .{
        .edge_px_max_out = variant.edge_px_max_out,
    });
    defer rendered.deinit(gpa);

    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var dims: [8]u8 = undefined;
    std.mem.writeInt(u32, dims[0..4], rendered.width, .little);
    std.mem.writeInt(u32, dims[4..8], rendered.height, .little);
    hasher.update(&dims);
    hasher.update(rendered.rgba);
    var digest: [32]u8 = undefined;
    hasher.final(&digest);

    var result = Result{ .name = undefined, .hash_hex = undefined };
    result.hash_hex = std.fmt.bytesToHex(digest, .lower);
    result.name = try std.fmt.allocPrint(gpa, "{s}-{s}", .{ scene.name, variant.name });
    return result;
}

fn baseline_write(gpa: std.mem.Allocator, io: std.Io, results: []const Result) !void {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(gpa);
    try text.appendSlice(gpa, "{\n");
    for (results, 0..) |result, i| {
        const comma: []const u8 = if (i + 1 < results.len) "," else "";
        try text.print(gpa, "    \"{s}\": \"{s}\"{s}\n", .{
            result.name, result.hash_hex, comma,
        });
    }
    try text.appendSlice(gpa, "}\n");
    try wombat.vfs.user_file_write(io, std.Io.Dir.cwd(), baseline_path, text.items);
    std.debug.print("golden: baseline updated, {d} cases -> {s}\n", .{
        results.len, baseline_path,
    });
}

fn baseline_compare(gpa: std.mem.Allocator, io: std.Io, results: []const Result) !void {
    const bytes = std.Io.Dir.cwd().readFileAlloc(io, baseline_path, gpa, file_bytes_max) catch {
        std.debug.print(
            "golden: no baseline at {s} — run `zig build golden -- --update` and commit it\n",
            .{baseline_path},
        );
        return error.GoldenBaselineMissing;
    };
    defer gpa.free(bytes);

    var parsed = try std.json.parseFromSlice(std.json.Value, gpa, bytes, .{});
    defer parsed.deinit();
    const object = switch (parsed.value) {
        .object => |o| o,
        else => return error.GoldenBaselineCorrupt,
    };

    var pass: u32 = 0;
    var fail: u32 = 0;
    for (results) |result| {
        const expected = object.get(result.name) orelse {
            std.debug.print("FAIL {s}: not in baseline (new case? --update)\n", .{result.name});
            fail += 1;
            continue;
        };
        if (expected != .string or !std.mem.eql(u8, expected.string, &result.hash_hex)) {
            std.debug.print("FAIL {s}: output drifted from baseline\n", .{result.name});
            fail += 1;
            continue;
        }
        pass += 1;
    }
    // Baseline entries with no matching case are stale: the corpus only grows.
    if (object.count() != results.len) {
        std.debug.print(
            "golden: baseline has {d} entries, corpus has {d} — stale baseline\n",
            .{ object.count(), results.len },
        );
        fail += 1;
    }

    std.debug.print("golden: {d} pass, {d} fail, of {d} cases\n", .{ pass, fail, results.len });
    if (fail > 0) return error.GoldenRegression;
    assert(pass == results.len);
}

// ---- scene generators ----------------------------------------------------
// Integer in, integer out, no shared state: each site's value is a pure
// function of its coordinates — the corpus needs no stored fixtures.

fn range_scale(unit_millionths: u64) u16 {
    assert(unit_millionths <= 1_000_000);
    const span: u64 = white_level - black_level;
    return @intCast(black_level + (span * unit_millionths) / 1_000_000);
}

fn generate_gradient(x: u32, y: u32, width: u32, height: u32, color: emu.dng.CfaColor) u16 {
    _ = y;
    _ = height;
    _ = color;
    assert(x < width);
    return range_scale(@as(u64, x) * 1_000_000 / (width - 1));
}

fn generate_patches(x: u32, y: u32, width: u32, height: u32, color: emu.dng.CfaColor) u16 {
    assert(x < width);
    assert(y < height);
    const patch = (y * 4 / height) * 4 + (x * 4 / width);
    const level: u64 = switch (color) {
        .red => if (patch & 1 != 0) 900_000 else 150_000,
        .green => if (patch & 2 != 0) 800_000 else 200_000,
        .blue => if (patch & 4 != 0) 700_000 else 100_000,
    };
    return range_scale(level);
}

fn generate_noise(x: u32, y: u32, width: u32, height: u32, color: emu.dng.CfaColor) u16 {
    assert(x < width);
    assert(y < height);
    _ = color;
    const site = @as(u64, y) * width + x;
    return range_scale(splitmix64(site) % 1_000_001);
}

fn generate_checker(x: u32, y: u32, width: u32, height: u32, color: emu.dng.CfaColor) u16 {
    assert(x < width);
    assert(y < height);
    _ = color;
    return range_scale(if ((x / 2 + y / 2) % 2 == 0) 850_000 else 120_000);
}

/// A radial hot spot whose centre clips at the white level: exercises
/// highlight clamping through black subtraction and the tone curve.
fn generate_highlight(x: u32, y: u32, width: u32, height: u32, color: emu.dng.CfaColor) u16 {
    assert(x < width);
    assert(y < height);
    _ = color;
    const dx = @as(i64, x) - width / 2;
    const dy = @as(i64, y) - height / 2;
    const dist2: u64 = @intCast(dx * dx + dy * dy);
    const falloff = dist2 * 1_400_000 / (@as(u64, width) * width / 4);
    const level = if (falloff >= 1_300_000) 0 else 1_300_000 - falloff;
    return range_scale(@min(level, 1_000_000));
}

/// SplitMix64: the deterministic integer generator the doctrine calls for —
/// no `std` PRNG churn, no floats, reproducible forever.
fn splitmix64(state: u64) u64 {
    var z = state +% 0x9E3779B97F4A7C15;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}
