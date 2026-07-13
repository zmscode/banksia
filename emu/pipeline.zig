//! The develop pipeline: linear scene-referred f32, end to end.
//!
//! `render(gpa, sensor, recipe) → RGBA8` is a pure function — no clock, no
//! RNG, no I/O, no global state. Identical inputs produce bit-identical
//! output; the determinism test at the bottom holds that line.
//!
//! Engine version 1 op stack (validated, in order):
//!
//!   black_point → [white_balance] → demosaic → [exposure|tone_curve]* → srgb_encode
//!
//! Op semantics are frozen per engine version: improving a curve or a
//! demosaic goes in a *new* version, never in place (plan.md, Phase 3).
//!
//! Kernels are the data plane: standalone functions over primitive
//! arguments, `@Vector` bodies with scalar tails, O(1) asserts outside the
//! loops. Everything else is control plane and asserts unconditionally.

const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const calibration = @import("calibration.zig");
const color = @import("color.zig");
const dng = @import("dng.zig");
const film_curve = @import("film_curve.zig");
const geometry = @import("geometry.zig");
const icc_profile = @import("icc_profile.zig");
const image = @import("image.zig");

/// Per-element asserts inside pixel loops run only when this is set: slow
/// assertions reduce fuzz coverage, so they must earn their keep.
const verify = builtin.mode == .Debug;

pub const engine_version_current: u32 = 1;
pub const engine_version_latest: u32 = 5;
/// Recovered Capture One 16.7.3 clipping-recovery safety point, expressed as a
/// fraction of the per-channel sensor clip after CFA-site normalization.
pub const highlight_recovery_start_bootstrap: f32 = 0.9659363;

/// An edit stack longer than this is not a recipe, it is a bug.
pub const ops_max: u32 = 64;

pub const Op = union(enum) {
    black_point: BlackPoint,
    white_balance: WhiteBalance,
    demosaic: Demosaic,
    exposure: Exposure,
    tone_curve: ToneCurve,
    srgb_encode: SrgbEncode,
};

pub const BlackPoint = struct {};

pub const WhiteBalance = struct {
    /// Derive gains from the sensor's as-shot neutral; explicit gains below
    /// are ignored when set.
    as_shot: bool = true,
    gain_r: f32 = 1,
    gain_g: f32 = 1,
    gain_b: f32 = 1,
};

pub const Demosaic = struct {};

pub const Exposure = struct {
    /// Stops; gain is exp2(ev).
    ev: f32 = 0,
};

pub const ToneCurve = struct {
    /// 0 is identity, 1 is a full smoothstep S-curve. Engine version 1
    /// does not define negative contrast.
    contrast: f32 = 0,
};

pub const SrgbEncode = struct {};

pub const Recipe = struct {
    engine_version: u32 = engine_version_current,
    camera_profile: CameraProfileSelection = .technical_matrix,
    film_curve: film_curve.Selection = .linear,
    ops: []const Op,
};

pub const CameraProfileSelection = enum {
    technical_matrix,
    resolved_nonlinear,
};

pub const Cancellation = struct {
    context: ?*anyopaque = null,
    callback: ?*const fn (?*anyopaque) callconv(.c) i32 = null,

    pub const never: Cancellation = .{};

    pub fn requested(self: Cancellation) bool {
        const callback = self.callback orelse return false;
        return callback(self.context) != 0;
    }
};

pub const RenderOptions = struct {
    /// Longest edge of the output in pixels; 0 renders at sensor resolution.
    /// Smaller outputs render at full resolution first and then box
    /// downsample: correct and deterministic first. The subsampled-demosaic
    /// fast path is a Phase 6 optimization tested against this reference.
    edge_px_max_out: u32 = 0,
    memory_budget_bytes: u64 = 0,
    cancellation: Cancellation = .never,
    /// Benchmark-only measurement of the final planar-to-RGBA8 packing pass.
    /// Disabled for normal renders so the stable renderer pays no timing cost.
    measure_output_packing: bool = false,
    reconstruction: ReconstructionDefaults = .legacy,
    camera_profile: CameraProfile = .technical_matrix,
    film_curve: film_curve.Rendering = .linear,
};

/// The nonlinear profile replaces, rather than mutates, the independently
/// selectable DNG/LibRaw technical matrix conversion.
pub const CameraProfile = union(enum) {
    technical_matrix,
    nonlinear: icc_profile.Profile,
};

pub const ReconstructionDefaults = struct {
    enabled: bool = false,
    adaptive_green_enabled: bool = false,
    hot_pixel_cleanup_amount: f32 = 0,
    anti_color_aliasing_strength: f32 = 1,
    highlight_recovery_start: f32 = 0.8,

    pub const legacy = ReconstructionDefaults{};

    pub fn assertValid(defaults: ReconstructionDefaults) void {
        assert(std.math.isFinite(defaults.hot_pixel_cleanup_amount));
        assert(defaults.hot_pixel_cleanup_amount >= 0);
        assert(defaults.hot_pixel_cleanup_amount <= 100);
        assert(std.math.isFinite(defaults.anti_color_aliasing_strength));
        assert(defaults.anti_color_aliasing_strength >= 0);
        assert(defaults.anti_color_aliasing_strength <= 1);
        assert(std.math.isFinite(defaults.highlight_recovery_start));
        assert(defaults.highlight_recovery_start >= 0);
        assert(defaults.highlight_recovery_start < 1);
        if (!defaults.enabled) assert(!defaults.adaptive_green_enabled);
    }
};

pub const Rendered = struct {
    width: u32,
    height: u32,
    /// Row-major RGBA8, `width * height * 4` bytes.
    rgba: []u8,
    output_packing_ns: u64 = 0,

    pub fn deinit(self: *Rendered, gpa: std.mem.Allocator) void {
        assert(self.rgba.len == @as(usize, self.width) * self.height * 4);
        gpa.free(self.rgba);
        self.* = undefined;
    }
};

/// Retained preview boundary for accelerated late develop. Pixels are
/// row-major RGBA32F in linear Rec.2020 after sensor-domain operations,
/// demosaic, camera-to-working conversion, crop/orientation, and optional
/// preview scaling. Exposure, tone, output conversion, and transfer encoding
/// have not run. Alpha is exactly 1.
pub const LinearRendered = struct {
    width: u32,
    height: u32,
    rgba: []f32,

    pub fn deinit(self: *LinearRendered, gpa: std.mem.Allocator) void {
        assert(self.rgba.len == @as(usize, self.width) * self.height * 4);
        gpa.free(self.rgba);
        self.* = undefined;
    }
};

pub const RenderError = error{
    InvalidRecipe,
    UnsupportedEngineVersion,
    UnsupportedSensor,
    InvalidColorMetadata,
    OutOfMemory,
    Cancelled,
};

pub fn render(
    gpa: std.mem.Allocator,
    sensor: *const dng.SensorData,
    recipe: Recipe,
    options: RenderOptions,
) RenderError!Rendered {
    if (recipe.engine_version != 1) return error.UnsupportedEngineVersion;
    return render_internal(gpa, sensor, recipe, options, null, null);
}

/// Rich dispatch surface. Version 1 deliberately ignores metadata and stays
/// byte-frozen; version 2 applies the declared crop and orientation.
pub fn render_decoded(
    gpa: std.mem.Allocator,
    raw: *const dng.DecodedRaw,
    recipe: Recipe,
    options: RenderOptions,
) RenderError!Rendered {
    return switch (recipe.engine_version) {
        1 => if (raw.linear == null)
            render(gpa, &raw.sensor, recipe, options)
        else
            error.UnsupportedSensor,
        2, 3, 4, 5 => {
            const dimensions = geometry.Transform.init(raw.metadata).output_dimensions();
            const longest = @max(dimensions.width, dimensions.height);
            const ratio = if (options.edge_px_max_out == 0)
                0
            else
                longest / options.edge_px_max_out;
            const factor = ratio & ~@as(u32, 1);
            if (factor >= 2) {
                var preview = try preview_raw_make(gpa, raw, factor);
                defer preview.deinit(gpa);
                return render_decoded_v2(gpa, &preview, recipe, options);
            }
            return render_decoded_v2(gpa, raw, recipe, options);
        },
        else => error.UnsupportedEngineVersion,
    };
}

/// Produce the immutable linear-working preview consumed by the Metal late
/// develop proof. Version 1 remains byte-frozen and has no split-stage API.
pub fn render_linear_decoded(
    gpa: std.mem.Allocator,
    raw: *const dng.DecodedRaw,
    recipe: Recipe,
    options: RenderOptions,
) RenderError!LinearRendered {
    if (recipe.engine_version < 2 or recipe.engine_version > engine_version_latest) {
        return error.UnsupportedEngineVersion;
    }
    options.reconstruction.assertValid();
    options.film_curve.assertValid();
    if (recipe.engine_version == 2) assert(!options.reconstruction.enabled);
    try cancellation_check(options.cancellation);
    const memory_bytes_max = render_linear_memory_bytes_max_internal(
        raw,
        options.edge_px_max_out,
        options.reconstruction.enabled,
    );
    if (options.memory_budget_bytes > 0 and
        memory_bytes_max > options.memory_budget_bytes)
    {
        return error.OutOfMemory;
    }
    const dimensions = geometry.Transform.init(raw.metadata).output_dimensions();
    const longest = @max(dimensions.width, dimensions.height);
    const factor = preview_factor(longest, options.edge_px_max_out);
    if (factor >= 2) {
        var preview = try preview_raw_make(gpa, raw, factor);
        defer preview.deinit(gpa);
        try cancellation_check(options.cancellation);
        return render_linear_decoded_v2(gpa, &preview, recipe, options);
    }
    return render_linear_decoded_v2(gpa, raw, recipe, options);
}

pub fn render_linear_memory_bytes_max(raw: *const dng.DecodedRaw, edge_px_max_out: u32) u64 {
    return render_linear_memory_bytes_max_internal(raw, edge_px_max_out, false);
}

fn render_linear_memory_bytes_max_internal(
    raw: *const dng.DecodedRaw,
    edge_px_max_out: u32,
    calibrated_reconstruction: bool,
) u64 {
    const dimensions = geometry.Transform.init(raw.metadata).output_dimensions();
    const longest = @max(dimensions.width, dimensions.height);
    const factor = @max(1, preview_factor(longest, edge_px_max_out));
    const work_width = (raw.sensor.width + factor - 1) / factor;
    const work_height = (raw.sensor.height + factor - 1) / factor;
    const oriented_width = (dimensions.width + factor - 1) / factor;
    const oriented_height = (dimensions.height + factor - 1) / factor;
    const width_out, const height_out = dims_out(
        oriented_width,
        oriented_height,
        edge_px_max_out,
    );

    const raw_pixels = @as(u64, raw.sensor.width) * raw.sensor.height;
    const work_pixels = @as(u64, work_width) * work_height;
    const output_pixels = @as(u64, width_out) * height_out;
    const input_channels: u64 = if (raw.linear == null) 1 else 3;
    const cfa_bytes = (raw_pixels + work_pixels) * @sizeOf(u16) * input_channels;
    // Legacy/profile peak: mosaic + RGB planes + three chroma/profile scratch
    // planes. Calibrated v3/v4's larger peak is mosaic + RGB planes + four RCD
    // scratch planes. Cleanup, RCD, chroma, and profile scratch are scoped to
    // their kernels, so admission models concurrent memory rather than summing
    // old lifetimes.
    const early_channels: u64 = if (calibrated_reconstruction) 8 else 7;
    const early_stage_bytes = work_pixels * @sizeOf(f32) * early_channels;
    const output_stage_bytes = output_pixels * 72;
    return cfa_bytes + early_stage_bytes + output_stage_bytes;
}

/// Choose an even CFA-preserving reduction level. Interactive previews may use
/// the next coarser level when it stays within 5% of the requested maximum edge;
/// small reference renders retain strict-CPU-compatible dimensions so the CPU
/// and GPU conformance oracle compares the same pixels.
fn preview_factor(longest: u32, edge_px_max_out: u32) u32 {
    if (edge_px_max_out == 0 or edge_px_max_out >= longest) return 0;
    const ratio = longest / edge_px_max_out;
    const floor_even = ratio & ~@as(u32, 1);
    if (edge_px_max_out < 1024 or floor_even < 2 or ratio & 1 == 0) return floor_even;
    const ceil_even = floor_even + 2;
    const reduced_longest = (longest + ceil_even - 1) / ceil_even;
    if (@as(u64, reduced_longest) * 20 >= @as(u64, edge_px_max_out) * 19) {
        return ceil_even;
    }
    return floor_even;
}

fn cancellation_check(cancellation: Cancellation) RenderError!void {
    if (cancellation.requested()) return error.Cancelled;
}

fn render_decoded_v2(
    gpa: std.mem.Allocator,
    raw: *const dng.DecodedRaw,
    recipe: Recipe,
    options: RenderOptions,
) RenderError!Rendered {
    const color_transform = color.Transform.init(raw.metadata) catch {
        return error.InvalidColorMetadata;
    };
    if (raw.linear) |*linear| {
        return render_linear_source_display(
            gpa,
            linear,
            raw.metadata,
            recipe,
            options,
            color_transform,
        );
    }
    return render_internal(
        gpa,
        &raw.sensor,
        recipe,
        options,
        geometry.Transform.init(raw.metadata),
        color_transform,
    );
}

fn render_linear_decoded_v2(
    gpa: std.mem.Allocator,
    raw: *const dng.DecodedRaw,
    recipe: Recipe,
    options: RenderOptions,
) RenderError!LinearRendered {
    const color_transform = color.Transform.init(raw.metadata) catch {
        return error.InvalidColorMetadata;
    };
    if (raw.linear) |*linear| {
        return render_linear_source_working(
            gpa,
            linear,
            raw.metadata,
            recipe,
            options,
            color_transform,
        );
    }
    return render_linear_internal(
        gpa,
        &raw.sensor,
        recipe,
        options,
        geometry.Transform.init(raw.metadata),
        color_transform,
    );
}

fn preview_raw_make(
    gpa: std.mem.Allocator,
    source: *const dng.DecodedRaw,
    factor: u32,
) RenderError!dng.DecodedRaw {
    assert(factor >= 2);
    assert(factor % 2 == 0);
    const width = (source.sensor.width + factor - 1) / factor;
    const height = (source.sensor.height + factor - 1) / factor;
    const bayer_count = if (source.linear == null) @as(usize, width) * height else 0;
    const bayer = try gpa.alloc(u16, bayer_count);
    errdefer gpa.free(bayer);
    var linear: ?dng.LinearData = null;
    if (source.linear) |linear_source| {
        const rgb = try gpa.alloc(u16, @as(usize, width) * height * 3);
        errdefer gpa.free(rgb);
        preview_linear_reduce(
            rgb,
            width,
            height,
            linear_source.rgb,
            linear_source.width,
            linear_source.height,
            factor,
        );
        linear = .{
            .width = width,
            .height = height,
            .black_level = linear_source.black_level,
            .white_level = linear_source.white_level,
            .baseline_exposure_ev = linear_source.baseline_exposure_ev,
            .wb_neutral = linear_source.wb_neutral,
            .rgb = rgb,
        };
    } else {
        preview_bayer_reduce(
            bayer,
            width,
            height,
            source.sensor.bayer,
            source.sensor.width,
            source.sensor.height,
            factor,
        );
    }

    var metadata = source.metadata;
    metadata.width = width;
    metadata.height = height;
    metadata.active_area = rect_scale(source.metadata.active_area, factor);
    const crop_sensor = dng.Rect{
        .x = source.metadata.active_area.x + source.metadata.default_crop.x,
        .y = source.metadata.active_area.y + source.metadata.default_crop.y,
        .width = source.metadata.default_crop.width,
        .height = source.metadata.default_crop.height,
    };
    const crop = rect_scale(crop_sensor, factor);
    metadata.default_crop = .{
        .x = crop.x - metadata.active_area.x,
        .y = crop.y - metadata.active_area.y,
        .width = crop.width,
        .height = crop.height,
    };
    return .{
        .metadata = metadata,
        .linear = linear,
        .sensor = .{
            .width = width,
            .height = height,
            .cfa = source.sensor.cfa,
            .black_level = source.sensor.black_level,
            .white_level = source.sensor.white_level,
            .black_level_site = source.sensor.black_level_site,
            .white_level_site = source.sensor.white_level_site,
            .wb_neutral = source.sensor.wb_neutral,
            .bayer = bayer,
        },
    };
}

fn preview_linear_reduce(
    target: []u16,
    width_out: u32,
    height_out: u32,
    source: []const u16,
    width: u32,
    height: u32,
    factor: u32,
) void {
    assert(target.len == @as(usize, width_out) * height_out * 3);
    assert(source.len == @as(usize, width) * height * 3);
    assert(factor >= 2);
    var y: u32 = 0;
    while (y < height_out) : (y += 1) {
        var x: u32 = 0;
        while (x < width_out) : (x += 1) {
            const x_end = @min(width, (x + 1) * factor);
            const y_end = @min(height, (y + 1) * factor);
            var sums: [3]u64 = @splat(0);
            var count: u32 = 0;
            var source_y = y * factor;
            while (source_y < y_end) : (source_y += 1) {
                var source_x = x * factor;
                while (source_x < x_end) : (source_x += 1) {
                    const source_index = (@as(usize, source_y) * width + source_x) * 3;
                    inline for (0..3) |channel| sums[channel] += source[source_index + channel];
                    count += 1;
                }
            }
            assert(count > 0);
            const target_index = (@as(usize, y) * width_out + x) * 3;
            inline for (0..3) |channel| {
                target[target_index + channel] = @intCast(sums[channel] / count);
            }
        }
    }
}

fn rect_scale(rect: dng.Rect, factor: u32) dng.Rect {
    assert(rect.width > 0);
    assert(rect.height > 0);
    const right = (@as(u64, rect.x) + rect.width + factor - 1) / factor;
    const bottom = (@as(u64, rect.y) + rect.height + factor - 1) / factor;
    const x = rect.x / factor;
    const y = rect.y / factor;
    return .{
        .x = x,
        .y = y,
        .width = @intCast(right - x),
        .height = @intCast(bottom - y),
    };
}

fn preview_bayer_reduce(
    target: []u16,
    width_out: u32,
    height_out: u32,
    source: []const u16,
    width: u32,
    height: u32,
    factor: u32,
) void {
    assert(target.len == @as(usize, width_out) * height_out);
    assert(source.len == @as(usize, width) * height);
    assert(factor >= 2);
    assert(factor % 2 == 0);
    var y: u32 = 0;
    while (y < height_out) : (y += 1) {
        var x: u32 = 0;
        while (x < width_out) : (x += 1) {
            const x_end = @min(width, (x + 1) * factor);
            const y_end = @min(height, (y + 1) * factor);
            var source_y = preview_site_first(y * factor, y & 1, height);
            var sum: u64 = 0;
            var count: u32 = 0;
            while (source_y < y_end) : (source_y += 2) {
                var source_x = preview_site_first(x * factor, x & 1, width);
                while (source_x < x_end) : (source_x += 2) {
                    sum += source[@as(usize, source_y) * width + source_x];
                    count += 1;
                }
            }
            if (count == 0) {
                const source_x = preview_site_last(x & 1, width);
                const fallback_y = preview_site_last(y & 1, height);
                sum = source[@as(usize, fallback_y) * width + source_x];
                count = 1;
            }
            target[@as(usize, y) * width_out + x] = @intCast(sum / count);
        }
    }
}

fn preview_site_first(start: u32, parity: u32, limit: u32) u32 {
    assert(parity <= 1);
    assert(limit > 0);
    const candidate = start + ((start ^ parity) & 1);
    return if (candidate < limit) candidate else limit;
}

fn preview_site_last(parity: u32, limit: u32) u32 {
    assert(parity <= 1);
    assert(limit > 0);
    const last = limit - 1;
    if (last & 1 == parity or last == 0) return last;
    return last - 1;
}

fn render_linear_source_display(
    gpa: std.mem.Allocator,
    source: *const dng.LinearData,
    metadata: dng.Metadata,
    recipe: Recipe,
    options: RenderOptions,
    color_transform: color.Transform,
) RenderError!Rendered {
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var planes = try linear_source_planes(
        arena,
        source,
        recipe,
        options.cancellation,
        color_transform,
        true,
    );
    color.working_to_linear_srgb(&planes);
    const transformed = try planes_transform(arena, &planes, geometry.Transform.init(metadata));
    const width_out, const height_out = dims_out(
        transformed.width,
        transformed.height,
        options.edge_px_max_out,
    );
    const output = if (width_out == transformed.width and height_out == transformed.height)
        transformed
    else
        try planes_downsample(arena, &transformed, width_out, height_out);
    try cancellation_check(options.cancellation);
    const rgba = try gpa.alloc(u8, @as(usize, width_out) * height_out * 4);
    errdefer gpa.free(rgba);
    const packing_ns = pack_srgb_timed(
        rgba,
        output.r,
        output.g,
        output.b,
        options.measure_output_packing,
    );
    return .{
        .width = width_out,
        .height = height_out,
        .rgba = rgba,
        .output_packing_ns = packing_ns,
    };
}

fn render_linear_source_working(
    gpa: std.mem.Allocator,
    source: *const dng.LinearData,
    metadata: dng.Metadata,
    recipe: Recipe,
    options: RenderOptions,
    color_transform: color.Transform,
) RenderError!LinearRendered {
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const planes = try linear_source_planes(
        arena,
        source,
        recipe,
        options.cancellation,
        color_transform,
        false,
    );
    const transformed = try planes_transform(arena, &planes, geometry.Transform.init(metadata));
    const width_out, const height_out = dims_out(
        transformed.width,
        transformed.height,
        options.edge_px_max_out,
    );
    const output = if (width_out == transformed.width and height_out == transformed.height)
        transformed
    else
        try planes_downsample(arena, &transformed, width_out, height_out);
    try cancellation_check(options.cancellation);
    const rgba = try gpa.alloc(f32, @as(usize, width_out) * height_out * 4);
    errdefer gpa.free(rgba);
    kernel_linear_pack(rgba, output.r, output.g, output.b);
    return .{ .width = width_out, .height = height_out, .rgba = rgba };
}

fn linear_source_planes(
    arena: std.mem.Allocator,
    source: *const dng.LinearData,
    recipe: Recipe,
    cancellation: Cancellation,
    color_transform: color.Transform,
    apply_late: bool,
) RenderError!image.Planes {
    assert(source.rgb.len == @as(usize, source.width) * source.height * 3);
    assert(source.white_level > source.black_level);
    var ops: std.MultiArrayList(Op) = .empty;
    defer ops.deinit(arena);
    try ops.ensureTotalCapacity(arena, recipe.ops.len);
    for (recipe.ops) |op| ops.appendAssumeCapacity(op);
    try stack_validate(ops.items(.tags));

    var planes = try image.Planes.init(arena, source.width, source.height);
    const scale = std.math.exp2(source.baseline_exposure_ev) /
        (source.white_level - source.black_level);
    for (planes.r, planes.g, planes.b, 0..) |*red, *green, *blue, index| {
        const sample = index * 3;
        red.* = @max(0, (@as(f32, @floatFromInt(source.rgb[sample])) -
            source.black_level) * scale);
        green.* = @max(0, (@as(f32, @floatFromInt(source.rgb[sample + 1])) -
            source.black_level) * scale);
        blue.* = @max(0, (@as(f32, @floatFromInt(source.rgb[sample + 2])) -
            source.black_level) * scale);
    }

    var transformed = false;
    for (0..ops.len) |index| {
        try cancellation_check(cancellation);
        const op = ops.get(index);
        switch (op) {
            .black_point, .srgb_encode => {},
            .white_balance => {
                if (!op.white_balance.as_shot or color_transform.apply_as_shot_white_balance) {
                    const gains = wb_gains(op.white_balance, source.wb_neutral);
                    kernel_gain(planes.r, gains[0]);
                    kernel_gain(planes.g, gains[1]);
                    kernel_gain(planes.b, gains[2]);
                }
            },
            .demosaic => {
                assert(!transformed);
                color_transform.camera_to_working(&planes);
                transformed = true;
            },
            .exposure => if (apply_late) {
                const gain = std.math.exp2(op.exposure.ev);
                kernel_gain(planes.r, gain);
                kernel_gain(planes.g, gain);
                kernel_gain(planes.b, gain);
            },
            .tone_curve => if (apply_late and op.tone_curve.contrast != 0) {
                kernel_tone_curve(planes.r, op.tone_curve.contrast);
                kernel_tone_curve(planes.g, op.tone_curve.contrast);
                kernel_tone_curve(planes.b, op.tone_curve.contrast);
            },
        }
    }
    assert(transformed);
    return planes;
}

fn render_internal(
    gpa: std.mem.Allocator,
    sensor: *const dng.SensorData,
    recipe: Recipe,
    options: RenderOptions,
    transform: ?geometry.Transform,
    color_transform: ?color.Transform,
) RenderError!Rendered {
    assert(sensor.bayer.len == @as(usize, sensor.width) * sensor.height);
    assert(sensor.white_level > sensor.black_level);
    options.reconstruction.assertValid();
    if (recipe.engine_version < 3) assert(!options.reconstruction.enabled);
    if (recipe.engine_version < 3) {
        assert(std.meta.activeTag(options.camera_profile) == .technical_matrix);
    }
    if (std.meta.activeTag(options.camera_profile) == .nonlinear) {
        assert(recipe.engine_version >= 4);
        assert(recipe.camera_profile == .resolved_nonlinear);
    }
    assertFilmCurveSelection(recipe, options.film_curve);

    // The op stack is struct-of-arrays: validation walks the tag column
    // without touching a single payload.
    var ops: std.MultiArrayList(Op) = .empty;
    defer ops.deinit(gpa);
    try ops.ensureTotalCapacity(gpa, recipe.ops.len);
    for (recipe.ops) |op| ops.appendAssumeCapacity(op);
    try stack_validate(ops.items(.tags));

    // Plan: every intermediate buffer comes from one arena and dies with
    // it; the returned RGBA8 is the only allocation that outlives the call.
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const count = @as(usize, sensor.width) * sensor.height;
    const mosaic = try arena.alloc(f32, count);
    var planes = try image.Planes.init(arena, sensor.width, sensor.height);
    var applied_wb_gains: ?[3]f32 = null;

    for (0..ops.len) |i| {
        try op_apply(
            gpa,
            ops.get(i),
            recipe.engine_version,
            sensor,
            mosaic,
            &planes,
            color_transform,
            &applied_wb_gains,
            options.reconstruction,
            options.camera_profile,
            options.film_curve,
        );
    }
    if (color_transform != null) color.working_to_linear_srgb(&planes);

    const output_planes = if (transform) |value|
        try planes_transform(arena, &planes, value)
    else
        planes;
    const width_out, const height_out = dims_out(
        output_planes.width,
        output_planes.height,
        options.edge_px_max_out,
    );
    const count_out = @as(usize, width_out) * height_out;
    const rgba = try gpa.alloc(u8, count_out * 4);
    errdefer gpa.free(rgba);

    const packing_ns = if (width_out == output_planes.width and
        height_out == output_planes.height)
    blk: {
        break :blk pack_srgb_timed(
            rgba,
            output_planes.r,
            output_planes.g,
            output_planes.b,
            options.measure_output_packing,
        );
    } else blk: {
        const small = try planes_downsample(arena, &output_planes, width_out, height_out);
        break :blk pack_srgb_timed(
            rgba,
            small.r,
            small.g,
            small.b,
            options.measure_output_packing,
        );
    };

    assert(rgba.len == count_out * 4);
    return .{
        .width = width_out,
        .height = height_out,
        .rgba = rgba,
        .output_packing_ns = packing_ns,
    };
}

fn render_linear_internal(
    gpa: std.mem.Allocator,
    sensor: *const dng.SensorData,
    recipe: Recipe,
    options: RenderOptions,
    transform: geometry.Transform,
    color_transform: color.Transform,
) RenderError!LinearRendered {
    assert(sensor.bayer.len == @as(usize, sensor.width) * sensor.height);
    assert(sensor.white_level > sensor.black_level);
    options.reconstruction.assertValid();
    options.film_curve.assertValid();
    if (recipe.engine_version < 3) assert(!options.reconstruction.enabled);
    if (recipe.engine_version < 3) {
        assert(std.meta.activeTag(options.camera_profile) == .technical_matrix);
    }
    if (std.meta.activeTag(options.camera_profile) == .nonlinear) {
        assert(recipe.engine_version >= 4);
        assert(recipe.camera_profile == .resolved_nonlinear);
    }
    assertFilmCurveSelection(recipe, options.film_curve);

    var ops: std.MultiArrayList(Op) = .empty;
    defer ops.deinit(gpa);
    try ops.ensureTotalCapacity(gpa, recipe.ops.len);
    for (recipe.ops) |op| ops.appendAssumeCapacity(op);
    try stack_validate(ops.items(.tags));

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const count = @as(usize, sensor.width) * sensor.height;
    const mosaic = try arena.alloc(f32, count);
    var planes = try image.Planes.init(arena, sensor.width, sensor.height);
    var applied_wb_gains: ?[3]f32 = null;

    for (0..ops.len) |i| {
        try cancellation_check(options.cancellation);
        const op = ops.get(i);
        switch (op) {
            .exposure, .tone_curve, .srgb_encode => {},
            else => try op_apply(
                gpa,
                op,
                recipe.engine_version,
                sensor,
                mosaic,
                &planes,
                color_transform,
                &applied_wb_gains,
                options.reconstruction,
                options.camera_profile,
                options.film_curve,
            ),
        }
    }

    try cancellation_check(options.cancellation);
    const dimensions = transform.output_dimensions();
    const width_out, const height_out = dims_out(
        dimensions.width,
        dimensions.height,
        options.edge_px_max_out,
    );
    const output_planes = if (width_out == dimensions.width and
        height_out == dimensions.height)
        try planes_transform(arena, &planes, transform)
    else
        try planes_transform_downsample(arena, &planes, transform, width_out, height_out);

    try cancellation_check(options.cancellation);
    const count_out = @as(usize, width_out) * height_out;
    const rgba = try gpa.alloc(f32, count_out * 4);
    errdefer gpa.free(rgba);
    kernel_linear_pack(rgba, output_planes.r, output_planes.g, output_planes.b);
    try cancellation_check(options.cancellation);
    return .{ .width = width_out, .height = height_out, .rgba = rgba };
}

fn planes_transform(
    arena: std.mem.Allocator,
    source: *const image.Planes,
    transform: geometry.Transform,
) RenderError!image.Planes {
    const dimensions = transform.output_dimensions();
    const target = try image.Planes.init(arena, dimensions.width, dimensions.height);
    const pairs = [3][2][]f32{
        .{ target.r, source.r },
        .{ target.g, source.g },
        .{ target.b, source.b },
    };
    for (pairs) |pair| {
        for (pair[0], 0..) |*value, index| {
            const output = geometry.Point{
                .x = @intCast(index % dimensions.width),
                .y = @intCast(index / dimensions.width),
            };
            const sensor = transform.output_to_sensor(output);
            value.* = pair[1][@as(usize, sensor.y) * source.width + sensor.x];
        }
    }
    return target;
}

/// Apply crop/orientation and box reduction in one traversal. Preview renders
/// avoid allocating and filling a full-size oriented three-plane image only to
/// read it once during the following downsample.
fn planes_transform_downsample(
    arena: std.mem.Allocator,
    source: *const image.Planes,
    transform: geometry.Transform,
    width_out: u32,
    height_out: u32,
) RenderError!image.Planes {
    const dimensions = transform.output_dimensions();
    assert(width_out <= dimensions.width);
    assert(height_out <= dimensions.height);
    const target = try image.Planes.init(arena, width_out, height_out);

    var y_target: u32 = 0;
    while (y_target < height_out) : (y_target += 1) {
        const y0: u32 = @intCast(@as(u64, y_target) * dimensions.height / height_out);
        const y1: u32 = @intCast(
            (@as(u64, y_target) + 1) * dimensions.height / height_out,
        );
        var x_target: u32 = 0;
        while (x_target < width_out) : (x_target += 1) {
            const x0: u32 = @intCast(@as(u64, x_target) * dimensions.width / width_out);
            const x1: u32 = @intCast(
                (@as(u64, x_target) + 1) * dimensions.width / width_out,
            );
            var sums: [3]f32 = @splat(0);
            var y = y0;
            while (y < y1) : (y += 1) {
                var x = x0;
                while (x < x1) : (x += 1) {
                    const sensor = transform.output_to_sensor(.{ .x = x, .y = y });
                    const source_index = @as(usize, sensor.y) * source.width + sensor.x;
                    sums[0] += source.r[source_index];
                    sums[1] += source.g[source_index];
                    sums[2] += source.b[source_index];
                }
            }
            const sample_count = @as(f32, @floatFromInt((x1 - x0) * (y1 - y0)));
            const target_index = @as(usize, y_target) * width_out + x_target;
            target.r[target_index] = sums[0] / sample_count;
            target.g[target_index] = sums[1] / sample_count;
            target.b[target_index] = sums[2] / sample_count;
        }
    }
    return target;
}

/// Output dimensions for a bounded longest edge. A bound of 0, or one at or
/// above the sensor's longest edge, keeps full resolution; otherwise the
/// longest edge maps to the bound exactly and the short edge scales in
/// proportion, never below one pixel.
fn dims_out(width: u32, height: u32, edge_px_max_out: u32) struct { u32, u32 } {
    assert(width > 0);
    assert(height > 0);
    const longest = @max(width, height);
    if (edge_px_max_out == 0 or edge_px_max_out >= longest) return .{ width, height };

    const width_out: u32 = @intCast(@max(1, @as(u64, width) * edge_px_max_out / longest));
    const height_out: u32 = @intCast(@max(1, @as(u64, height) * edge_px_max_out / longest));
    assert(@max(width_out, height_out) == edge_px_max_out);
    assert(width_out < width or height_out < height);
    return .{ width_out, height_out };
}

/// Downsample all three planes into a fresh arena allocation; scratch for
/// the column sums is arena-owned too and dies with the render.
fn planes_downsample(
    arena: std.mem.Allocator,
    planes: *const image.Planes,
    width_out: u32,
    height_out: u32,
) RenderError!image.Planes {
    assert(width_out <= planes.width);
    assert(height_out <= planes.height);
    const small = try image.Planes.init(arena, width_out, height_out);
    const row_sum = try arena.alloc(f32, planes.width);
    const pairs = [3][2][]f32{
        .{ small.r, planes.r },
        .{ small.g, planes.g },
        .{ small.b, planes.b },
    };
    for (pairs) |pair| {
        kernel_box_downsample(
            pair[0],
            width_out,
            height_out,
            pair[1],
            planes.width,
            planes.height,
            row_sum,
        );
    }
    return small;
}

fn op_apply(
    scratch_gpa: std.mem.Allocator,
    op: Op,
    engine_version: u32,
    sensor: *const dng.SensorData,
    mosaic: []f32,
    planes: *image.Planes,
    color_transform: ?color.Transform,
    applied_wb_gains: *?[3]f32,
    reconstruction: ReconstructionDefaults,
    camera_profile: CameraProfile,
    curve_rendering: film_curve.Rendering,
) RenderError!void {
    switch (op) {
        .black_point => {
            if (sensor.black_level_site) |black| {
                const white = sensor.white_level_site orelse
                    @as([4]f32, @splat(sensor.white_level));
                kernel_black_scale_sites(
                    mosaic,
                    sensor.bayer,
                    sensor.width,
                    sensor.height,
                    black,
                    white,
                );
            } else {
                const scale = 1.0 / (sensor.white_level - sensor.black_level);
                kernel_black_scale(mosaic, sensor.bayer, sensor.black_level, scale);
            }
            if (reconstruction.enabled) {
                if (reconstruction.adaptive_green_enabled) {
                    kernel_green_equalize(mosaic, sensor.width, sensor.height, sensor.cfa);
                }
                if (engine_version >= 5) {
                    try kernel_isolated_pixel_cleanup_v2(
                        scratch_gpa,
                        mosaic,
                        sensor.width,
                        sensor.height,
                        reconstruction.hot_pixel_cleanup_amount,
                    );
                } else {
                    try kernel_hot_pixel_cleanup(
                        scratch_gpa,
                        mosaic,
                        sensor.width,
                        sensor.height,
                        reconstruction.hot_pixel_cleanup_amount,
                    );
                }
            }
        },
        .white_balance => {
            const wb = op.white_balance;
            if (color_transform == null or
                !wb.as_shot or
                color_transform.?.apply_as_shot_white_balance or
                std.meta.activeTag(camera_profile) == .nonlinear)
            {
                const gains = wb_gains(wb, sensor.wb_neutral);
                kernel_wb(mosaic, sensor.width, sensor.height, sensor.cfa, gains);
                applied_wb_gains.* = gains;
            }
        },
        .demosaic => {
            if (reconstruction.enabled) {
                var rcd_scratch = std.heap.ArenaAllocator.init(scratch_gpa);
                defer rcd_scratch.deinit();
                try demosaic_rcd_dispatch(
                    rcd_scratch.allocator(),
                    sensor.cfa,
                    mosaic,
                    planes,
                );
            } else {
                try demosaic_dispatch(sensor.cfa, mosaic, planes);
            }
            if (color_transform) |value| {
                if (engine_version >= 2) {
                    if (reconstruction.enabled) {
                        const neutral_ratios = if (applied_wb_gains.* != null)
                            @as([3]f32, @splat(1))
                        else
                            neutral_ratios_green(sensor.wb_neutral);
                        try kernel_chroma_lowpass_calibrated(
                            scratch_gpa,
                            planes,
                            reconstruction.anti_color_aliasing_strength,
                            neutral_ratios,
                            engine_version < 5,
                        );
                    } else {
                        try kernel_chroma_lowpass_legacy(scratch_gpa, planes);
                    }
                    if (applied_wb_gains.*) |gains| {
                        kernel_highlight_recovery_balanced(
                            planes,
                            gains,
                            reconstruction.highlight_recovery_start,
                        );
                    } else {
                        kernel_highlight_recovery_unbalanced(
                            planes,
                            sensor.wb_neutral,
                            reconstruction.highlight_recovery_start,
                        );
                    }
                }
                switch (camera_profile) {
                    .technical_matrix => value.camera_to_working(planes),
                    .nonlinear => |profile| try profile.applyPreservingTechnicalLuminance(
                        scratch_gpa,
                        planes,
                        value,
                        applied_wb_gains.*,
                    ),
                }
                curve_rendering.apply(planes);
            }
        },
        .exposure => {
            const gain = std.math.exp2(op.exposure.ev);
            for ([_][]f32{ planes.r, planes.g, planes.b }) |plane| {
                kernel_gain(plane, gain);
            }
        },
        .tone_curve => {
            const contrast = op.tone_curve.contrast;
            // A neutral v2 tone operation is an identity in the linear
            // working space. Gamut/output clipping belongs after the working
            // space is converted to linear sRGB; clipping Rec.2020 channels
            // here creates false highlight hues.
            if (engine_version >= 2 and contrast == 0) return;
            for ([_][]f32{ planes.r, planes.g, planes.b }) |plane| {
                kernel_tone_curve(plane, contrast);
            }
        },
        .srgb_encode => {}, // packing runs once, after the stack
    }
}

fn assertFilmCurveSelection(recipe: Recipe, rendering: film_curve.Rendering) void {
    if (recipe.engine_version < 5) {
        assert(recipe.film_curve == .linear);
        assert(std.meta.activeTag(rendering) == .linear);
        return;
    }
    switch (recipe.film_curve) {
        .linear => assert(std.meta.activeTag(rendering) == .linear),
        .capture_one_auto => assert(std.meta.activeTag(rendering) == .capture_one_auto),
    }
}

/// Engine version 1 accepts exactly: black_point first, srgb_encode last,
/// one demosaic between them, only bayer-domain ops before the demosaic and
/// only rgb-domain ops after it.
fn stack_validate(tags: []const std.meta.Tag(Op)) RenderError!void {
    if (tags.len < 3 or tags.len > ops_max) return error.InvalidRecipe;
    if (tags[0] != .black_point) return error.InvalidRecipe;
    if (tags[tags.len - 1] != .srgb_encode) return error.InvalidRecipe;

    var demosaic_at: ?usize = null;
    for (tags, 0..) |tag, i| {
        switch (tag) {
            .black_point => if (i != 0) return error.InvalidRecipe,
            .srgb_encode => if (i != tags.len - 1) return error.InvalidRecipe,
            .demosaic => {
                if (demosaic_at != null) return error.InvalidRecipe;
                demosaic_at = i;
            },
            .white_balance => if (demosaic_at != null) return error.InvalidRecipe,
            .exposure, .tone_curve => {
                if (demosaic_at == null) return error.InvalidRecipe;
            },
        }
    }
    if (demosaic_at == null) return error.InvalidRecipe;
}

/// White-balance gains normalized so green is 1: the neutral is what the
/// camera recorded for a grey patch, so each channel is scaled by
/// neutral_green / neutral_channel.
fn wb_gains(wb: WhiteBalance, neutral: [3]f32) [3]f32 {
    if (wb.as_shot) {
        // Decode validated neutral > 0; assert the pair here.
        for (neutral) |n| assert(n > 0);
        return .{ neutral[1] / neutral[0], 1.0, neutral[1] / neutral[2] };
    }
    assert(wb.gain_r > 0);
    assert(wb.gain_g > 0);
    assert(wb.gain_b > 0);
    return .{ wb.gain_r, wb.gain_g, wb.gain_b };
}

// ---- kernels: the data plane ------------------------------------------------

const vector_len = 8;
const Vf = @Vector(vector_len, f32);

fn kernel_black_scale(dst: []f32, src: []const u16, black: f32, scale: f32) void {
    assert(dst.len == src.len);
    assert(scale > 0);
    const black_v: Vf = @splat(black);
    const scale_v: Vf = @splat(scale);
    const zero_v: Vf = @splat(0);
    var i: usize = 0;
    while (i + vector_len <= dst.len) : (i += vector_len) {
        const raw: @Vector(vector_len, u16) = src[i..][0..vector_len].*;
        const v: Vf = @floatFromInt(raw);
        dst[i..][0..vector_len].* = @max(zero_v, (v - black_v) * scale_v);
    }
    while (i < dst.len) : (i += 1) {
        const v: f32 = @floatFromInt(src[i]);
        dst[i] = @max(0, (v - black) * scale);
    }
}

fn kernel_black_scale_sites(
    dst: []f32,
    src: []const u16,
    width: u32,
    height: u32,
    black: [4]f32,
    white: [4]f32,
) void {
    assert(dst.len == src.len);
    assert(dst.len == @as(usize, width) * height);
    var scale: [4]f32 = undefined;
    for (&scale, black, white) |*value, black_site, white_site| {
        assert(white_site > black_site);
        value.* = 1 / (white_site - black_site);
    }

    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const index = @as(usize, y) * width + x;
            const site = (y & 1) * 2 + (x & 1);
            const raw: f32 = @floatFromInt(src[index]);
            dst[index] = @max(0, (raw - black[site]) * scale[site]);
        }
    }
}

/// Equalize the two green CFA lattices with a deliberately bounded global
/// correction. The calibration flag enables the operation; the two-percent
/// bound prevents scene content from being mistaken for sensor imbalance.
fn kernel_green_equalize(
    mosaic: []f32,
    width: u32,
    height: u32,
    cfa: [4]dng.CfaColor,
) void {
    assert(mosaic.len == @as(usize, width) * height);
    var green_sites: [2]u2 = undefined;
    var green_count: u2 = 0;
    for (cfa, 0..) |color_at_site, site| {
        if (color_at_site == .green) {
            assert(green_count < 2);
            green_sites[green_count] = @intCast(site);
            green_count += 1;
        }
    }
    assert(green_count == 2);

    var sums: [2]f64 = @splat(0);
    var counts: [2]u64 = @splat(0);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const site: u2 = @intCast((y & 1) * 2 + (x & 1));
            for (green_sites, 0..) |green_site, green_index| {
                if (site == green_site) {
                    sums[green_index] += mosaic[pixel_index(width, x, y)];
                    counts[green_index] += 1;
                }
            }
        }
    }
    assert(counts[0] > 0);
    assert(counts[1] > 0);
    const mean_first = sums[0] / @as(f64, @floatFromInt(counts[0]));
    const mean_second = sums[1] / @as(f64, @floatFromInt(counts[1]));
    if (mean_first <= 0 or mean_second <= 0) return;
    const ratio = std.math.clamp(mean_first / mean_second, 0.98, 1.02);
    const gain_first: f32 = @floatCast(1 / @sqrt(ratio));
    const gain_second: f32 = @floatCast(@sqrt(ratio));
    assert(gain_first >= 0.98);
    assert(gain_first <= 1.02);
    assert(gain_second >= 0.98);
    assert(gain_second <= 1.02);

    y = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const site: u2 = @intCast((y & 1) * 2 + (x & 1));
            const index = pixel_index(width, x, y);
            if (site == green_sites[0]) mosaic[index] *= gain_first;
            if (site == green_sites[1]) mosaic[index] *= gain_second;
        }
    }
}

/// Remove only isolated positive outliers using same-color neighbors two
/// pixels away. Amount follows the extracted 0...100 calibration scale; zero
/// is an exact identity and the correction never crosses CFA channels.
fn kernel_hot_pixel_cleanup(
    scratch_gpa: std.mem.Allocator,
    mosaic: []f32,
    width: u32,
    height: u32,
    amount: f32,
) RenderError!void {
    assert(mosaic.len == @as(usize, width) * height);
    assert(std.math.isFinite(amount));
    assert(amount >= 0);
    assert(amount <= 100);
    if (amount == 0 or width < 5 or height < 5) return;
    const source = try scratch_gpa.dupe(f32, mosaic);
    defer scratch_gpa.free(source);
    const blend = amount / 100;
    const threshold = 0.25 - 0.20 * blend;
    var y: u32 = 2;
    while (y < height - 2) : (y += 1) {
        var x: u32 = 2;
        while (x < width - 2) : (x += 1) {
            var neighbors = [4]f32{
                source[pixel_index(width, x - 2, y)],
                source[pixel_index(width, x + 2, y)],
                source[pixel_index(width, x, y - 2)],
                source[pixel_index(width, x, y + 2)],
            };
            std.sort.insertion(f32, &neighbors, {}, std.sort.asc(f32));
            const local = 0.5 * (neighbors[1] + neighbors[2]);
            const index = pixel_index(width, x, y);
            if (source[index] > neighbors[3] + threshold) {
                mosaic[index] = source[index] + (local - source[index]) * blend;
            }
        }
    }
}

/// Remove isolated positive and negative sensor defects without mixing CFA
/// channels. Unlike the historical calibrated cleanup, the conservative
/// defect gate is always active: calibration only tightens its threshold.
/// Engine versions before v5 continue to use `kernel_hot_pixel_cleanup`.
fn kernel_isolated_pixel_cleanup_v2(
    scratch_gpa: std.mem.Allocator,
    mosaic: []f32,
    width: u32,
    height: u32,
    calibrated_amount: f32,
) RenderError!void {
    assert(mosaic.len == @as(usize, width) * height);
    assert(std.math.isFinite(calibrated_amount));
    assert(calibrated_amount >= 0);
    assert(calibrated_amount <= 100);
    if (width < 5 or height < 5) return;

    const source = try scratch_gpa.dupe(f32, mosaic);
    defer scratch_gpa.free(source);
    const threshold = 0.08 - 0.03 * (calibrated_amount / 100);

    var y: u32 = 2;
    while (y < height - 2) : (y += 1) {
        var x: u32 = 2;
        while (x < width - 2) : (x += 1) {
            var neighbors = [8]f32{
                source[pixel_index(width, x - 2, y - 2)],
                source[pixel_index(width, x, y - 2)],
                source[pixel_index(width, x + 2, y - 2)],
                source[pixel_index(width, x - 2, y)],
                source[pixel_index(width, x + 2, y)],
                source[pixel_index(width, x - 2, y + 2)],
                source[pixel_index(width, x, y + 2)],
                source[pixel_index(width, x + 2, y + 2)],
            };
            std.sort.insertion(f32, &neighbors, {}, std.sort.asc(f32));
            const local = 0.5 * (neighbors[3] + neighbors[4]);
            const index = pixel_index(width, x, y);
            const center = source[index];
            if (center < neighbors[1] - threshold or
                center > neighbors[6] + threshold)
            {
                mosaic[index] = local;
            }
        }
    }
}

fn kernel_wb(
    mosaic: []f32,
    width: u32,
    height: u32,
    cfa: [4]dng.CfaColor,
    gains: [3]f32,
) void {
    assert(mosaic.len == @as(usize, width) * height);
    for (gains) |g| assert(g > 0);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        const row = mosaic[@as(usize, y) * width ..][0..width];
        const g_even = gains[@intFromEnum(cfa[(y & 1) * 2])];
        const g_odd = gains[@intFromEnum(cfa[(y & 1) * 2 + 1])];
        kernel_wb_row(row, g_even, g_odd);
    }
}

fn kernel_wb_row(row: []f32, g_even: f32, g_odd: f32) void {
    assert(g_even > 0);
    assert(g_odd > 0);
    var pattern: [vector_len]f32 = undefined;
    for (&pattern, 0..) |*p, i| p.* = if (i % 2 == 0) g_even else g_odd;
    const pattern_v: Vf = pattern;
    var x: usize = 0;
    while (x + vector_len <= row.len) : (x += vector_len) {
        const v: Vf = row[x..][0..vector_len].*;
        row[x..][0..vector_len].* = v * pattern_v;
    }
    while (x < row.len) : (x += 1) {
        row[x] *= if (x % 2 == 0) g_even else g_odd;
    }
}

fn kernel_gain(plane: []f32, gain: f32) void {
    assert(gain > 0);
    assert(std.math.isFinite(gain));
    const gain_v: Vf = @splat(gain);
    var i: usize = 0;
    while (i + vector_len <= plane.len) : (i += vector_len) {
        const v: Vf = plane[i..][0..vector_len].*;
        plane[i..][0..vector_len].* = v * gain_v;
    }
    while (i < plane.len) : (i += 1) plane[i] *= gain;
}

/// Bayer reconstruction carries luminance detail at full resolution, but its
/// red-minus-green and blue-minus-green estimates are only half-resolution.
/// A broad, selective chroma low-pass suppresses the alternating false colour
/// produced by neutral fabric near the sensor Nyquist limit while retaining the
/// sharper green/luminance plane. Stable chroma is left untouched; only a large
/// deviation from the local chroma mean is blended away. Engine v1 bypasses it.
fn kernel_chroma_lowpass_legacy(
    scratch_gpa: std.mem.Allocator,
    planes: *image.Planes,
) RenderError!void {
    assert(planes.r.len == planes.g.len);
    assert(planes.r.len == planes.b.len);
    const current = try scratch_gpa.alloc(f32, planes.r.len);
    defer scratch_gpa.free(current);
    const horizontal = try scratch_gpa.alloc(f32, planes.r.len);
    defer scratch_gpa.free(horizontal);
    const filtered = try scratch_gpa.alloc(f32, planes.r.len);
    defer scratch_gpa.free(filtered);
    const radius: i64 = 12;
    const diameter: f32 = @floatFromInt(radius * 2 + 1);
    for ([_][]f32{ planes.r, planes.b }) |channel| {
        for (current, channel, planes.g) |*chroma, value, green| {
            chroma.* = value - green;
        }
        var y: u32 = 0;
        while (y < planes.height) : (y += 1) {
            const row = @as(usize, y) * planes.width;
            var sum: f32 = 0;
            var offset: i64 = -radius;
            while (offset <= radius) : (offset += 1) {
                const source_x: u32 = @intCast(std.math.clamp(
                    offset,
                    0,
                    @as(i64, planes.width) - 1,
                ));
                sum += current[row + source_x];
            }
            var x: u32 = 0;
            while (x < planes.width) : (x += 1) {
                horizontal[row + x] = sum / diameter;
                const left_x: u32 = @intCast(std.math.clamp(
                    @as(i64, x) - radius,
                    0,
                    @as(i64, planes.width) - 1,
                ));
                const right_x: u32 = @intCast(std.math.clamp(
                    @as(i64, x) + radius + 1,
                    0,
                    @as(i64, planes.width) - 1,
                ));
                sum += current[row + right_x] - current[row + left_x];
            }
        }
        var x: u32 = 0;
        while (x < planes.width) : (x += 1) {
            var sum: f32 = 0;
            var offset: i64 = -radius;
            while (offset <= radius) : (offset += 1) {
                const source_y: u32 = @intCast(std.math.clamp(
                    offset,
                    0,
                    @as(i64, planes.height) - 1,
                ));
                sum += horizontal[@as(usize, source_y) * planes.width + x];
            }
            y = 0;
            while (y < planes.height) : (y += 1) {
                const center = @as(usize, y) * planes.width + x;
                filtered[center] = sum / diameter;
                const top_y: u32 = @intCast(std.math.clamp(
                    @as(i64, y) - radius,
                    0,
                    @as(i64, planes.height) - 1,
                ));
                const bottom_y: u32 = @intCast(std.math.clamp(
                    @as(i64, y) + radius + 1,
                    0,
                    @as(i64, planes.height) - 1,
                ));
                sum += horizontal[@as(usize, bottom_y) * planes.width + x] -
                    horizontal[@as(usize, top_y) * planes.width + x];
            }
        }
        for (channel, planes.g, current, filtered) |*value, green, original, local| {
            const residual = @abs(original - local);
            const blend = std.math.clamp((residual - 0.005) * 20, 0, 1);
            const chroma = original + (local - original) * blend;
            value.* = green + chroma;
        }
    }
}

/// The calibrated path is independently versioned so historical v2 bytes do
/// not change while its texture mask evolves against the visual corpus.
fn kernel_chroma_lowpass_calibrated(
    scratch_gpa: std.mem.Allocator,
    planes: *image.Planes,
    strength: f32,
    neutral_ratios: [3]f32,
    classify_neutral_texture: bool,
) RenderError!void {
    assert(planes.r.len == planes.g.len);
    assert(planes.r.len == planes.b.len);
    assert(std.math.isFinite(strength));
    assert(strength >= 0);
    assert(strength <= 1);
    for (neutral_ratios) |ratio| {
        assert(std.math.isFinite(ratio));
        assert(ratio > 0);
    }
    if (strength == 0) return;
    const current = try scratch_gpa.alloc(f32, planes.r.len);
    defer scratch_gpa.free(current);
    const horizontal = try scratch_gpa.alloc(f32, planes.r.len);
    defer scratch_gpa.free(horizontal);
    const filtered = try scratch_gpa.alloc(f32, planes.r.len);
    defer scratch_gpa.free(filtered);
    const radius: i64 = 12;
    const diameter: f32 = @floatFromInt(radius * 2 + 1);
    const channels = [_][]f32{ planes.r, planes.b };
    const ratios = [_]f32{ neutral_ratios[0], neutral_ratios[2] };
    for (channels, ratios) |channel, neutral_ratio| {
        for (current, channel, planes.g) |*chroma, value, green| {
            chroma.* = value - green * neutral_ratio;
        }
        var y: u32 = 0;
        while (y < planes.height) : (y += 1) {
            const row = @as(usize, y) * planes.width;
            var sum: f32 = 0;
            var offset: i64 = -radius;
            while (offset <= radius) : (offset += 1) {
                const source_x: u32 = @intCast(std.math.clamp(
                    offset,
                    0,
                    @as(i64, planes.width) - 1,
                ));
                sum += current[row + source_x];
            }
            var x: u32 = 0;
            while (x < planes.width) : (x += 1) {
                horizontal[row + x] = sum / diameter;
                const left_x: u32 = @intCast(std.math.clamp(
                    @as(i64, x) - radius,
                    0,
                    @as(i64, planes.width) - 1,
                ));
                const right_x: u32 = @intCast(std.math.clamp(
                    @as(i64, x) + radius + 1,
                    0,
                    @as(i64, planes.width) - 1,
                ));
                sum += current[row + right_x] - current[row + left_x];
            }
        }
        var x: u32 = 0;
        while (x < planes.width) : (x += 1) {
            var sum: f32 = 0;
            var offset: i64 = -radius;
            while (offset <= radius) : (offset += 1) {
                const source_y: u32 = @intCast(std.math.clamp(
                    offset,
                    0,
                    @as(i64, planes.height) - 1,
                ));
                sum += horizontal[@as(usize, source_y) * planes.width + x];
            }
            y = 0;
            while (y < planes.height) : (y += 1) {
                const center = @as(usize, y) * planes.width + x;
                filtered[center] = sum / diameter;
                const top_y: u32 = @intCast(std.math.clamp(
                    @as(i64, y) - radius,
                    0,
                    @as(i64, planes.height) - 1,
                ));
                const bottom_y: u32 = @intCast(std.math.clamp(
                    @as(i64, y) + radius + 1,
                    0,
                    @as(i64, planes.height) - 1,
                ));
                sum += horizontal[@as(usize, bottom_y) * planes.width + x] -
                    horizontal[@as(usize, top_y) * planes.width + x];
            }
        }
        @memset(horizontal, 0);
        y = 1;
        while (y + 1 < planes.height) : (y += 1) {
            x = 1;
            while (x + 1 < planes.width) : (x += 1) {
                const index = @as(usize, y) * planes.width + x;
                const original = current[index];
                const horizontal_alternation =
                    original * current[index - 1] < 0 and
                    original * current[index + 1] < 0;
                const vertical_alternation =
                    original * current[index - planes.width] < 0 and
                    original * current[index + planes.width] < 0;
                const local = filtered[index];
                const green = planes.g[index];
                const horizontal_green_product =
                    (green - planes.g[index - 1]) * (green - planes.g[index + 1]);
                const vertical_green_product =
                    (green - planes.g[index - planes.width]) *
                    (green - planes.g[index + planes.width]);
                const luminance_oscillation =
                    horizontal_green_product > 0.000025 or
                    vertical_green_product > 0.000025;
                const zero_mean_chroma = @abs(local) <= 0.12;
                const neutral_texture = classify_neutral_texture and
                    luminance_oscillation and zero_mean_chroma;
                if (horizontal_alternation or vertical_alternation or neutral_texture) {
                    horizontal[index] = 1;
                }
            }
        }

        y = 1;
        while (y + 1 < planes.height) : (y += 1) {
            x = 1;
            while (x + 1 < planes.width) : (x += 1) {
                const index = @as(usize, y) * planes.width + x;
                var selected = false;
                var offset_y: i64 = -2;
                while (offset_y <= 2) : (offset_y += 1) {
                    const sample_y: u32 = @intCast(std.math.clamp(
                        @as(i64, y) + offset_y,
                        1,
                        @as(i64, planes.height) - 2,
                    ));
                    var offset_x: i64 = -2;
                    while (offset_x <= 2) : (offset_x += 1) {
                        const sample_x: u32 = @intCast(std.math.clamp(
                            @as(i64, x) + offset_x,
                            1,
                            @as(i64, planes.width) - 2,
                        ));
                        const sample_index = @as(usize, sample_y) * planes.width + sample_x;
                        if (horizontal[sample_index] != 0) selected = true;
                    }
                }
                if (!selected) continue;
                const original = current[index];
                const local = filtered[index];
                const target = if (@abs(local) <= 0.12) @as(f32, 0) else local;
                const residual = @abs(original - target);
                const blend = std.math.clamp((residual - 0.005) * 20 * strength, 0, 1);
                const chroma = original + (target - original) * blend;
                channel[index] = planes.g[index] * neutral_ratio + chroma;
            }
        }
    }
}

fn neutral_ratios_green(neutral: [3]f32) [3]f32 {
    for (neutral) |value| {
        assert(std.math.isFinite(value));
        assert(value > 0);
    }
    return .{ neutral[0] / neutral[1], 1, neutral[2] / neutral[1] };
}

/// White balance cannot recover a channel that already hit sensor white. Near
/// that boundary, progressively remove the false chroma produced when clipped
/// camera channels receive different WB gains. Values below `start` of the
/// second-brightest channel's pre-WB range are bit-identical; clipped highlights
/// converge to the strongest surviving common camera-RGB value.
fn kernel_highlight_recovery_balanced(
    planes: *image.Planes,
    gains: [3]f32,
    start: f32,
) void {
    assert(planes.r.len == planes.g.len);
    assert(planes.r.len == planes.b.len);
    for (gains) |gain| assert(gain > 0);
    assert(start >= 0);
    assert(start < 1);

    const scale: f32 = 1 / (1 - start);
    for (planes.r, planes.g, planes.b) |*r, *g, *b| {
        const sensor_peak = middle3(r.* / gains[0], g.* / gains[1], b.* / gains[2]);
        const blend = std.math.clamp((sensor_peak - start) * scale, 0, 1);
        if (blend == 0) continue;
        const neutral = @min(r.*, @min(g.*, b.*));
        r.* += (neutral - r.*) * blend;
        g.* += (neutral - g.*) * blend;
        b.* += (neutral - b.*) * blend;
    }
}

/// Native DNG colour selection is performed by the camera transform rather
/// than Bayer-domain gains. Convert each camera channel to its neutral-relative
/// intensity for blending, then return it to the original camera-RGB ratios.
fn kernel_highlight_recovery_unbalanced(
    planes: *image.Planes,
    neutral: [3]f32,
    start: f32,
) void {
    assert(planes.r.len == planes.g.len);
    assert(planes.r.len == planes.b.len);
    for (neutral) |value| assert(value > 0);
    assert(start >= 0);
    assert(start < 1);

    const neutral_max = @max(neutral[0], @max(neutral[1], neutral[2]));
    const ratios = [3]f32{
        neutral[0] / neutral_max,
        neutral[1] / neutral_max,
        neutral[2] / neutral_max,
    };
    const scale: f32 = 1 / (1 - start);
    for (planes.r, planes.g, planes.b) |*r, *g, *b| {
        const sensor_peak = middle3(r.*, g.*, b.*);
        const blend = std.math.clamp((sensor_peak - start) * scale, 0, 1);
        if (blend == 0) continue;
        const common = @min(
            r.* / ratios[0],
            @min(g.* / ratios[1], b.* / ratios[2]),
        );
        r.* += (common * ratios[0] - r.*) * blend;
        g.* += (common * ratios[1] - g.*) * blend;
        b.* += (common * ratios[2] - b.*) * blend;
    }
}

fn middle3(a: f32, b: f32, c: f32) f32 {
    return @max(@min(a, b), @min(@max(a, b), c));
}

/// Contrast as a linear blend toward the smoothstep S-curve, on values
/// clamped to [0, 1]: y = x + c * (x²(3 − 2x) − x). Polynomial only — no
/// transcendentals in the loop, fully deterministic, trivially vectorized.
fn kernel_tone_curve(plane: []f32, contrast: f32) void {
    assert(contrast >= 0);
    assert(contrast <= 1);
    const c_v: Vf = @splat(contrast);
    const zero_v: Vf = @splat(0);
    const one_v: Vf = @splat(1);
    const three_v: Vf = @splat(3);
    const two_v: Vf = @splat(2);
    var i: usize = 0;
    while (i + vector_len <= plane.len) : (i += vector_len) {
        const raw: Vf = plane[i..][0..vector_len].*;
        const x = @min(one_v, @max(zero_v, raw));
        const s = x * x * (three_v - two_v * x);
        plane[i..][0..vector_len].* = x + c_v * (s - x);
    }
    while (i < plane.len) : (i += 1) {
        const x = std.math.clamp(plane[i], 0, 1);
        const s = x * x * (3 - 2 * x);
        plane[i] = x + contrast * (s - x);
    }
}

/// Box downsample: each output pixel is the mean of an integer bin of source
/// pixels. Bin edges come from the lattice map `edge(i) = i * source / target`,
/// so bins tile the source exactly — every source pixel lands in one bin,
/// none twice, none dropped. `row_sum` is caller scratch, `width_source` long.
fn kernel_box_downsample(
    target: []f32,
    width_target: u32,
    height_target: u32,
    source: []const f32,
    width_source: u32,
    height_source: u32,
    row_sum: []f32,
) void {
    assert(target.len == @as(usize, width_target) * height_target);
    assert(source.len == @as(usize, width_source) * height_source);
    assert(width_target > 0);
    assert(height_target > 0);
    assert(width_target <= width_source);
    assert(height_target <= height_source);
    assert(row_sum.len == width_source);

    var y_target: u32 = 0;
    while (y_target < height_target) : (y_target += 1) {
        const y0: u32 = @intCast(@as(u64, y_target) * height_source / height_target);
        const y1: u32 = @intCast((@as(u64, y_target) + 1) * height_source / height_target);
        assert(y1 > y0);
        @memset(row_sum, 0);
        var y = y0;
        while (y < y1) : (y += 1) {
            kernel_row_add(row_sum, source[@as(usize, y) * width_source ..][0..width_source]);
        }
        const row_target = target[@as(usize, y_target) * width_target ..][0..width_target];
        kernel_bins_mean(row_target, row_sum, y1 - y0);
    }
}

fn kernel_row_add(sum: []f32, row: []const f32) void {
    assert(sum.len == row.len);
    var i: usize = 0;
    while (i + vector_len <= sum.len) : (i += vector_len) {
        const s: Vf = sum[i..][0..vector_len].*;
        const r: Vf = row[i..][0..vector_len].*;
        sum[i..][0..vector_len].* = s + r;
    }
    while (i < sum.len) : (i += 1) sum[i] += row[i];
}

/// Horizontal step of the box downsample: bin a row of column sums into
/// means. `rows` is how many source rows each column sum accumulates.
fn kernel_bins_mean(target: []f32, row_sum: []const f32, rows: u32) void {
    assert(rows > 0);
    assert(target.len > 0);
    assert(target.len <= row_sum.len);
    for (target, 0..) |*out, x_target| {
        const x0: usize = @intCast(@as(u64, x_target) * row_sum.len / target.len);
        const x1: usize = @intCast((@as(u64, x_target) + 1) * row_sum.len / target.len);
        assert(x1 > x0);
        var sum: f32 = 0;
        for (row_sum[x0..x1]) |v| sum += v;
        out.* = sum / @as(f32, @floatFromInt(@as(u64, rows) * (x1 - x0)));
    }
}

fn kernel_srgb_pack(rgba: []u8, r: []const f32, g: []const f32, b: []const f32) void {
    assert(r.len == g.len);
    assert(g.len == b.len);
    assert(rgba.len == r.len * 4);
    for (r, g, b, 0..) |red, green, blue, i| {
        rgba[i * 4 + 0] = srgb_encode_scalar(red);
        rgba[i * 4 + 1] = srgb_encode_scalar(green);
        rgba[i * 4 + 2] = srgb_encode_scalar(blue);
        rgba[i * 4 + 3] = 255;
    }
}

fn pack_srgb_timed(
    rgba: []u8,
    r: []const f32,
    g: []const f32,
    b: []const f32,
    enabled: bool,
) u64 {
    if (!enabled) {
        kernel_srgb_pack(rgba, r, g, b);
        return 0;
    }
    const started = monotonic_ns();
    kernel_srgb_pack(rgba, r, g, b);
    return monotonic_ns() - started;
}

fn monotonic_ns() u64 {
    var timestamp: std.c.timespec = undefined;
    _ = std.c.clock_gettime(.MONOTONIC, &timestamp);
    return @intCast(
        @as(i128, timestamp.sec) * std.time.ns_per_s + timestamp.nsec,
    );
}

fn kernel_linear_pack(rgba: []f32, r: []const f32, g: []const f32, b: []const f32) void {
    assert(r.len == g.len);
    assert(g.len == b.len);
    assert(rgba.len == r.len * 4);
    for (r, g, b, 0..) |red, green, blue, i| {
        rgba[i * 4 + 0] = red;
        rgba[i * 4 + 1] = green;
        rgba[i * 4 + 2] = blue;
        rgba[i * 4 + 3] = 1;
    }
}

/// The exact sRGB transfer function, quantized to u8.
fn srgb_encode_scalar(linear: f32) u8 {
    const x = std.math.clamp(linear, 0, 1);
    const s = if (x <= 0.0031308)
        12.92 * x
    else
        1.055 * std.math.pow(f32, x, 1.0 / 2.4) - 0.055;
    const quantized = @round(std.math.clamp(s, 0, 1) * 255);
    return @intFromFloat(quantized);
}

// ---- demosaic ----------------------------------------------------------------

/// Bilinear demosaic, monomorphized per CFA layout: the four instantiations
/// make every `site_color` lookup a compile-time constant fold.
fn demosaic_dispatch(
    cfa: [4]dng.CfaColor,
    mosaic: []const f32,
    planes: *image.Planes,
) RenderError!void {
    const layouts = [_][4]dng.CfaColor{
        .{ .red, .green, .green, .blue },
        .{ .blue, .green, .green, .red },
        .{ .green, .red, .blue, .green },
        .{ .green, .blue, .red, .green },
    };
    inline for (layouts) |layout| {
        if (std.mem.eql(dng.CfaColor, &cfa, &layout)) {
            return demosaic_bilinear(layout, mosaic, planes);
        }
    }
    return error.UnsupportedSensor;
}

fn demosaic_rcd_dispatch(
    arena: std.mem.Allocator,
    cfa: [4]dng.CfaColor,
    mosaic: []const f32,
    planes: *image.Planes,
) RenderError!void {
    const layouts = [_][4]dng.CfaColor{
        .{ .red, .green, .green, .blue },
        .{ .blue, .green, .green, .red },
        .{ .green, .red, .blue, .green },
        .{ .green, .blue, .red, .green },
    };
    inline for (layouts) |layout| {
        if (std.mem.eql(dng.CfaColor, &cfa, &layout)) {
            return demosaic_rcd_reference(arena, layout, mosaic, planes);
        }
    }
    return error.UnsupportedSensor;
}

fn demosaic_bilinear(
    comptime cfa: [4]dng.CfaColor,
    mosaic: []const f32,
    planes: *image.Planes,
) void {
    const width = planes.width;
    const height = planes.height;
    assert(mosaic.len == @as(usize, width) * height);
    assert(mosaic.len == planes.r.len);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const i = @as(usize, y) * width + x;
            const v = mosaic[i];
            const cross = neighbors_cross(mosaic, width, height, x, y);
            const diagonal = neighbors_diagonal(mosaic, width, height, x, y);
            switch (site_color(cfa, x, y)) {
                .green => {
                    const row = neighbors_row(mosaic, width, x, y);
                    const column = neighbors_column(mosaic, width, height, x, y);
                    planes.g[i] = v;
                    if (site_color(cfa, x +% 1, y) == .red) {
                        planes.r[i] = row;
                        planes.b[i] = column;
                    } else {
                        planes.r[i] = column;
                        planes.b[i] = row;
                    }
                },
                .red => {
                    planes.r[i] = v;
                    planes.g[i] = cross;
                    planes.b[i] = diagonal;
                },
                .blue => {
                    planes.b[i] = v;
                    planes.g[i] = cross;
                    planes.r[i] = diagonal;
                },
            }
        }
    }
}

/// Whole-frame Ratio Corrected Demosaicing reference. This intentionally
/// favors readable equations over tiling/SIMD: it is the semantic candidate
/// that later CPU optimization and Metal kernels must match. The existing
/// bilinear path remains active until this candidate clears the artifact
/// corpus and an explicit graph migration selects its implementation ID.
fn demosaic_rcd_reference(
    arena: std.mem.Allocator,
    comptime cfa: [4]dng.CfaColor,
    mosaic: []const f32,
    planes: *image.Planes,
) RenderError!void {
    const width = planes.width;
    const height = planes.height;
    const pixel_count = @as(usize, width) * height;
    assert(mosaic.len == pixel_count);
    assert(planes.r.len == pixel_count);
    assert(planes.g.len == pixel_count);
    assert(planes.b.len == pixel_count);

    // RCD needs a four-pixel neighborhood. Bilinear is a deterministic border
    // policy and the complete fallback for tiny images.
    demosaic_bilinear(cfa, mosaic, planes);
    const radius: u32 = 4;
    if (width <= radius * 2 or height <= radius * 2) return;

    const direction_vh = try arena.alloc(f32, pixel_count);
    const low_pass_or_direction_pq = try arena.alloc(f32, pixel_count);
    const high_pass_p = try arena.alloc(f32, pixel_count);
    const high_pass_q = try arena.alloc(f32, pixel_count);
    @memset(direction_vh, 0);
    @memset(low_pass_or_direction_pq, 0);
    @memset(high_pass_p, 0);
    @memset(high_pass_q, 0);

    const epsilon: f32 = 1e-5;
    const epsilon_squared: f32 = epsilon * epsilon;

    // Step 1: Discriminate vertical and horizontal structure from a
    // six-neighbor high-pass response.
    var y: u32 = radius;
    while (y < height - radius) : (y += 1) {
        var x: u32 = radius;
        while (x < width - radius) : (x += 1) {
            var vertical_stat: f32 = 0;
            var horizontal_stat: f32 = 0;
            var offset: i64 = -1;
            while (offset <= 1) : (offset += 1) {
                vertical_stat += squared(rcd_high_pass_vertical(
                    mosaic,
                    width,
                    height,
                    x,
                    @intCast(@as(i64, y) + offset),
                ));
                horizontal_stat += squared(rcd_high_pass_horizontal(
                    mosaic,
                    width,
                    height,
                    @intCast(@as(i64, x) + offset),
                    y,
                ));
            }
            vertical_stat = @max(epsilon_squared, vertical_stat);
            horizontal_stat = @max(epsilon_squared, horizontal_stat);
            direction_vh[pixel_index(width, x, y)] =
                vertical_stat / (vertical_stat + horizontal_stat);
        }
    }

    // Step 2: Low-pass energy at red/blue sites supplies the ratio correction
    // used to estimate green without crossing strong edges.
    y = 2;
    while (y < height - 2) : (y += 1) {
        var x: u32 = 2;
        while (x < width - 2) : (x += 1) {
            if (site_color(cfa, x, y) == .green) continue;
            low_pass_or_direction_pq[pixel_index(width, x, y)] =
                fetch_u32(mosaic, width, x, y) +
                0.5 * (fetch_u32(mosaic, width, x - 1, y) +
                    fetch_u32(mosaic, width, x + 1, y) +
                    fetch_u32(mosaic, width, x, y - 1) +
                    fetch_u32(mosaic, width, x, y + 1)) +
                0.25 * (fetch_u32(mosaic, width, x - 1, y - 1) +
                    fetch_u32(mosaic, width, x + 1, y - 1) +
                    fetch_u32(mosaic, width, x - 1, y + 1) +
                    fetch_u32(mosaic, width, x + 1, y + 1));
        }
    }

    // Step 3: Populate green at red/blue sites from ratio-corrected cardinal
    // estimates, weighted toward the smoother direction.
    y = radius;
    while (y < height - radius) : (y += 1) {
        var x: u32 = radius;
        while (x < width - radius) : (x += 1) {
            if (site_color(cfa, x, y) == .green) continue;
            const center = fetch_u32(mosaic, width, x, y);
            const north_gradient = epsilon +
                @abs(fetch_u32(mosaic, width, x, y - 1) -
                    fetch_u32(mosaic, width, x, y + 1)) +
                @abs(center - fetch_u32(mosaic, width, x, y - 2)) +
                @abs(fetch_u32(mosaic, width, x, y - 1) -
                    fetch_u32(mosaic, width, x, y - 3)) +
                @abs(fetch_u32(mosaic, width, x, y - 2) -
                    fetch_u32(mosaic, width, x, y - 4));
            const south_gradient = epsilon +
                @abs(fetch_u32(mosaic, width, x, y - 1) -
                    fetch_u32(mosaic, width, x, y + 1)) +
                @abs(center - fetch_u32(mosaic, width, x, y + 2)) +
                @abs(fetch_u32(mosaic, width, x, y + 1) -
                    fetch_u32(mosaic, width, x, y + 3)) +
                @abs(fetch_u32(mosaic, width, x, y + 2) -
                    fetch_u32(mosaic, width, x, y + 4));
            const west_gradient = epsilon +
                @abs(fetch_u32(mosaic, width, x - 1, y) -
                    fetch_u32(mosaic, width, x + 1, y)) +
                @abs(center - fetch_u32(mosaic, width, x - 2, y)) +
                @abs(fetch_u32(mosaic, width, x - 1, y) -
                    fetch_u32(mosaic, width, x - 3, y)) +
                @abs(fetch_u32(mosaic, width, x - 2, y) -
                    fetch_u32(mosaic, width, x - 4, y));
            const east_gradient = epsilon +
                @abs(fetch_u32(mosaic, width, x - 1, y) -
                    fetch_u32(mosaic, width, x + 1, y)) +
                @abs(center - fetch_u32(mosaic, width, x + 2, y)) +
                @abs(fetch_u32(mosaic, width, x + 1, y) -
                    fetch_u32(mosaic, width, x + 3, y)) +
                @abs(fetch_u32(mosaic, width, x + 2, y) -
                    fetch_u32(mosaic, width, x + 4, y));

            const low_pass = low_pass_or_direction_pq[pixel_index(width, x, y)];
            const north = fetch_u32(mosaic, width, x, y - 1) * (2 * low_pass) /
                (epsilon + low_pass +
                    low_pass_or_direction_pq[pixel_index(width, x, y - 2)]);
            const south = fetch_u32(mosaic, width, x, y + 1) * (2 * low_pass) /
                (epsilon + low_pass +
                    low_pass_or_direction_pq[pixel_index(width, x, y + 2)]);
            const west = fetch_u32(mosaic, width, x - 1, y) * (2 * low_pass) /
                (epsilon + low_pass +
                    low_pass_or_direction_pq[pixel_index(width, x - 2, y)]);
            const east = fetch_u32(mosaic, width, x + 1, y) * (2 * low_pass) /
                (epsilon + low_pass +
                    low_pass_or_direction_pq[pixel_index(width, x + 2, y)]);
            const vertical = (south_gradient * north + north_gradient * south) /
                (north_gradient + south_gradient);
            const horizontal = (west_gradient * east + east_gradient * west) /
                (west_gradient + east_gradient);
            const direction = refined_direction(direction_vh, width, x, y);
            planes.g[pixel_index(width, x, y)] =
                @max(0, interpolate(direction, horizontal, vertical));
        }
    }

    // Step 4.0: Diagonal high-pass responses for the red-at-blue and
    // blue-at-red color-difference interpolation.
    y = 3;
    while (y < height - 3) : (y += 1) {
        var x: u32 = 3;
        while (x < width - 3) : (x += 1) {
            const index = pixel_index(width, x, y);
            high_pass_p[index] = squared(rcd_high_pass_diagonal_p(
                mosaic,
                width,
                height,
                x,
                y,
            ));
            high_pass_q[index] = squared(rcd_high_pass_diagonal_q(
                mosaic,
                width,
                height,
                x,
                y,
            ));
        }
    }

    @memset(low_pass_or_direction_pq, 0);
    y = radius;
    while (y < height - radius) : (y += 1) {
        var x: u32 = radius;
        while (x < width - radius) : (x += 1) {
            if (site_color(cfa, x, y) == .green) continue;
            const p_stat = @max(epsilon_squared, high_pass_p[pixel_index(width, x - 1, y - 1)] +
                high_pass_p[pixel_index(width, x, y)] +
                high_pass_p[pixel_index(width, x + 1, y + 1)]);
            const q_stat = @max(epsilon_squared, high_pass_q[pixel_index(width, x + 1, y - 1)] +
                high_pass_q[pixel_index(width, x, y)] +
                high_pass_q[pixel_index(width, x - 1, y + 1)]);
            low_pass_or_direction_pq[pixel_index(width, x, y)] =
                p_stat / (p_stat + q_stat);
        }
    }

    // Step 4.2: Reconstruct the opposite chroma at red/blue sites from
    // diagonal color differences.
    y = radius;
    while (y < height - radius) : (y += 1) {
        var x: u32 = radius;
        while (x < width - radius) : (x += 1) {
            const color_at_site = site_color(cfa, x, y);
            if (color_at_site == .green) continue;
            const opposite = if (color_at_site == .red) planes.b else planes.r;
            const index = pixel_index(width, x, y);
            const direction = refined_direction(
                low_pass_or_direction_pq,
                width,
                x,
                y,
            );
            const northwest_gradient = epsilon +
                @abs(opposite[pixel_index(width, x - 1, y - 1)] -
                    opposite[pixel_index(width, x + 1, y + 1)]) +
                @abs(opposite[pixel_index(width, x - 1, y - 1)] -
                    opposite[pixel_index(width, x - 3, y - 3)]) +
                @abs(planes.g[index] - planes.g[pixel_index(width, x - 2, y - 2)]);
            const northeast_gradient = epsilon +
                @abs(opposite[pixel_index(width, x + 1, y - 1)] -
                    opposite[pixel_index(width, x - 1, y + 1)]) +
                @abs(opposite[pixel_index(width, x + 1, y - 1)] -
                    opposite[pixel_index(width, x + 3, y - 3)]) +
                @abs(planes.g[index] - planes.g[pixel_index(width, x + 2, y - 2)]);
            const southwest_gradient = epsilon +
                @abs(opposite[pixel_index(width, x + 1, y - 1)] -
                    opposite[pixel_index(width, x - 1, y + 1)]) +
                @abs(opposite[pixel_index(width, x - 1, y + 1)] -
                    opposite[pixel_index(width, x - 3, y + 3)]) +
                @abs(planes.g[index] - planes.g[pixel_index(width, x - 2, y + 2)]);
            const southeast_gradient = epsilon +
                @abs(opposite[pixel_index(width, x - 1, y - 1)] -
                    opposite[pixel_index(width, x + 1, y + 1)]) +
                @abs(opposite[pixel_index(width, x + 1, y + 1)] -
                    opposite[pixel_index(width, x + 3, y + 3)]) +
                @abs(planes.g[index] - planes.g[pixel_index(width, x + 2, y + 2)]);
            const difference_northwest =
                opposite[pixel_index(width, x - 1, y - 1)] -
                planes.g[pixel_index(width, x - 1, y - 1)];
            const difference_northeast =
                opposite[pixel_index(width, x + 1, y - 1)] -
                planes.g[pixel_index(width, x + 1, y - 1)];
            const difference_southwest =
                opposite[pixel_index(width, x - 1, y + 1)] -
                planes.g[pixel_index(width, x - 1, y + 1)];
            const difference_southeast =
                opposite[pixel_index(width, x + 1, y + 1)] -
                planes.g[pixel_index(width, x + 1, y + 1)];
            const diagonal_p =
                (northwest_gradient * difference_southeast +
                    southeast_gradient * difference_northwest) /
                (northwest_gradient + southeast_gradient);
            const diagonal_q =
                (northeast_gradient * difference_southwest +
                    southwest_gradient * difference_northeast) /
                (northeast_gradient + southwest_gradient);
            opposite[index] = @max(
                0,
                planes.g[index] + interpolate(direction, diagonal_q, diagonal_p),
            );
        }
    }

    // Step 4.3: Reconstruct both chroma channels at green sites from cardinal
    // color differences using the same vertical/horizontal discriminator.
    y = radius;
    while (y < height - radius) : (y += 1) {
        var x: u32 = radius;
        while (x < width - radius) : (x += 1) {
            if (site_color(cfa, x, y) != .green) continue;
            const index = pixel_index(width, x, y);
            const green_center = planes.g[index];
            const direction = refined_direction(direction_vh, width, x, y);
            for ([_][]f32{ planes.r, planes.b }) |channel| {
                const north_gradient = epsilon +
                    @abs(green_center - planes.g[pixel_index(width, x, y - 2)]) +
                    @abs(channel[pixel_index(width, x, y - 1)] -
                        channel[pixel_index(width, x, y + 1)]) +
                    @abs(channel[pixel_index(width, x, y - 1)] -
                        channel[pixel_index(width, x, y - 3)]);
                const south_gradient = epsilon +
                    @abs(green_center - planes.g[pixel_index(width, x, y + 2)]) +
                    @abs(channel[pixel_index(width, x, y - 1)] -
                        channel[pixel_index(width, x, y + 1)]) +
                    @abs(channel[pixel_index(width, x, y + 1)] -
                        channel[pixel_index(width, x, y + 3)]);
                const west_gradient = epsilon +
                    @abs(green_center - planes.g[pixel_index(width, x - 2, y)]) +
                    @abs(channel[pixel_index(width, x - 1, y)] -
                        channel[pixel_index(width, x + 1, y)]) +
                    @abs(channel[pixel_index(width, x - 1, y)] -
                        channel[pixel_index(width, x - 3, y)]);
                const east_gradient = epsilon +
                    @abs(green_center - planes.g[pixel_index(width, x + 2, y)]) +
                    @abs(channel[pixel_index(width, x - 1, y)] -
                        channel[pixel_index(width, x + 1, y)]) +
                    @abs(channel[pixel_index(width, x + 1, y)] -
                        channel[pixel_index(width, x + 3, y)]);
                const difference_north = channel[pixel_index(width, x, y - 1)] -
                    planes.g[pixel_index(width, x, y - 1)];
                const difference_south = channel[pixel_index(width, x, y + 1)] -
                    planes.g[pixel_index(width, x, y + 1)];
                const difference_west = channel[pixel_index(width, x - 1, y)] -
                    planes.g[pixel_index(width, x - 1, y)];
                const difference_east = channel[pixel_index(width, x + 1, y)] -
                    planes.g[pixel_index(width, x + 1, y)];
                const vertical =
                    (north_gradient * difference_south +
                        south_gradient * difference_north) /
                    (north_gradient + south_gradient);
                const horizontal =
                    (east_gradient * difference_west +
                        west_gradient * difference_east) /
                    (east_gradient + west_gradient);
                channel[index] = @max(
                    0,
                    green_center + interpolate(direction, horizontal, vertical),
                );
            }
        }
    }

    for ([_][]const f32{ planes.r, planes.g, planes.b }) |plane| {
        for (plane) |value| assert(std.math.isFinite(value));
    }
}

fn pixel_index(width: u32, x: u32, y: u32) usize {
    return @as(usize, y) * width + x;
}

fn fetch_u32(values: []const f32, width: u32, x: u32, y: u32) f32 {
    const index = pixel_index(width, x, y);
    assert(index < values.len);
    return values[index];
}

fn squared(value: f32) f32 {
    return value * value;
}

fn interpolate(weight: f32, first: f32, second: f32) f32 {
    assert(weight >= 0);
    assert(weight <= 1);
    return weight * (first - second) + second;
}

fn refined_direction(values: []const f32, width: u32, x: u32, y: u32) f32 {
    const central = values[pixel_index(width, x, y)];
    const neighborhood = 0.25 *
        (values[pixel_index(width, x - 1, y - 1)] +
            values[pixel_index(width, x + 1, y - 1)] +
            values[pixel_index(width, x - 1, y + 1)] +
            values[pixel_index(width, x + 1, y + 1)]);
    return if (@abs(0.5 - central) < @abs(0.5 - neighborhood))
        neighborhood
    else
        central;
}

fn rcd_high_pass_vertical(
    mosaic: []const f32,
    width: u32,
    height: u32,
    x: u32,
    y: u32,
) f32 {
    const xi: i64 = x;
    const yi: i64 = y;
    return (fetch(mosaic, width, height, xi, yi - 3) -
        fetch(mosaic, width, height, xi, yi - 1) -
        fetch(mosaic, width, height, xi, yi + 1) +
        fetch(mosaic, width, height, xi, yi + 3)) -
        3 * (fetch(mosaic, width, height, xi, yi - 2) +
            fetch(mosaic, width, height, xi, yi + 2)) +
        6 * fetch(mosaic, width, height, xi, yi);
}

fn rcd_high_pass_horizontal(
    mosaic: []const f32,
    width: u32,
    height: u32,
    x: u32,
    y: u32,
) f32 {
    const xi: i64 = x;
    const yi: i64 = y;
    return (fetch(mosaic, width, height, xi - 3, yi) -
        fetch(mosaic, width, height, xi - 1, yi) -
        fetch(mosaic, width, height, xi + 1, yi) +
        fetch(mosaic, width, height, xi + 3, yi)) -
        3 * (fetch(mosaic, width, height, xi - 2, yi) +
            fetch(mosaic, width, height, xi + 2, yi)) +
        6 * fetch(mosaic, width, height, xi, yi);
}

fn rcd_high_pass_diagonal_p(
    mosaic: []const f32,
    width: u32,
    height: u32,
    x: u32,
    y: u32,
) f32 {
    const xi: i64 = x;
    const yi: i64 = y;
    return (fetch(mosaic, width, height, xi - 3, yi - 3) -
        fetch(mosaic, width, height, xi - 1, yi - 1) -
        fetch(mosaic, width, height, xi + 1, yi + 1) +
        fetch(mosaic, width, height, xi + 3, yi + 3)) -
        3 * (fetch(mosaic, width, height, xi - 2, yi - 2) +
            fetch(mosaic, width, height, xi + 2, yi + 2)) +
        6 * fetch(mosaic, width, height, xi, yi);
}

fn rcd_high_pass_diagonal_q(
    mosaic: []const f32,
    width: u32,
    height: u32,
    x: u32,
    y: u32,
) f32 {
    const xi: i64 = x;
    const yi: i64 = y;
    return (fetch(mosaic, width, height, xi + 3, yi - 3) -
        fetch(mosaic, width, height, xi + 1, yi - 1) -
        fetch(mosaic, width, height, xi - 1, yi + 1) +
        fetch(mosaic, width, height, xi - 3, yi + 3)) -
        3 * (fetch(mosaic, width, height, xi + 2, yi - 2) +
            fetch(mosaic, width, height, xi - 2, yi + 2)) +
        6 * fetch(mosaic, width, height, xi, yi);
}

fn site_color(comptime cfa: [4]dng.CfaColor, x: u32, y: u32) dng.CfaColor {
    return cfa[((y & 1) << 1) | (x & 1)];
}

/// Coordinate-clamped fetch: the border policy is clamp-to-edge.
fn fetch(mosaic: []const f32, width: u32, height: u32, x: i64, y: i64) f32 {
    const cx: u32 = @intCast(std.math.clamp(x, 0, @as(i64, width) - 1));
    const cy: u32 = @intCast(std.math.clamp(y, 0, @as(i64, height) - 1));
    return mosaic[@as(usize, cy) * width + cx];
}

fn neighbors_row(mosaic: []const f32, width: u32, x: u32, y: u32) f32 {
    const xi = @as(i64, x);
    // Height plays no role: same row. Clamp handles both edges.
    return 0.5 * (fetch(mosaic, width, std.math.maxInt(u32), xi - 1, y) +
        fetch(mosaic, width, std.math.maxInt(u32), xi + 1, y));
}

fn neighbors_column(mosaic: []const f32, width: u32, height: u32, x: u32, y: u32) f32 {
    const yi = @as(i64, y);
    return 0.5 * (fetch(mosaic, width, height, x, yi - 1) +
        fetch(mosaic, width, height, x, yi + 1));
}

fn neighbors_cross(mosaic: []const f32, width: u32, height: u32, x: u32, y: u32) f32 {
    const xi = @as(i64, x);
    const yi = @as(i64, y);
    return 0.25 * (fetch(mosaic, width, height, xi - 1, yi) +
        fetch(mosaic, width, height, xi + 1, yi) +
        fetch(mosaic, width, height, xi, yi - 1) +
        fetch(mosaic, width, height, xi, yi + 1));
}

fn neighbors_diagonal(mosaic: []const f32, width: u32, height: u32, x: u32, y: u32) f32 {
    const xi = @as(i64, x);
    const yi = @as(i64, y);
    return 0.25 * (fetch(mosaic, width, height, xi - 1, yi - 1) +
        fetch(mosaic, width, height, xi + 1, yi - 1) +
        fetch(mosaic, width, height, xi - 1, yi + 1) +
        fetch(mosaic, width, height, xi + 1, yi + 1));
}

// ---- tests -------------------------------------------------------------------

const test_ops_default = [_]Op{
    .{ .black_point = .{} },
    .{ .white_balance = .{} },
    .{ .demosaic = .{} },
    .{ .exposure = .{} },
    .{ .tone_curve = .{} },
    .{ .srgb_encode = .{} },
};

fn test_cancel_requested(context: ?*anyopaque) callconv(.c) i32 {
    assert(context == null);
    return 1;
}

fn test_sensor(gpa: std.mem.Allocator, width: u32, height: u32) !dng.SensorData {
    const bayer = try gpa.alloc(u16, width * height);
    for (bayer, 0..) |*s, i| {
        // A deterministic gradient with per-site variation; values inside
        // [black, white] so nothing clips.
        s.* = @intCast(1024 + (i * 331) % 14000);
    }
    return .{
        .width = width,
        .height = height,
        .cfa = .{ .red, .green, .green, .blue },
        .black_level = 1024,
        .white_level = 15360,
        .wb_neutral = .{ 0.6, 1.0, 0.8 },
        .bayer = bayer,
    };
}

test "RCD reference preserves samples and reduces neutral fine-fabric chroma" {
    // An odd-sized neutral weave near the CFA Nyquist limit exposes false
    // color immediately: the ground truth has identical RGB at every point,
    // so any reconstructed channel difference is an artifact.
    const gpa = std.testing.allocator;
    const width: u32 = 65;
    const height: u32 = 49;
    const cfa = [4]dng.CfaColor{ .red, .green, .green, .blue };
    const mosaic = try gpa.alloc(f32, @as(usize, width) * height);
    defer gpa.free(mosaic);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const weave = ((x + 2 * y) % 5) < 2;
            mosaic[pixel_index(width, x, y)] = if (weave) 0.78 else 0.22;
        }
    }

    var bilinear = try image.Planes.init(gpa, width, height);
    defer bilinear.deinit(gpa);
    demosaic_bilinear(cfa, mosaic, &bilinear);

    var rcd = try image.Planes.init(gpa, width, height);
    defer rcd.deinit(gpa);
    var scratch = std.heap.ArenaAllocator.init(gpa);
    defer scratch.deinit();
    try demosaic_rcd_reference(scratch.allocator(), cfa, mosaic, &rcd);

    var bilinear_chroma_sum: f64 = 0;
    var rcd_chroma_sum: f64 = 0;
    var sample_count: u32 = 0;
    y = 9;
    while (y < height - 9) : (y += 1) {
        var x: u32 = 9;
        while (x < width - 9) : (x += 1) {
            const index = pixel_index(width, x, y);
            bilinear_chroma_sum += @abs(bilinear.r[index] - bilinear.g[index]);
            bilinear_chroma_sum += @abs(bilinear.b[index] - bilinear.g[index]);
            rcd_chroma_sum += @abs(rcd.r[index] - rcd.g[index]);
            rcd_chroma_sum += @abs(rcd.b[index] - rcd.g[index]);
            sample_count += 2;

            switch (site_color(cfa, x, y)) {
                .red => try std.testing.expectEqual(mosaic[index], rcd.r[index]),
                .green => try std.testing.expectEqual(mosaic[index], rcd.g[index]),
                .blue => try std.testing.expectEqual(mosaic[index], rcd.b[index]),
            }
        }
    }
    try std.testing.expect(sample_count > 0);
    const bilinear_chroma_mean = bilinear_chroma_sum / sample_count;
    const rcd_chroma_mean = rcd_chroma_sum / sample_count;
    try std.testing.expect(rcd_chroma_mean < bilinear_chroma_mean);
}

test "RCD reference has finite deterministic borders for tiny and odd images" {
    const gpa = std.testing.allocator;
    const cfa = [4]dng.CfaColor{ .blue, .green, .green, .red };
    const dimensions = [_][2]u32{ .{ 7, 5 }, .{ 19, 17 }, .{ 33, 25 } };
    for (dimensions) |dimension| {
        const width = dimension[0];
        const height = dimension[1];
        const mosaic = try gpa.alloc(f32, @as(usize, width) * height);
        defer gpa.free(mosaic);
        for (mosaic, 0..) |*value, index| {
            value.* = @as(f32, @floatFromInt((index * 37) % 101)) / 100;
        }
        var first = try image.Planes.init(gpa, width, height);
        defer first.deinit(gpa);
        var second = try image.Planes.init(gpa, width, height);
        defer second.deinit(gpa);
        var first_scratch = std.heap.ArenaAllocator.init(gpa);
        defer first_scratch.deinit();
        var second_scratch = std.heap.ArenaAllocator.init(gpa);
        defer second_scratch.deinit();
        try demosaic_rcd_reference(first_scratch.allocator(), cfa, mosaic, &first);
        try demosaic_rcd_reference(second_scratch.allocator(), cfa, mosaic, &second);
        try std.testing.expectEqualSlices(f32, first.r, second.r);
        try std.testing.expectEqualSlices(f32, first.g, second.g);
        try std.testing.expectEqualSlices(f32, first.b, second.b);
        for ([_][]const f32{ first.r, first.g, first.b }) |plane| {
            for (plane) |value| try std.testing.expect(std.math.isFinite(value));
        }
    }
}

const DemosaicArtifactScene = enum {
    diagonal_lines,
    zipper_edge,
    maze_detail,
    color_edge,
    clipped_highlight,
    deep_shadow,
    saturated_edge,
};

test "RCD artifact suite covers structured edges shadows and clipped highlights" {
    // Each fixture starts as known linear RGB, is sampled through an RGGB CFA,
    // and is reconstructed independently. The gate is deliberately objective:
    // RCD must improve aggregate interior RGB error over the diagnostic
    // bilinear implementation while preserving finite bounded output.
    const gpa = std.testing.allocator;
    const width: u32 = 67;
    const height: u32 = 51;
    const cfa = [4]dng.CfaColor{ .red, .green, .green, .blue };
    const scenes = [_]DemosaicArtifactScene{
        .diagonal_lines,
        .zipper_edge,
        .maze_detail,
        .color_edge,
        .clipped_highlight,
        .deep_shadow,
        .saturated_edge,
    };
    var error_bilinear_total: f64 = 0;
    var error_rcd_total: f64 = 0;

    for (scenes) |scene| {
        const pixel_count = @as(usize, width) * height;
        const mosaic = try gpa.alloc(f32, pixel_count);
        defer gpa.free(mosaic);
        const reference = try gpa.alloc([3]f32, pixel_count);
        defer gpa.free(reference);
        artifact_scene_sample(scene, cfa, mosaic, reference, width, height);

        var bilinear = try image.Planes.init(gpa, width, height);
        defer bilinear.deinit(gpa);
        demosaic_bilinear(cfa, mosaic, &bilinear);
        var rcd = try image.Planes.init(gpa, width, height);
        defer rcd.deinit(gpa);
        var scratch = std.heap.ArenaAllocator.init(gpa);
        defer scratch.deinit();
        try demosaic_rcd_reference(scratch.allocator(), cfa, mosaic, &rcd);

        var y: u32 = 9;
        while (y < height - 9) : (y += 1) {
            var x: u32 = 9;
            while (x < width - 9) : (x += 1) {
                const index = pixel_index(width, x, y);
                const expected = reference[index];
                const actual_bilinear = [3]f32{
                    bilinear.r[index], bilinear.g[index], bilinear.b[index],
                };
                const actual_rcd = [3]f32{ rcd.r[index], rcd.g[index], rcd.b[index] };
                for (actual_bilinear, actual_rcd, expected) |linear, ratio, target| {
                    error_bilinear_total += squared(linear - target);
                    error_rcd_total += squared(ratio - target);
                    try std.testing.expect(std.math.isFinite(ratio));
                    try std.testing.expect(ratio >= 0);
                }
            }
        }
    }
    try std.testing.expect(error_bilinear_total > 0);
    try std.testing.expect(error_rcd_total < error_bilinear_total);
}

fn artifact_scene_sample(
    scene: DemosaicArtifactScene,
    comptime cfa: [4]dng.CfaColor,
    mosaic: []f32,
    reference: [][3]f32,
    width: u32,
    height: u32,
) void {
    assert(mosaic.len == @as(usize, width) * height);
    assert(reference.len == mosaic.len);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const index = pixel_index(width, x, y);
            const rgb = artifact_scene_rgb(scene, x, y, width, height);
            reference[index] = rgb;
            mosaic[index] = rgb[@intFromEnum(site_color(cfa, x, y))];
        }
    }
}

fn artifact_scene_rgb(
    scene: DemosaicArtifactScene,
    x: u32,
    y: u32,
    width: u32,
    height: u32,
) [3]f32 {
    assert(x < width);
    assert(y < height);
    return switch (scene) {
        .diagonal_lines => blk: {
            const light: f32 = if ((x + 2 * y) % 11 < 4) 0.82 else 0.18;
            break :blk @splat(light);
        },
        .zipper_edge => blk: {
            const boundary = width / 2 + @as(u32, @intFromBool(y % 4 >= 2));
            const light: f32 = if (x < boundary) 0.12 else 0.88;
            break :blk @splat(light);
        },
        .maze_detail => blk: {
            const cell_x = x / 3;
            const cell_y = y / 3;
            const light: f32 = if ((cell_x ^ cell_y) & 1 == 0) 0.72 else 0.28;
            break :blk @splat(light);
        },
        .color_edge => if (x + y < (width + height) / 2)
            .{ 0.78, 0.24, 0.12 }
        else
            .{ 0.08, 0.52, 0.88 },
        .clipped_highlight => blk: {
            const center_x = width / 2;
            const center_y = height / 2;
            const distance = @abs(@as(i64, x) - center_x) +
                @abs(@as(i64, y) - center_y);
            if (distance < 7) break :blk .{ 1, 1, 1 };
            if (distance < 12) break :blk .{ 1, 0.92, 0.78 };
            break :blk .{ 0.16, 0.20, 0.24 };
        },
        .deep_shadow => blk: {
            const level: f32 = if ((x + y * 3) % 9 < 4) 0.012 else 0.035;
            break :blk .{ level * 0.9, level, level * 1.1 };
        },
        .saturated_edge => if (x < width / 2)
            .{ 1, 0.12, 0.04 }
        else
            .{ 0.02, 0.18, 1 },
    };
}

test "per-site black and white levels normalize each CFA site independently" {
    const source = [4]u16{ 60, 120, 180, 240 };
    const black = [4]f32{ 10, 20, 30, 40 };
    const white = [4]f32{ 110, 220, 330, 440 };
    var target: [4]f32 = undefined;
    kernel_black_scale_sites(&target, &source, 2, 2, black, white);
    for (target) |value| try std.testing.expectApproxEqAbs(@as(f32, 0.5), value, 1e-6);
}

test "calibrated sensor cleanup is CFA-local bounded and has an exact off state" {
    const gpa = std.testing.allocator;
    const width: u32 = 10;
    const height: u32 = 10;
    const cfa = [4]dng.CfaColor{ .red, .green, .green, .blue };
    var mosaic: [width * height]f32 = @splat(0.2);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const site = (y & 1) * 2 + (x & 1);
            if (site == 1) mosaic[pixel_index(width, x, y)] = 1.01;
            if (site == 2) mosaic[pixel_index(width, x, y)] = 0.99;
        }
    }
    kernel_green_equalize(&mosaic, width, height, cfa);
    try std.testing.expectApproxEqAbs(mosaic[1], mosaic[width], 0.0002);
    try std.testing.expect(mosaic[1] >= 0.98);
    try std.testing.expect(mosaic[width] <= 1.02);

    const hot_index = pixel_index(width, 4, 4);
    mosaic[hot_index] = 0.95;
    const before_off = mosaic;
    var scratch_off = std.heap.ArenaAllocator.init(gpa);
    defer scratch_off.deinit();
    try kernel_hot_pixel_cleanup(scratch_off.allocator(), &mosaic, width, height, 0);
    try std.testing.expectEqualSlices(f32, &before_off, &mosaic);

    var scratch_on = std.heap.ArenaAllocator.init(gpa);
    defer scratch_on.deinit();
    try kernel_hot_pixel_cleanup(scratch_on.allocator(), &mosaic, width, height, 100);
    try std.testing.expectApproxEqAbs(@as(f32, 0.2), mosaic[hot_index], 1e-6);
    try std.testing.expectEqual(before_off[hot_index - 1], mosaic[hot_index - 1]);
}

test "v5 isolated sensor cleanup repairs bright and dark defects" {
    const gpa = std.testing.allocator;
    const width: u32 = 10;
    const height: u32 = 10;
    var mosaic: [width * height]f32 = @splat(0.35);
    const bright_index = pixel_index(width, 4, 4);
    const dark_index = pixel_index(width, 5, 5);
    mosaic[bright_index] = 0.95;
    mosaic[dark_index] = 0.01;

    var scratch = std.heap.ArenaAllocator.init(gpa);
    defer scratch.deinit();
    try kernel_isolated_pixel_cleanup_v2(
        scratch.allocator(),
        &mosaic,
        width,
        height,
        0,
    );

    try std.testing.expectApproxEqAbs(@as(f32, 0.35), mosaic[bright_index], 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 0.35), mosaic[dark_index], 1e-6);
    try std.testing.expectEqual(@as(f32, 0.35), mosaic[bright_index - 1]);
}

test "anti-color-alias strength zero is identity and one suppresses chroma" {
    const gpa = std.testing.allocator;
    const width: u32 = 17;
    const height: u32 = 13;
    var planes = try image.Planes.init(gpa, width, height);
    defer planes.deinit(gpa);
    @memset(planes.g, 0.5);
    @memset(planes.b, 0.5);
    for (planes.r, 0..) |*value, index| {
        value.* = if (index & 1 == 0) 0.1 else 0.9;
    }
    const original = try gpa.dupe(f32, planes.r);
    defer gpa.free(original);
    var scratch_off = std.heap.ArenaAllocator.init(gpa);
    defer scratch_off.deinit();
    try kernel_chroma_lowpass_calibrated(
        scratch_off.allocator(),
        &planes,
        0,
        @splat(1),
        true,
    );
    try std.testing.expectEqualSlices(f32, original, planes.r);

    var scratch_on = std.heap.ArenaAllocator.init(gpa);
    defer scratch_on.deinit();
    try kernel_chroma_lowpass_calibrated(
        scratch_on.allocator(),
        &planes,
        1,
        @splat(1),
        true,
    );
    var residual_before: f64 = 0;
    var residual_after: f64 = 0;
    for (original, planes.r) |before, after| {
        residual_before += @abs(before - 0.5);
        residual_after += @abs(after - 0.5);
    }
    try std.testing.expect(residual_after < residual_before);

    // A sustained colour step is not alternating CFA false colour and must
    // remain exact, including the pixels nearest the boundary.
    for (planes.r, 0..) |*value, index| {
        value.* = if (index % width < width / 2) 0.2 else 0.8;
    }
    const color_edge = try gpa.dupe(f32, planes.r);
    defer gpa.free(color_edge);
    try kernel_chroma_lowpass_calibrated(gpa, &planes, 1, @splat(1), false);
    try std.testing.expectEqualSlices(f32, color_edge, planes.r);

    // Coherent low-amplitude colour over luminance texture is subject colour,
    // not neutral moire. The v5 classifier must preserve it exactly.
    for (planes.g, planes.r, planes.b, 0..) |*green, *red, *blue, index| {
        green.* = if (index & 1 == 0) 0.42 else 0.58;
        red.* = green.* + 0.08;
        blue.* = green.* - 0.04;
    }
    const coherent_red = try gpa.dupe(f32, planes.r);
    defer gpa.free(coherent_red);
    const coherent_blue = try gpa.dupe(f32, planes.b);
    defer gpa.free(coherent_blue);
    try kernel_chroma_lowpass_calibrated(gpa, &planes, 1, @splat(1), false);
    try std.testing.expectEqualSlices(f32, coherent_red, planes.r);
    try std.testing.expectEqualSlices(f32, coherent_blue, planes.b);
}

test "render is deterministic: two runs, identical bytes" {
    const gpa = std.testing.allocator;
    var sensor = try test_sensor(gpa, 23, 17);
    defer sensor.deinit(gpa);
    const recipe = Recipe{ .ops = &test_ops_default };

    var first = try render(gpa, &sensor, recipe, .{});
    defer first.deinit(gpa);
    var second = try render(gpa, &sensor, recipe, .{});
    defer second.deinit(gpa);
    try std.testing.expectEqualSlices(u8, first.rgba, second.rgba);
}

test "downsampled render is deterministic and sized by the longest edge" {
    const gpa = std.testing.allocator;
    var sensor = try test_sensor(gpa, 37, 23);
    defer sensor.deinit(gpa);
    const recipe = Recipe{ .ops = &test_ops_default };

    var first = try render(gpa, &sensor, recipe, .{ .edge_px_max_out = 16 });
    defer first.deinit(gpa);
    var second = try render(gpa, &sensor, recipe, .{ .edge_px_max_out = 16 });
    defer second.deinit(gpa);

    // Longest edge maps to the bound exactly; the short edge scales down
    // in proportion: 23 * 16 / 37 = 9 (floor).
    try std.testing.expectEqual(@as(u32, 16), first.width);
    try std.testing.expectEqual(@as(u32, 9), first.height);
    try std.testing.expectEqualSlices(u8, first.rgba, second.rgba);

    // A bound at or above the longest edge is a no-op (negative space).
    var full = try render(gpa, &sensor, recipe, .{ .edge_px_max_out = 37 });
    defer full.deinit(gpa);
    try std.testing.expectEqual(@as(u32, 37), full.width);
    try std.testing.expectEqual(@as(u32, 23), full.height);
}

test "preview level may undershoot its edge bound by at most five percent" {
    try std.testing.expectEqual(@as(u32, 4), preview_factor(5472, 1440));
    try std.testing.expectEqual(@as(u32, 4), preview_factor(5472, 1024));
    try std.testing.expectEqual(@as(u32, 10), preview_factor(5472, 512));
    try std.testing.expectEqual(@as(u32, 0), preview_factor(1440, 1440));
}

test "engine v2 applies default crop and orientation before preview sizing" {
    const gpa = std.testing.allocator;
    const sensor = try test_sensor(gpa, 10, 8);
    var raw = dng.DecodedRaw{
        .sensor = sensor,
        .metadata = .{
            .width = 10,
            .height = 8,
            .compression = .none,
            .cfa = sensor.cfa,
            .black_level = sensor.black_level,
            .white_level = sensor.white_level,
            .wb_neutral = sensor.wb_neutral,
            .orientation = .rotate_90_clockwise,
            .active_area = .{ .x = 1, .y = 1, .width = 8, .height = 6 },
            .default_crop = .{ .x = 1, .y = 1, .width = 6, .height = 4 },
            .color_matrix_1 = color.Mat3.identity.values,
            .calibration_illuminant_1 = 23,
        },
    };
    defer raw.deinit(gpa);
    const recipe = Recipe{ .engine_version = 2, .ops = &test_ops_default };

    var full = try render_decoded(gpa, &raw, recipe, .{});
    defer full.deinit(gpa);
    var repeated = try render_decoded(gpa, &raw, recipe, .{});
    defer repeated.deinit(gpa);
    try std.testing.expectEqual(@as(u32, 4), full.width);
    try std.testing.expectEqual(@as(u32, 6), full.height);
    try std.testing.expectEqualSlices(u8, full.rgba, repeated.rgba);

    var preview = try render_decoded(gpa, &raw, recipe, .{ .edge_px_max_out = 3 });
    defer preview.deinit(gpa);
    try std.testing.expectEqual(@as(u32, 2), preview.width);
    try std.testing.expectEqual(@as(u32, 3), preview.height);

    var late_ops = test_ops_default;
    late_ops[3] = .{ .exposure = .{ .ev = 1.25 } };
    late_ops[4] = .{ .tone_curve = .{ .contrast = 0.8 } };
    var linear_neutral = try render_linear_decoded(
        gpa,
        &raw,
        recipe,
        .{ .edge_px_max_out = 3 },
    );
    defer linear_neutral.deinit(gpa);
    var linear_late_edit = try render_linear_decoded(
        gpa,
        &raw,
        .{ .engine_version = 2, .ops = &late_ops },
        .{ .edge_px_max_out = 3 },
    );
    defer linear_late_edit.deinit(gpa);
    try std.testing.expectEqual(@as(u32, 2), linear_neutral.width);
    try std.testing.expectEqual(@as(u32, 3), linear_neutral.height);
    try std.testing.expectEqualSlices(f32, linear_neutral.rgba, linear_late_edit.rgba);
    const memory_bytes_max = render_linear_memory_bytes_max(&raw, 3);
    try std.testing.expect(memory_bytes_max > 0);
    const calibrated_memory_bytes_max = render_linear_memory_bytes_max_internal(
        &raw,
        3,
        true,
    );
    try std.testing.expect(calibrated_memory_bytes_max > memory_bytes_max);
    try std.testing.expectError(error.OutOfMemory, render_linear_decoded(
        gpa,
        &raw,
        recipe,
        .{ .edge_px_max_out = 3, .memory_budget_bytes = memory_bytes_max - 1 },
    ));
    try std.testing.expectError(error.Cancelled, render_linear_decoded(
        gpa,
        &raw,
        recipe,
        .{ .cancellation = .{ .callback = test_cancel_requested } },
    ));
    try std.testing.expectError(error.OutOfMemory, render_linear_decoded(
        gpa,
        &raw,
        .{ .engine_version = 3, .ops = &test_ops_default },
        .{
            .edge_px_max_out = 3,
            .memory_budget_bytes = calibrated_memory_bytes_max - 1,
            .reconstruction = .{ .enabled = true },
        },
    ));
    for (linear_neutral.rgba, 0..) |value, i| {
        try std.testing.expect(std.math.isFinite(value));
        if (i % 4 == 3) try std.testing.expectEqual(@as(f32, 1), value);
    }

    var early_ops = test_ops_default;
    early_ops[1] = .{ .white_balance = .{
        .as_shot = false,
        .gain_r = 1.2,
        .gain_g = 1,
        .gain_b = 0.8,
    } };
    var linear_early_edit = try render_linear_decoded(
        gpa,
        &raw,
        .{ .engine_version = 2, .ops = &early_ops },
        .{ .edge_px_max_out = 3 },
    );
    defer linear_early_edit.deinit(gpa);
    try std.testing.expect(!std.mem.eql(f32, linear_neutral.rgba, linear_early_edit.rgba));
}

test "engine v3 calibrated reconstruction is explicit and leaves v2 frozen" {
    const gpa = std.testing.allocator;
    const sensor = try test_sensor(gpa, 33, 25);
    var raw = dng.DecodedRaw{
        .sensor = sensor,
        .metadata = .{
            .width = 33,
            .height = 25,
            .compression = .none,
            .cfa = sensor.cfa,
            .black_level = sensor.black_level,
            .white_level = sensor.white_level,
            .wb_neutral = sensor.wb_neutral,
            .orientation = .normal,
            .active_area = .{ .x = 0, .y = 0, .width = 33, .height = 25 },
            .default_crop = .{ .x = 0, .y = 0, .width = 33, .height = 25 },
            .color_matrix_1 = color.Mat3.identity.values,
            .calibration_illuminant_1 = 23,
        },
    };
    defer raw.deinit(gpa);
    const legacy_recipe = Recipe{ .engine_version = 2, .ops = &test_ops_default };
    var legacy_first = try render_decoded(gpa, &raw, legacy_recipe, .{});
    defer legacy_first.deinit(gpa);
    var calibrated = try render_decoded(
        gpa,
        &raw,
        .{ .engine_version = 3, .ops = &test_ops_default },
        .{ .reconstruction = .{
            .enabled = true,
            .adaptive_green_enabled = true,
            .hot_pixel_cleanup_amount = 10,
            .anti_color_aliasing_strength = 0.5,
            .highlight_recovery_start = highlight_recovery_start_bootstrap,
        } },
    );
    defer calibrated.deinit(gpa);
    var legacy_second = try render_decoded(gpa, &raw, legacy_recipe, .{});
    defer legacy_second.deinit(gpa);

    try std.testing.expectEqualSlices(u8, legacy_first.rgba, legacy_second.rgba);
    try std.testing.expect(!std.mem.eql(u8, legacy_first.rgba, calibrated.rgba));
    try std.testing.expectEqual(legacy_first.width, calibrated.width);
    try std.testing.expectEqual(legacy_first.height, calibrated.height);

    var calibrated_preview = try render_decoded(
        gpa,
        &raw,
        .{ .engine_version = 3, .ops = &test_ops_default },
        .{
            .edge_px_max_out = 16,
            .reconstruction = .{
                .enabled = true,
                .adaptive_green_enabled = true,
                .hot_pixel_cleanup_amount = 10,
                .anti_color_aliasing_strength = 0.5,
                .highlight_recovery_start = highlight_recovery_start_bootstrap,
            },
        },
    );
    defer calibrated_preview.deinit(gpa);
    try std.testing.expectEqual(@as(u32, 16), calibrated_preview.width);
    try std.testing.expectEqual(@as(u32, 12), calibrated_preview.height);
}

test "box downsample bins tile the source and average exactly" {
    // 4 wide -> 2 wide, 2 tall -> 1 tall: each output pixel is the mean of
    // a 2x2 bin, checked by hand.
    const source = [_]f32{
        1, 3, 5,  7,
        2, 4, 10, 12,
    };
    var target: [2]f32 = undefined;
    var row_sum: [4]f32 = undefined;
    kernel_box_downsample(&target, 2, 1, &source, 4, 2, &row_sum);
    try std.testing.expectEqual(@as(f32, 2.5), target[0]);
    try std.testing.expectEqual(@as(f32, 8.5), target[1]);

    // Non-divisible bins: 5 -> 2 splits as [0,2) and [2,5); a constant
    // field must stay constant regardless of bin widths.
    const flat = [_]f32{ 0.25, 0.25, 0.25, 0.25, 0.25 };
    var uneven: [2]f32 = undefined;
    var scratch: [5]f32 = undefined;
    kernel_box_downsample(&uneven, 2, 1, &flat, 5, 1, &scratch);
    try std.testing.expectEqual(@as(f32, 0.25), uneven[0]);
    try std.testing.expectEqual(@as(f32, 0.25), uneven[1]);
}

test "v2 highlight recovery is neutral below sensor white" {
    var r = [_]f32{ 0.8, 2.0, 1.9 };
    var g = [_]f32{ 0.7, 1.0, 0.95 };
    var b = [_]f32{ 0.6, 1.5, 1.425 };
    var planes = image.Planes{
        .width = 3,
        .height = 1,
        .r = &r,
        .g = &g,
        .b = &b,
    };
    kernel_highlight_recovery_balanced(&planes, .{ 2, 1, 1.5 }, 0.8);

    // Nothing below 80% of the sensor range changes.
    try std.testing.expectEqual(@as(f32, 0.8), r[0]);
    try std.testing.expectEqual(@as(f32, 0.7), g[0]);
    try std.testing.expectEqual(@as(f32, 0.6), b[0]);
    // A fully clipped neutral converges to its surviving common value.
    try std.testing.expectEqual(@as(f32, 1), r[1]);
    try std.testing.expectEqual(@as(f32, 1), g[1]);
    try std.testing.expectEqual(@as(f32, 1), b[1]);
    // Recovery ramps continuously through the final 10%.
    try std.testing.expectApproxEqAbs(@as(f32, 1.1875), r[2], 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 0.95), g[2], 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 1.06875), b[2], 1e-6);
}

test "v2 unbalanced DNG highlight recovery follows AsShotNeutral" {
    var r = [_]f32{ 0.4, 1.0, 1.0 };
    var g = [_]f32{ 0.7, 1.0, 0.2 };
    var b = [_]f32{ 0.5, 1.0, 0.1 };
    var planes = image.Planes{
        .width = 3,
        .height = 1,
        .r = &r,
        .g = &g,
        .b = &b,
    };
    kernel_highlight_recovery_unbalanced(&planes, .{ 0.5, 1, 0.75 }, 0.8);

    try std.testing.expectEqual(@as(f32, 0.4), r[0]);
    try std.testing.expectEqual(@as(f32, 0.7), g[0]);
    try std.testing.expectEqual(@as(f32, 0.5), b[0]);
    try std.testing.expectEqual(@as(f32, 0.5), r[1]);
    try std.testing.expectEqual(@as(f32, 1), g[1]);
    try std.testing.expectEqual(@as(f32, 0.75), b[1]);
    // One legitimately saturated colour channel is not a neutral highlight.
    try std.testing.expectEqual(@as(f32, 1), r[2]);
    try std.testing.expectEqual(@as(f32, 0.2), g[2]);
    try std.testing.expectEqual(@as(f32, 0.1), b[2]);
}

test "calibrated highlight headroom starts at the recovered clip safety point" {
    var r = [_]f32{ 1.93, 2 };
    var g = [_]f32{ 0.965, 1 };
    var b = [_]f32{ 1.4475, 1.5 };
    var planes = image.Planes{
        .width = 2,
        .height = 1,
        .r = &r,
        .g = &g,
        .b = &b,
    };
    kernel_highlight_recovery_balanced(
        &planes,
        .{ 2, 1, 1.5 },
        highlight_recovery_start_bootstrap,
    );

    // Per-channel sensor values at 0.965 remain bit-identical, while a sensor
    // white shared by all three channels converges to a neutral recoverable
    // value. CFA-site white normalization is covered independently above.
    try std.testing.expectEqual(@as(f32, 1.93), r[0]);
    try std.testing.expectEqual(@as(f32, 0.965), g[0]);
    try std.testing.expectEqual(@as(f32, 1.4475), b[0]);
    try std.testing.expectEqual(@as(f32, 1), r[1]);
    try std.testing.expectEqual(@as(f32, 1), g[1]);
    try std.testing.expectEqual(@as(f32, 1), b[1]);
}

test "a flat grey field survives the pipeline as flat grey" {
    const gpa = std.testing.allocator;
    const bayer = try gpa.alloc(u16, 16 * 16);
    // Mid-grey after black subtraction; neutral of 1s so WB is identity.
    @memset(bayer, 8192);
    var sensor = dng.SensorData{
        .width = 16,
        .height = 16,
        .cfa = .{ .red, .green, .green, .blue },
        .black_level = 0,
        .white_level = 16384,
        .wb_neutral = .{ 1, 1, 1 },
        .bayer = bayer,
    };
    defer sensor.deinit(gpa);

    var out = try render(gpa, &sensor, .{ .ops = &test_ops_default }, .{});
    defer out.deinit(gpa);

    // Every pixel identical, r == g == b, and alpha opaque: demosaic of a
    // constant field must not invent structure.
    const first = out.rgba[0];
    for (0..(16 * 16)) |i| {
        try std.testing.expectEqual(first, out.rgba[i * 4 + 0]);
        try std.testing.expectEqual(first, out.rgba[i * 4 + 1]);
        try std.testing.expectEqual(first, out.rgba[i * 4 + 2]);
        try std.testing.expectEqual(@as(u8, 255), out.rgba[i * 4 + 3]);
    }
    // linear 0.5 → sRGB ≈ 188.
    try std.testing.expectEqual(@as(u8, 188), first);
}

test "stack validation rejects malformed recipes (negative space)" {
    const gpa = std.testing.allocator;
    var sensor = try test_sensor(gpa, 8, 8);
    defer sensor.deinit(gpa);

    const no_demosaic = [_]Op{
        .{ .black_point = .{} }, .{ .exposure = .{} }, .{ .srgb_encode = .{} },
    };
    try std.testing.expectError(
        error.InvalidRecipe,
        render(gpa, &sensor, .{ .ops = &no_demosaic }, .{}),
    );

    const wb_after_demosaic = [_]Op{
        .{ .black_point = .{} },   .{ .demosaic = .{} },
        .{ .white_balance = .{} }, .{ .srgb_encode = .{} },
    };
    try std.testing.expectError(
        error.InvalidRecipe,
        render(gpa, &sensor, .{ .ops = &wb_after_demosaic }, .{}),
    );

    try std.testing.expectError(
        error.UnsupportedEngineVersion,
        render(gpa, &sensor, .{ .engine_version = 2, .ops = &test_ops_default }, .{}),
    );

    const raw = dng.DecodedRaw{
        .sensor = sensor,
        .metadata = undefined,
    };
    try std.testing.expectError(
        error.UnsupportedEngineVersion,
        render_decoded(
            gpa,
            &raw,
            .{ .engine_version = 6, .ops = &test_ops_default },
            .{},
        ),
    );
}

test "engine v4 profile is selectable and precedes creative late develop" {
    const gpa = std.testing.allocator;
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "tests/corpus/phase2b/canon-r3-emerald-fabric.dng",
        gpa,
        std.Io.Limit.limited(64 * 1024 * 1024),
    );
    defer gpa.free(bytes);
    var raw = try dng.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    var mft2 = try database.loadMft2(
        gpa,
        "profile.capture-one.CanonEOSR3-ProStandard.v1",
    );
    defer mft2.deinit(gpa);
    const profile = try icc_profile.Profile.init(&mft2);
    const reconstruction = ReconstructionDefaults{
        .enabled = true,
        .adaptive_green_enabled = true,
        .hot_pixel_cleanup_amount = 0,
        .anti_color_aliasing_strength = 1,
        .highlight_recovery_start = highlight_recovery_start_bootstrap,
    };
    const profile_recipe = Recipe{
        .engine_version = 4,
        .camera_profile = .resolved_nonlinear,
        .ops = &test_ops_default,
    };
    var profiled = try render_linear_decoded(gpa, &raw, profile_recipe, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = profile },
    });
    defer profiled.deinit(gpa);
    var matrix = try render_linear_decoded(gpa, &raw, .{
        .engine_version = 4,
        .camera_profile = .technical_matrix,
        .ops = &test_ops_default,
    }, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .technical_matrix,
    });
    defer matrix.deinit(gpa);
    try std.testing.expect(!std.mem.eql(f32, profiled.rgba, matrix.rgba));

    const late_ops = [_]Op{
        .{ .black_point = .{} },
        .{ .white_balance = .{} },
        .{ .demosaic = .{} },
        .{ .exposure = .{ .ev = 0.75 } },
        .{ .tone_curve = .{ .contrast = 0.4 } },
        .{ .srgb_encode = .{} },
    };
    var retained_after_late_edit = try render_linear_decoded(gpa, &raw, .{
        .engine_version = 4,
        .camera_profile = .resolved_nonlinear,
        .ops = &late_ops,
    }, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = profile },
    });
    defer retained_after_late_edit.deinit(gpa);
    try std.testing.expectEqualSlices(f32, profiled.rgba, retained_after_late_edit.rgba);

    var developed = try render_decoded(gpa, &raw, .{
        .engine_version = 4,
        .camera_profile = .resolved_nonlinear,
        .ops = &late_ops,
    }, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = profile },
    });
    defer developed.deinit(gpa);
    var neutral = try render_decoded(gpa, &raw, profile_recipe, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = profile },
    });
    defer neutral.deinit(gpa);
    try std.testing.expect(!std.mem.eql(u8, developed.rgba, neutral.rgba));
}

test "engine v5 film default is selectable and precedes user develop" {
    const gpa = std.testing.allocator;
    const bytes = try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "tests/corpus/phase2b/canon-r3-emerald-fabric.dng",
        gpa,
        std.Io.Limit.limited(64 * 1024 * 1024),
    );
    defer gpa.free(bytes);
    var raw = try dng.decode_raw(gpa, bytes);
    defer raw.deinit(gpa);
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    var mft2 = try database.loadMft2(
        gpa,
        "profile.capture-one.CanonEOSR3-ProStandard.v1",
    );
    defer mft2.deinit(gpa);
    const camera_profile = try icc_profile.Profile.init(&mft2);
    const curve_record = try database.loadFilmCurve(
        "curve.capture-one.CanonEOSR3-Auto.v1",
    );
    const curve_profile = try film_curve.Profile.init(&curve_record);
    const reconstruction = ReconstructionDefaults{
        .enabled = true,
        .adaptive_green_enabled = true,
        .hot_pixel_cleanup_amount = 0,
        .anti_color_aliasing_strength = 1,
        .highlight_recovery_start = highlight_recovery_start_bootstrap,
    };
    const auto_rendering = film_curve.Rendering{ .capture_one_auto = .{
        .profile = &curve_profile,
        .base_gain = 1.07,
        .sensor_range_gain = 1,
    } };
    const auto_recipe = Recipe{
        .engine_version = 5,
        .camera_profile = .resolved_nonlinear,
        .film_curve = .capture_one_auto,
        .ops = &test_ops_default,
    };
    var auto = try render_linear_decoded(gpa, &raw, auto_recipe, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = camera_profile },
        .film_curve = auto_rendering,
    });
    defer auto.deinit(gpa);
    var linear = try render_linear_decoded(gpa, &raw, .{
        .engine_version = 5,
        .camera_profile = .resolved_nonlinear,
        .film_curve = .linear,
        .ops = &test_ops_default,
    }, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = camera_profile },
        .film_curve = .linear,
    });
    defer linear.deinit(gpa);
    try std.testing.expect(!std.mem.eql(f32, auto.rgba, linear.rgba));

    const late_ops = [_]Op{
        .{ .black_point = .{} },
        .{ .white_balance = .{} },
        .{ .demosaic = .{} },
        .{ .exposure = .{ .ev = 1.25 } },
        .{ .tone_curve = .{ .contrast = 0.75 } },
        .{ .srgb_encode = .{} },
    };
    var retained_after_edit = try render_linear_decoded(gpa, &raw, .{
        .engine_version = 5,
        .camera_profile = .resolved_nonlinear,
        .film_curve = .capture_one_auto,
        .ops = &late_ops,
    }, .{
        .edge_px_max_out = 64,
        .reconstruction = reconstruction,
        .camera_profile = .{ .nonlinear = camera_profile },
        .film_curve = auto_rendering,
    });
    defer retained_after_edit.deinit(gpa);
    try std.testing.expectEqualSlices(f32, auto.rgba, retained_after_edit.rgba);
}
