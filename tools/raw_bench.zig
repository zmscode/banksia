//! ReleaseFast real-camera timing harness.
//!
//! Measures metadata parse, sensor decode, warm edge-1024 render, and warm
//! full render independently. Files are read before timing.

const std = @import("std");
const emu = @import("emu");

const file_bytes_max = std.Io.Limit.limited(512 * 1024 * 1024);
const iterations_max: u32 = 9;

const Options = struct {
    iterations: u32 = 3,
    paths: std.ArrayList([]const u8) = .empty,

    fn deinit(options: *Options, gpa: std.mem.Allocator) void {
        options.paths.deinit(gpa);
        options.* = undefined;
    }
};

const Samples = struct {
    values: [iterations_max]u64 = @splat(0),
    len: u32 = 0,

    fn append(samples: *Samples, value: u64) void {
        std.debug.assert(samples.len < iterations_max);
        samples.values[samples.len] = value;
        samples.len += 1;
    }

    fn percentile(samples: Samples, numerator: u32, denominator: u32) u64 {
        std.debug.assert(samples.len > 0);
        var sorted = samples.values;
        var index: u32 = 1;
        while (index < samples.len) : (index += 1) {
            const value = sorted[index];
            var insertion = index;
            while (insertion > 0 and sorted[insertion - 1] > value) {
                sorted[insertion] = sorted[insertion - 1];
                insertion -= 1;
            }
            sorted[insertion] = value;
        }
        const rank = (@as(u64, samples.len - 1) * numerator) / denominator;
        return sorted[@intCast(rank)];
    }

    fn report(samples: Samples, name: []const u8) void {
        std.debug.print(
            "  {s}: p50={d:.3} ms p95={d:.3} ms ({d} runs)\n",
            .{
                name,
                ms(samples.percentile(50, 100)),
                ms(samples.percentile(95, 100)),
                samples.len,
            },
        );
    }
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    var options = try options_parse(gpa, init);
    defer options.deinit(gpa);
    if (options.paths.items.len == 0) return error.Usage;

    for (options.paths.items) |path| {
        try bench_file(gpa, io, path, options.iterations);
    }
}

fn options_parse(gpa: std.mem.Allocator, init: std.process.Init) !Options {
    var options = Options{};
    errdefer options.deinit(gpa);
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--iterations")) {
            options.iterations = try std.fmt.parseInt(
                u32,
                args.next() orelse return error.Usage,
                10,
            );
            if (options.iterations == 0 or options.iterations > iterations_max) {
                return error.Usage;
            }
        } else {
            try options.paths.append(gpa, arg);
        }
    }
    return options;
}

fn bench_file(
    gpa: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    iterations: u32,
) !void {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, file_bytes_max);
    defer gpa.free(bytes);
    var metadata_samples = Samples{};
    var decode_samples = Samples{};

    var iteration: u32 = 0;
    while (iteration < iterations) : (iteration += 1) {
        const metadata_started = std.Io.Clock.now(.awake, io);
        _ = try emu.raw.decode_metadata(bytes);
        const metadata_finished = std.Io.Clock.now(.awake, io);
        metadata_samples.append(elapsed_ns(metadata_started, metadata_finished));

        const decode_started = std.Io.Clock.now(.awake, io);
        var decoded = try emu.raw.decode_raw(gpa, bytes);
        const decode_finished = std.Io.Clock.now(.awake, io);
        decode_samples.append(elapsed_ns(decode_started, decode_finished));
        decoded.deinit(gpa);
    }

    var raw = try emu.raw.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    const recipe = emu.pipeline.Recipe{
        .engine_version = 2,
        .ops = &emu.recipe.default_ops,
    };
    var preview_samples = Samples{};
    var full_samples = Samples{};
    try render_warm(gpa, &raw, recipe, 1024);
    try render_warm(gpa, &raw, recipe, 0);
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        preview_samples.append(try render_timed(gpa, io, &raw, recipe, 1024));
        full_samples.append(try render_timed(gpa, io, &raw, recipe, 0));
    }

    const dimensions = emu.geometry.Transform.init(raw.metadata).output_dimensions();
    std.debug.print(
        "raw-bench: {s} {d}x{d} -> {d}x{d}\n",
        .{ path, raw.metadata.width, raw.metadata.height, dimensions.width, dimensions.height },
    );
    metadata_samples.report("metadata parse");
    decode_samples.report("sensor decode");
    preview_samples.report("warm edge-1024 v2 render");
    full_samples.report("warm full v2 render");
}

fn render_warm(
    gpa: std.mem.Allocator,
    raw: *const emu.dng.DecodedRaw,
    recipe: emu.pipeline.Recipe,
    edge_px_max_out: u32,
) !void {
    var rendered = try emu.pipeline.render_decoded(
        gpa,
        raw,
        recipe,
        .{ .edge_px_max_out = edge_px_max_out },
    );
    rendered.deinit(gpa);
}

fn render_timed(
    gpa: std.mem.Allocator,
    io: std.Io,
    raw: *const emu.dng.DecodedRaw,
    recipe: emu.pipeline.Recipe,
    edge_px_max_out: u32,
) !u64 {
    const started = std.Io.Clock.now(.awake, io);
    var rendered = try emu.pipeline.render_decoded(
        gpa,
        raw,
        recipe,
        .{ .edge_px_max_out = edge_px_max_out },
    );
    const finished = std.Io.Clock.now(.awake, io);
    rendered.deinit(gpa);
    return elapsed_ns(started, finished);
}

fn elapsed_ns(started: std.Io.Timestamp, finished: std.Io.Timestamp) u64 {
    return @intCast(started.durationTo(finished).nanoseconds);
}

fn ms(nanoseconds: u64) f64 {
    return @as(f64, @floatFromInt(nanoseconds)) / std.time.ns_per_ms;
}
