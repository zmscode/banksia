//! ReleaseFast real-camera timing harness.
//!
//! Measures metadata parse, sensor decode, warm thumbnail/preview/full renders,
//! CPU late-release fallback, and the retained linear base independently. Files
//! are read before timing.

const std = @import("std");
const emu = @import("emu");

const file_bytes_max = std.Io.Limit.limited(512 * 1024 * 1024);
const iterations_max: u32 = 101;

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
        // Nearest-rank percentile: ceil(P * N) - 1. The old interpolation
        // formula selected the second-highest value for p95 with nine samples,
        // understating the tail that this harness exists to expose.
        const rank = (@as(u64, samples.len) * numerator + denominator - 1) / denominator;
        return sorted[@intCast(rank - 1)];
    }

    fn report(samples: Samples, name: []const u8) void {
        std.debug.print(
            "  {s}: p50={d:.3} ms p95={d:.3} ms p99={d:.3} ms ({d} runs)\n",
            .{
                name,
                ms(samples.percentile(50, 100)),
                ms(samples.percentile(95, 100)),
                ms(samples.percentile(99, 100)),
                samples.len,
            },
        );
    }
};

const TimedRender = struct {
    total_ns: u64,
    output_packing_ns: u64,
    loupe_backing_ns: u64,
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
    const benchmark_started = std.Io.Clock.now(.awake, io);
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
    const late_ops = [_]emu.pipeline.Op{
        .{ .black_point = .{} },
        .{ .white_balance = .{} },
        .{ .demosaic = .{} },
        .{ .exposure = .{ .ev = 0.75 } },
        .{ .tone_curve = .{ .contrast = 0.35 } },
        .{ .srgb_encode = .{} },
    };
    const late_recipe = emu.pipeline.Recipe{
        .engine_version = 2,
        .ops = &late_ops,
    };
    var thumbnail_samples = Samples{};
    var uncached_thumbnail_samples = Samples{};
    var preview_samples = Samples{};
    var edge_1440_samples = Samples{};
    var linear_preview_samples = Samples{};
    var late_release_samples = Samples{};
    var late_release_packing_samples = Samples{};
    var late_release_loupe_samples = Samples{};
    var full_samples = Samples{};
    try render_warm(gpa, &raw, recipe, 220);
    try render_warm(gpa, &raw, recipe, 1024);
    try render_warm(gpa, &raw, recipe, 1440);
    try render_linear_warm(gpa, &raw, recipe, 1440);
    try render_warm(gpa, &raw, late_recipe, 1440);
    try render_warm(gpa, &raw, recipe, 0);
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        thumbnail_samples.append((try render_timed(gpa, io, &raw, recipe, 220, false)).total_ns);
    }
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        uncached_thumbnail_samples.append(try uncached_thumbnail_timed(
            gpa,
            io,
            bytes,
            recipe,
        ));
    }
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        preview_samples.append((try render_timed(gpa, io, &raw, recipe, 1024, false)).total_ns);
    }
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        edge_1440_samples.append((try render_timed(gpa, io, &raw, recipe, 1440, false)).total_ns);
    }
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        linear_preview_samples.append(try render_linear_timed(
            gpa,
            io,
            &raw,
            recipe,
            1440,
        ));
    }
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        const late = try render_timed(gpa, io, &raw, late_recipe, 1440, true);
        late_release_samples.append(late.total_ns);
        late_release_packing_samples.append(late.output_packing_ns);
        late_release_loupe_samples.append(late.loupe_backing_ns);
    }
    iteration = 0;
    while (iteration < iterations) : (iteration += 1) {
        full_samples.append((try render_timed(gpa, io, &raw, recipe, 0, false)).total_ns);
    }

    const dimensions = emu.geometry.Transform.init(raw.metadata).output_dimensions();
    std.debug.print(
        "raw-bench: {s} {d}x{d} -> {d}x{d}\n",
        .{ path, raw.metadata.width, raw.metadata.height, dimensions.width, dimensions.height },
    );
    metadata_samples.report("metadata parse");
    decode_samples.report("sensor decode");
    thumbnail_samples.report("warm edge-220 thumbnail render");
    uncached_thumbnail_samples.report("uncached edge-220 thumbnail decode and render");
    preview_samples.report("warm edge-1024 v2 render");
    edge_1440_samples.report("warm edge-1440 v2 render");
    linear_preview_samples.report("warm edge-1440 linear base");
    late_release_samples.report("warm edge-1440 CPU late-release render");
    late_release_packing_samples.report("late-release sRGB output packing");
    late_release_loupe_samples.report("late-release loupe backing crop and RGB read");
    full_samples.report("warm full v2 render");
    std.debug.print(
        "  linear admission estimate (edge-1440): {d:.2} MiB\n" ++ "  benchmark duration: {d:.3} s\n",
        .{
            @as(f64, @floatFromInt(
                emu.pipeline.render_linear_memory_bytes_max(&raw, 1440),
            )) / (1024 * 1024),
            ms(elapsed_ns(benchmark_started, std.Io.Clock.now(.awake, io))) / 1_000,
        },
    );
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
    measure_loupe: bool,
) !TimedRender {
    const started = std.Io.Clock.now(.awake, io);
    var rendered = try emu.pipeline.render_decoded(
        gpa,
        raw,
        recipe,
        .{
            .edge_px_max_out = edge_px_max_out,
            .measure_output_packing = true,
        },
    );
    const finished = std.Io.Clock.now(.awake, io);
    const result = TimedRender{
        .total_ns = elapsed_ns(started, finished),
        .output_packing_ns = rendered.output_packing_ns,
        .loupe_backing_ns = if (measure_loupe) loupe_backing_timed(io, &rendered) else 0,
    };
    rendered.deinit(gpa);
    return result;
}

fn uncached_thumbnail_timed(
    gpa: std.mem.Allocator,
    io: std.Io,
    bytes: []const u8,
    recipe: emu.pipeline.Recipe,
) !u64 {
    const started = std.Io.Clock.now(.awake, io);
    var decoded = try emu.raw.decode_raw(gpa, bytes);
    defer decoded.deinit(gpa);
    var rendered = try emu.pipeline.render_decoded(
        gpa,
        &decoded,
        recipe,
        .{ .edge_px_max_out = 220 },
    );
    rendered.deinit(gpa);
    return elapsed_ns(started, std.Io.Clock.now(.awake, io));
}

fn loupe_backing_timed(io: std.Io, rendered: *const emu.pipeline.Rendered) u64 {
    const started = std.Io.Clock.now(.awake, io);
    const crop_width = @min(@as(u32, 18), rendered.width);
    const crop_height = @min(@as(u32, 18), rendered.height);
    const origin_x = (rendered.width - crop_width) / 2;
    const origin_y = (rendered.height - crop_height) / 2;
    var checksum: u64 = 0;
    for (0..crop_height) |y| {
        for (0..crop_width) |x| {
            const offset = (@as(usize, origin_y + y) * rendered.width + origin_x + x) * 4;
            checksum +%= rendered.rgba[offset];
            checksum +%= rendered.rgba[offset + 1];
            checksum +%= rendered.rgba[offset + 2];
        }
    }
    std.mem.doNotOptimizeAway(checksum);
    return elapsed_ns(started, std.Io.Clock.now(.awake, io));
}

fn render_linear_warm(
    gpa: std.mem.Allocator,
    raw: *const emu.dng.DecodedRaw,
    recipe: emu.pipeline.Recipe,
    edge_px_max_out: u32,
) !void {
    var rendered = try emu.pipeline.render_linear_decoded(
        gpa,
        raw,
        recipe,
        .{ .edge_px_max_out = edge_px_max_out },
    );
    rendered.deinit(gpa);
}

fn render_linear_timed(
    gpa: std.mem.Allocator,
    io: std.Io,
    raw: *const emu.dng.DecodedRaw,
    recipe: emu.pipeline.Recipe,
    edge_px_max_out: u32,
) !u64 {
    const started = std.Io.Clock.now(.awake, io);
    var rendered = try emu.pipeline.render_linear_decoded(
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
