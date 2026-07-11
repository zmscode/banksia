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
const color = @import("color.zig");
const dng = @import("dng.zig");
const geometry = @import("geometry.zig");
const image = @import("image.zig");

/// Per-element asserts inside pixel loops run only when this is set: slow
/// assertions reduce fuzz coverage, so they must earn their keep.
const verify = builtin.mode == .Debug;

pub const engine_version_current: u32 = 1;
pub const engine_version_latest: u32 = 2;

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
    ops: []const Op,
};

pub const RenderOptions = struct {
    /// Longest edge of the output in pixels; 0 renders at sensor resolution.
    /// Smaller outputs render at full resolution first and then box
    /// downsample: correct and deterministic first. The subsampled-demosaic
    /// fast path is a Phase 6 optimization tested against this reference.
    edge_px_max_out: u32 = 0,
};

pub const Rendered = struct {
    width: u32,
    height: u32,
    /// Row-major RGBA8, `width * height * 4` bytes.
    rgba: []u8,

    pub fn deinit(self: *Rendered, gpa: std.mem.Allocator) void {
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
        1 => render(gpa, &raw.sensor, recipe, options),
        2 => {
            const color_transform = color.Transform.init(raw.metadata) catch {
                return error.InvalidColorMetadata;
            };
            return render_internal(
                gpa,
                &raw.sensor,
                recipe,
                options,
                geometry.Transform.init(raw.metadata),
                color_transform,
            );
        },
        else => error.UnsupportedEngineVersion,
    };
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

    for (0..ops.len) |i| {
        try op_apply(ops.get(i), sensor, mosaic, &planes, color_transform);
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

    if (width_out == output_planes.width and height_out == output_planes.height) {
        kernel_srgb_pack(rgba, output_planes.r, output_planes.g, output_planes.b);
    } else {
        const small = try planes_downsample(arena, &output_planes, width_out, height_out);
        kernel_srgb_pack(rgba, small.r, small.g, small.b);
    }

    assert(rgba.len == count_out * 4);
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
    op: Op,
    sensor: *const dng.SensorData,
    mosaic: []f32,
    planes: *image.Planes,
    color_transform: ?color.Transform,
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
        },
        .white_balance => {
            const wb = op.white_balance;
            if (color_transform == null or
                !wb.as_shot or
                color_transform.?.apply_as_shot_white_balance)
            {
                const gains = wb_gains(wb, sensor.wb_neutral);
                kernel_wb(mosaic, sensor.width, sensor.height, sensor.cfa, gains);
            }
        },
        .demosaic => {
            try demosaic_dispatch(sensor.cfa, mosaic, planes);
            if (color_transform) |value| value.camera_to_working(planes);
        },
        .exposure => {
            const gain = std.math.exp2(op.exposure.ev);
            for ([_][]f32{ planes.r, planes.g, planes.b }) |plane| {
                kernel_gain(plane, gain);
            }
        },
        .tone_curve => {
            const contrast = op.tone_curve.contrast;
            for ([_][]f32{ planes.r, planes.g, planes.b }) |plane| {
                kernel_tone_curve(plane, contrast);
            }
        },
        .srgb_encode => {}, // packing runs once, after the stack
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

test "per-site black and white levels normalize each CFA site independently" {
    const source = [4]u16{ 60, 120, 180, 240 };
    const black = [4]f32{ 10, 20, 30, 40 };
    const white = [4]f32{ 110, 220, 330, 440 };
    var target: [4]f32 = undefined;
    kernel_black_scale_sites(&target, &source, 2, 2, black, white);
    for (target) |value| try std.testing.expectApproxEqAbs(@as(f32, 0.5), value, 1e-6);
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
            .{ .engine_version = 3, .ops = &test_ops_default },
            .{},
        ),
    );
}
