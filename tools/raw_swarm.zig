//! Deterministic DNG parser swarm.
//!
//! With no paths it mutates a generated supported DNG and exercises metadata,
//! full decode, colour construction, and render. Paths add real files to the
//! metadata-parser swarm without routing proprietary bytes into LibRaw.

const std = @import("std");
const emu = @import("emu");

const file_bytes_max = std.Io.Limit.limited(512 * 1024 * 1024);
const runs_default: u32 = 10_000;
const mutations_max: u32 = 8;

const State = struct {
    value: u64,

    fn next(state: *State) u64 {
        state.value +%= 0x9E3779B97F4A7C15;
        var value = state.value;
        value = (value ^ (value >> 30)) *% 0xBF58476D1CE4E5B9;
        value = (value ^ (value >> 27)) *% 0x94D049BB133111EB;
        return value ^ (value >> 31);
    }

    fn less_than(state: *State, limit: usize) usize {
        std.debug.assert(limit > 0);
        return @intCast(state.next() % limit);
    }
};

const Options = struct {
    seed: u64 = 0x2B_2026,
    runs: u32 = runs_default,
    paths: std.ArrayList([]const u8) = .empty,

    fn deinit(options: *Options, gpa: std.mem.Allocator) void {
        options.paths.deinit(gpa);
        options.* = undefined;
    }
};

const Counts = struct {
    cases: u64 = 0,
    accepted_metadata: u64 = 0,
    accepted_decode: u64 = 0,
    accepted_render: u64 = 0,
    rejected: u64 = 0,
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    var options = try options_parse(gpa, init);
    defer options.deinit(gpa);

    const synthetic = try synthetic_make(gpa);
    defer gpa.free(synthetic);
    var state = State{ .value = options.seed };
    var counts = Counts{};
    try swarm(gpa, synthetic, options.runs, true, &state, &counts);

    for (options.paths.items) |path| {
        {
            const bytes = try std.Io.Dir.cwd().readFileAlloc(
                io,
                path,
                gpa,
                file_bytes_max,
            );
            defer gpa.free(bytes);
            try swarm(gpa, bytes, options.runs, false, &state, &counts);
        }
    }

    std.debug.print(
        "raw-swarm: seed={d} cases={d} metadata={d} decode={d} render={d} rejected={d}\n",
        .{
            options.seed,
            counts.cases,
            counts.accepted_metadata,
            counts.accepted_decode,
            counts.accepted_render,
            counts.rejected,
        },
    );
}

fn options_parse(gpa: std.mem.Allocator, init: std.process.Init) !Options {
    var options = Options{};
    errdefer options.deinit(gpa);
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--seed")) {
            options.seed = try std.fmt.parseInt(u64, args.next() orelse return error.Usage, 0);
        } else if (std.mem.eql(u8, arg, "--runs")) {
            options.runs = try std.fmt.parseInt(u32, args.next() orelse return error.Usage, 10);
            if (options.runs == 0) return error.Usage;
        } else {
            try options.paths.append(gpa, arg);
        }
    }
    return options;
}

fn synthetic_make(gpa: std.mem.Allocator) ![]u8 {
    var bayer: [32 * 24]u16 = undefined;
    for (&bayer, 0..) |*sample, index| {
        sample.* = @intCast(512 + (index * 97) % 14_000);
    }
    return emu.dng_write.write(gpa, .{
        .width = 32,
        .height = 24,
        .black_level = 512,
        .white_level = 15_000,
        .wb_neutral = .{ 0.5, 1, 0.7 },
        .bayer = &bayer,
        .compression = .lossless_jpeg,
        .tile = .{ .width = 16, .height = 12 },
    });
}

fn swarm(
    gpa: std.mem.Allocator,
    source: []const u8,
    runs: u32,
    full: bool,
    state: *State,
    counts: *Counts,
) !void {
    const mutable = try gpa.dupe(u8, source);
    defer gpa.free(mutable);
    var run: u32 = 0;
    while (run < runs) : (run += 1) {
        if (run % 4 == 0) {
            const length = state.less_than(mutable.len + 1);
            try candidate_check(gpa, mutable[0..length], full, counts);
        } else {
            var positions: [mutations_max]usize = undefined;
            var previous: [mutations_max]u8 = undefined;
            const mutation_count: u32 = @intCast(1 + state.less_than(mutations_max));
            for (0..mutation_count) |index| {
                const position = state.less_than(mutable.len);
                positions[index] = position;
                previous[index] = mutable[position];
                mutable[position] ^= @truncate(state.next() | 1);
            }
            try candidate_check(gpa, mutable, full, counts);
            var index = mutation_count;
            while (index > 0) {
                index -= 1;
                mutable[positions[index]] = previous[index];
            }
        }
    }
}

fn candidate_check(
    gpa: std.mem.Allocator,
    bytes: []const u8,
    full: bool,
    counts: *Counts,
) !void {
    counts.cases += 1;
    const metadata = emu.dng.decode_metadata(bytes) catch {
        counts.rejected += 1;
        return;
    };
    counts.accepted_metadata += 1;
    try metadata_check(metadata);
    if (!full) return;

    var raw = emu.dng.decode_raw(gpa, bytes) catch return;
    defer raw.deinit(gpa);
    counts.accepted_decode += 1;
    var rendered = emu.pipeline.render_decoded(
        gpa,
        &raw,
        .{ .engine_version = 2, .ops = &emu.recipe.default_ops },
        .{ .edge_px_max_out = 128 },
    ) catch return;
    defer rendered.deinit(gpa);
    if (rendered.rgba.len != @as(usize, rendered.width) * rendered.height * 4) {
        return error.InvalidRender;
    }
    counts.accepted_render += 1;
}

fn metadata_check(metadata: emu.dng.Metadata) !void {
    if (metadata.width == 0 or metadata.height == 0) return error.InvalidMetadata;
    if (@as(u64, metadata.width) * metadata.height > emu.image.pixel_count_max) {
        return error.InvalidMetadata;
    }
    if (!(metadata.white_level > metadata.black_level)) return error.InvalidMetadata;
    const transform = emu.color.Transform.init(metadata) catch return;
    for (transform.camera_to_rec2020.values) |value| {
        if (!std.math.isFinite(value)) return error.NonFiniteColorTransform;
    }
}
