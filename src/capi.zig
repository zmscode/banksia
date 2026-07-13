//! The C ABI: everything the shell may touch, and nothing else.
//!
//! Eleven exported functions, `bk_` prefixed, hand-documented in
//! `include/banksia.h` — the header changes in the same commit as this file,
//! and the header-sync test below holds the two together.
//!
//! Conventions across the boundary (plan.md, Phase 1):
//!
//! - Handles are opaque pointers; one engine handle = one thread. There is
//!   no internal locking: the Swift actor is the serialization point, and
//!   locks here would only hide misuse.
//! - Status functions return `i32`: 0 ok, negative code on failure, message
//!   via `bk_last_error`. Success clears the message. No Zig error unions
//!   and no panics cross the boundary; every `catch` becomes a code.
//! - The engine owns returned buffers: pixels from `bk_render` are valid
//!   until the next `bk_render` on the same handle or `bk_engine_destroy`.
//! - Debug builds run each engine on its own `DebugAllocator`; destroy
//!   asserts a clean leak report. That assert is the Phase 1 leak gate.

const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const emu = @import("emu");

const verify = builtin.mode == .Debug;

/// Codes mirror the BK_ERR_* defines in include/banksia.h.
const ok: i32 = 0;
const err_invalid_argument: i32 = -1;
const err_io: i32 = -2;
const err_decode: i32 = -3;
const err_recipe: i32 = -4;
const err_render: i32 = -5;
const err_no_raw: i32 = -6;
const err_out_of_memory: i32 = -7;
const err_cancelled: i32 = -8;

const error_message_bytes_max = 256;
const manifest_json_bytes_max = 16 * 1024;
const raw_bytes_max = std.Io.Limit.limited(512 * 1024 * 1024);

comptime {
    assert(manifest_json_bytes_max > error_message_bytes_max);
}

const DebugAllocator = std.heap.DebugAllocator(.{});

/// The opaque handle behind `bk_engine`. The engine struct itself lives on
/// the C allocator; everything the engine loads or renders lives on
/// `gpa` — the per-engine debug allocator in debug builds, so destroy can
/// audit every byte.
const Engine = struct {
    debug_allocator: if (verify) DebugAllocator else void,
    gpa: std.mem.Allocator,
    raw: ?emu.dng.DecodedRaw = null,
    recipe: ?std.json.Parsed(emu.pipeline.Recipe) = null,
    rendered: ?emu.pipeline.Rendered = null,
    linear_rendered: ?emu.pipeline.LinearRendered = null,
    resolved_calibration: ?emu.calibration.ResolvedCalibration = null,
    input_profile: ?emu.calibration.Mft2 = null,
    /// Always NUL-terminated; index error_message_bytes_max is the fence.
    last_error: [error_message_bytes_max + 1]u8,
    manifest_json: [manifest_json_bytes_max + 1]u8,
};

pub export fn bk_engine_create() ?*Engine {
    const engine = std.heap.c_allocator.create(Engine) catch return null;
    engine.* = .{
        .debug_allocator = if (verify) DebugAllocator.init else {},
        .gpa = undefined,
        .last_error = @splat(0),
        .manifest_json = @splat(0),
    };
    engine.gpa = if (verify) engine.debug_allocator.allocator() else std.heap.smp_allocator;
    return engine;
}

pub export fn bk_engine_destroy(engine_maybe: ?*Engine) void {
    const engine = engine_maybe orelse return;
    if (engine.raw) |*raw| raw.deinit(engine.gpa);
    if (engine.recipe) |*recipe| recipe.deinit();
    if (engine.rendered) |*rendered| rendered.deinit(engine.gpa);
    if (engine.linear_rendered) |*rendered| rendered.deinit(engine.gpa);
    if (engine.input_profile) |*profile| profile.deinit(engine.gpa);
    if (verify) {
        // The leak gate: every allocation made through this handle must be
        // gone. In release builds the report (and the assert) compile out.
        const report = engine.debug_allocator.deinit();
        assert(report == .ok);
    }
    std.heap.c_allocator.destroy(engine);
}

pub export fn bk_load_raw(engine_maybe: ?*Engine, path_maybe: ?[*:0]const u8) i32 {
    const engine = engine_maybe orelse return err_invalid_argument;
    const path = path_maybe orelse {
        return fail(engine, err_invalid_argument, "path is null", .{});
    };
    return load_raw(engine, std.mem.span(path));
}

pub export fn bk_raw_dimensions(
    engine_maybe: ?*Engine,
    width_out: ?*u32,
    height_out: ?*u32,
) i32 {
    const engine = engine_maybe orelse return err_invalid_argument;
    const width_ptr = width_out orelse {
        return fail(engine, err_invalid_argument, "width_out is null", .{});
    };
    const height_ptr = height_out orelse {
        return fail(engine, err_invalid_argument, "height_out is null", .{});
    };
    const raw = &(engine.raw orelse {
        return fail(engine, err_no_raw, "no raw loaded: bk_load_raw must succeed first", .{});
    });
    const dimensions = emu.geometry.Transform.init(raw.metadata).output_dimensions();
    assert(dimensions.width > 0);
    assert(dimensions.height > 0);
    width_ptr.* = dimensions.width;
    height_ptr.* = dimensions.height;
    return succeed(engine);
}

fn load_raw(engine: *Engine, path: []const u8) i32 {
    var threaded = std.Io.Threaded.init_single_threaded;
    const io = threaded.io();
    const blob = std.Io.Dir.cwd().readFileAlloc(io, path, engine.gpa, raw_bytes_max) catch |err|
        switch (err) {
            error.OutOfMemory => return fail(engine, err_out_of_memory, "out of memory", .{}),
            else => return fail(engine, err_io, "cannot read '{s}': {s}", .{
                path, @errorName(err),
            }),
        };
    defer engine.gpa.free(blob);

    const raw = emu.raw.decode_raw(engine.gpa, blob) catch |err| switch (err) {
        error.OutOfMemory => return fail(engine, err_out_of_memory, "out of memory", .{}),
        else => return fail(engine, err_decode, "cannot decode '{s}': {s}", .{
            path, @errorName(err),
        }),
    };
    if (engine.raw) |*old| old.deinit(engine.gpa);
    engine.raw = raw;
    engine.resolved_calibration = null;
    if (engine.input_profile) |*profile| profile.deinit(engine.gpa);
    engine.input_profile = null;
    return succeed(engine);
}

const PipelineStageJSON = struct {
    stage_id: []const u8,
    implementation_id: []const u8,
    input_domain: []const u8,
    output_domain: []const u8,
    neutral_behavior: []const u8,
    status: []const u8,
};

const PipelineManifestJSON = struct {
    recipe_schema_id: []const u8,
    active_graph_id: []const u8,
    target_graph_id: []const u8,
    renderer_id: []const u8,
    backend_id: []const u8,
    precision_id: []const u8,
    resolution_state: []const u8,
    camera_state: []const u8,
    iso_state: []const u8,
    lens_state: []const u8,
    bundle_id: []const u8,
    camera_record_id: ?[]const u8,
    iso_record_ids: []const []const u8,
    input_profile_id: ?[]const u8,
    film_curve_id: ?[]const u8,
    lens_profile_id: ?[]const u8,
    first_affected_stage_id: []const u8,
    stages: []const PipelineStageJSON,
};

pub export fn bk_pipeline_manifest_json(
    engine_maybe: ?*Engine,
    database_path_maybe: ?[*:0]const u8,
) ?[*:0]const u8 {
    const engine = engine_maybe orelse return null;
    const database_path = database_path_maybe orelse {
        _ = fail(engine, err_invalid_argument, "calibration database path is null", .{});
        return null;
    };
    const raw = &(engine.raw orelse {
        _ = fail(engine, err_no_raw, "no raw loaded: bk_load_raw must succeed first", .{});
        return null;
    });
    var database = emu.calibration.Database.open(std.mem.span(database_path)) catch |err| {
        _ = fail(engine, err_render, "cannot open calibration bundle: {s}", .{@errorName(err)});
        return null;
    };
    defer database.deinit();
    const resolved = database.resolve(&raw.metadata, .{}) catch |err| {
        _ = fail(engine, err_render, "cannot resolve calibration: {s}", .{@errorName(err)});
        return null;
    };
    const input_profile = loadInputProfile(&database, engine.gpa, &resolved) catch |err| {
        _ = fail(engine, err_render, "cannot load input profile: {s}", .{@errorName(err)});
        return null;
    };
    if (engine.input_profile) |*old| old.deinit(engine.gpa);
    engine.input_profile = input_profile;
    engine.resolved_calibration = resolved;
    const dependencies = emu.render_manifest.DependencyManifest.init(&resolved);

    var iso_record_ids: [20][]const u8 = @splat("");
    for (dependencies.isoRecordIds(), 0..) |*record_id, index| {
        iso_record_ids[index] = record_id.slice();
    }
    var stages: [emu.render_manifest.reconstruction_stages.len]PipelineStageJSON = undefined;
    for (&stages, emu.render_manifest.reconstruction_stages) |*target, stage| {
        target.* = .{
            .stage_id = stage.stage_id,
            .implementation_id = stage.implementation_id,
            .input_domain = @tagName(stage.input),
            .output_domain = @tagName(stage.output),
            .neutral_behavior = @tagName(stage.neutral),
            .status = @tagName(stage.status),
        };
    }
    const view = PipelineManifestJSON{
        .recipe_schema_id = emu.render_manifest.recipe_schema_id_current,
        .active_graph_id = emu.render_manifest.graph_id_reconstruction_v3,
        .target_graph_id = resolved.processing_graph_id.slice(),
        .renderer_id = emu.render_manifest.renderer_id_strict_cpu_v3,
        .backend_id = "strict_cpu",
        .precision_id = "float32",
        .resolution_state = @tagName(resolved.state),
        .camera_state = selectionState(resolved.camera),
        .iso_state = selectionState(resolved.iso),
        .lens_state = selectionState(resolved.lens),
        .bundle_id = resolved.bundle_id.slice(),
        .camera_record_id = optionalTextSlice(&dependencies.camera_record_id),
        .iso_record_ids = iso_record_ids[0..dependencies.iso_record_count],
        .input_profile_id = optionalTextSlice(&dependencies.input_profile_id),
        .film_curve_id = optionalTextSlice(&dependencies.film_curve_id),
        .lens_profile_id = optionalTextSlice(&dependencies.lens_profile_id),
        .first_affected_stage_id = emu.render_manifest.reconstruction_stages[0].stage_id,
        .stages = &stages,
    };

    var writer: std.Io.Writer = .fixed(engine.manifest_json[0..manifest_json_bytes_max]);
    std.json.Stringify.value(view, .{}, &writer) catch {
        _ = fail(engine, err_render, "pipeline manifest exceeds fixed JSON capacity", .{});
        return null;
    };
    const json = writer.buffered();
    assert(json.len <= manifest_json_bytes_max);
    engine.manifest_json[json.len] = 0;
    _ = succeed(engine);
    return @ptrCast(&engine.manifest_json);
}

fn optionalTextSlice(value: *const ?emu.calibration.Text) ?[]const u8 {
    if (value.*) |*text| return text.slice();
    return null;
}

fn selectionState(value: anytype) []const u8 {
    return switch (value) {
        inline else => |payload, tag| switch (@TypeOf(payload)) {
            emu.calibration.CameraDefaults,
            emu.calibration.IsoDefaults,
            emu.calibration.LensSummary,
            => @tagName(tag),
            emu.calibration.FallbackReason => @tagName(payload),
            else => comptime unreachable,
        },
    };
}

pub export fn bk_set_recipe_json(engine_maybe: ?*Engine, json_maybe: ?[*:0]const u8) i32 {
    const engine = engine_maybe orelse return err_invalid_argument;
    const json = json_maybe orelse {
        return fail(engine, err_invalid_argument, "recipe json is null", .{});
    };
    const parsed = emu.recipe.parse(engine.gpa, std.mem.span(json)) catch |err| switch (err) {
        error.OutOfMemory => return fail(engine, err_out_of_memory, "out of memory", .{}),
        else => return fail(engine, err_recipe, "invalid recipe: {s}", .{@errorName(err)}),
    };
    if (engine.recipe) |*old| old.deinit();
    engine.recipe = parsed;
    return succeed(engine);
}

pub export fn bk_render(
    engine_maybe: ?*Engine,
    edge_px_max: u32,
    width_out: ?*u32,
    height_out: ?*u32,
) ?[*]u8 {
    const engine = engine_maybe orelse return null;
    const width_ptr = width_out orelse {
        _ = fail(engine, err_invalid_argument, "width_out is null", .{});
        return null;
    };
    const height_ptr = height_out orelse {
        _ = fail(engine, err_invalid_argument, "height_out is null", .{});
        return null;
    };
    if (engine.raw == null) {
        _ = fail(engine, err_no_raw, "no raw loaded: bk_load_raw must succeed first", .{});
        return null;
    }

    // A handle with no recipe set renders the engine's default recipe: the
    // shell can show an image before its first slider moves.
    const recipe = renderRecipe(engine);
    const reconstruction = reconstructionDefaults(engine, recipe) orelse {
        _ = fail(engine, err_render, "engine v3 requires resolved calibration", .{});
        return null;
    };
    const camera_profile = cameraProfile(engine, recipe) orelse {
        _ = fail(engine, err_render, "invalid nonlinear camera profile", .{});
        return null;
    };
    const rendered = emu.pipeline.render_decoded(engine.gpa, &engine.raw.?, recipe, .{
        .edge_px_max_out = edge_px_max,
        .reconstruction = reconstruction,
        .camera_profile = camera_profile,
    }) catch |err| {
        const code = switch (err) {
            error.OutOfMemory => err_out_of_memory,
            else => err_render,
        };
        _ = fail(engine, code, "render failed: {s}", .{@errorName(err)});
        return null;
    };

    if (engine.rendered) |*old| old.deinit(engine.gpa);
    engine.rendered = rendered;
    width_ptr.* = rendered.width;
    height_ptr.* = rendered.height;
    _ = succeed(engine);
    return engine.rendered.?.rgba.ptr;
}

pub export fn bk_render_linear(
    engine_maybe: ?*Engine,
    edge_px_max: u32,
    width_out: ?*u32,
    height_out: ?*u32,
) ?[*]f32 {
    return render_linear_with_admission(
        engine_maybe,
        edge_px_max,
        0,
        null,
        null,
        width_out,
        height_out,
    );
}

pub export fn bk_render_linear_with_admission(
    engine_maybe: ?*Engine,
    edge_px_max: u32,
    memory_budget_bytes: u64,
    should_cancel: ?*const fn (?*anyopaque) callconv(.c) i32,
    cancel_context: ?*anyopaque,
    width_out: ?*u32,
    height_out: ?*u32,
) ?[*]f32 {
    return render_linear_with_admission(
        engine_maybe,
        edge_px_max,
        memory_budget_bytes,
        should_cancel,
        cancel_context,
        width_out,
        height_out,
    );
}

fn render_linear_with_admission(
    engine_maybe: ?*Engine,
    edge_px_max: u32,
    memory_budget_bytes: u64,
    should_cancel: ?*const fn (?*anyopaque) callconv(.c) i32,
    cancel_context: ?*anyopaque,
    width_out: ?*u32,
    height_out: ?*u32,
) ?[*]f32 {
    const engine = engine_maybe orelse return null;
    const width_ptr = width_out orelse {
        _ = fail(engine, err_invalid_argument, "width_out is null", .{});
        return null;
    };
    const height_ptr = height_out orelse {
        _ = fail(engine, err_invalid_argument, "height_out is null", .{});
        return null;
    };
    if (engine.raw == null) {
        _ = fail(engine, err_no_raw, "no raw loaded: bk_load_raw must succeed first", .{});
        return null;
    }

    const recipe = renderRecipe(engine);
    const reconstruction = reconstructionDefaults(engine, recipe) orelse {
        _ = fail(engine, err_render, "engine v3 requires resolved calibration", .{});
        return null;
    };
    const camera_profile = cameraProfile(engine, recipe) orelse {
        _ = fail(engine, err_render, "invalid nonlinear camera profile", .{});
        return null;
    };
    const rendered = emu.pipeline.render_linear_decoded(
        engine.gpa,
        &engine.raw.?,
        recipe,
        .{
            .edge_px_max_out = edge_px_max,
            .memory_budget_bytes = memory_budget_bytes,
            .cancellation = .{
                .context = cancel_context,
                .callback = should_cancel,
            },
            .reconstruction = reconstruction,
            .camera_profile = camera_profile,
        },
    ) catch |err| {
        const code = switch (err) {
            error.OutOfMemory => err_out_of_memory,
            error.Cancelled => err_cancelled,
            else => err_render,
        };
        _ = fail(engine, code, "linear render failed: {s}", .{@errorName(err)});
        return null;
    };

    if (engine.linear_rendered) |*old| old.deinit(engine.gpa);
    engine.linear_rendered = rendered;
    width_ptr.* = rendered.width;
    height_ptr.* = rendered.height;
    _ = succeed(engine);
    return engine.linear_rendered.?.rgba.ptr;
}

fn reconstructionDefaults(
    engine: *const Engine,
    recipe: emu.pipeline.Recipe,
) ?emu.pipeline.ReconstructionDefaults {
    if (recipe.engine_version != 3) return .legacy;
    const resolved = engine.resolved_calibration orelse return null;
    return emu.reconstruction.defaults(&resolved) catch null;
}

fn loadInputProfile(
    database: *emu.calibration.Database,
    gpa: std.mem.Allocator,
    resolved: *const emu.calibration.ResolvedCalibration,
) !?emu.calibration.Mft2 {
    const profile_id = switch (resolved.camera) {
        .resolved => |camera| camera.input_profile_id.slice(),
        .generic_fallback => return null,
    };
    var mft2 = try database.loadMft2(gpa, profile_id);
    errdefer mft2.deinit(gpa);
    const profile = try emu.icc_profile.Profile.init(&mft2);
    if (!profile.isBootstrapCanonical()) return error.InvalidData;
    return mft2;
}

fn cameraProfile(
    engine: *const Engine,
    recipe: emu.pipeline.Recipe,
) ?emu.pipeline.CameraProfile {
    if (recipe.engine_version != 3) return .technical_matrix;
    const mft2 = &(engine.input_profile orelse return .technical_matrix);
    const profile = emu.icc_profile.Profile.init(mft2) catch return null;
    return .{ .nonlinear = profile };
}

fn renderRecipe(engine: *const Engine) emu.pipeline.Recipe {
    if (engine.recipe) |parsed| return parsed.value;
    if (engine.resolved_calibration != null) {
        return .{ .engine_version = 3, .ops = &emu.recipe.default_ops };
    }
    return emu.recipe.default_recipe();
}

pub export fn bk_last_error(engine_maybe: ?*const Engine) [*:0]const u8 {
    const engine = engine_maybe orelse return "invalid engine handle";
    assert(engine.last_error[error_message_bytes_max] == 0);
    return @ptrCast(&engine.last_error);
}

pub export fn bk_version() u32 {
    return emu.pipeline.engine_version_current;
}

// ---- error plumbing ----------------------------------------------------------

fn fail(engine: *Engine, code: i32, comptime fmt: []const u8, args: anytype) i32 {
    assert(code < 0);
    const text = std.fmt.bufPrint(engine.last_error[0..error_message_bytes_max], fmt, args) catch
        engine.last_error[0..error_message_bytes_max]; // truncated is fine, lost is not
    engine.last_error[text.len] = 0;
    assert(engine.last_error[error_message_bytes_max] == 0);
    return code;
}

fn succeed(engine: *Engine) i32 {
    engine.last_error[0] = 0;
    return ok;
}

// ---- tests ---------------------------------------------------------------------

/// Every exported function, collected by reflection: adding an export
/// without touching the header (or the reverse) fails the sync test below.
const exported_names = blk: {
    const decls = @typeInfo(@This()).@"struct".decls;
    var names: []const []const u8 = &.{};
    for (decls) |decl| {
        if (std.mem.startsWith(u8, decl.name, "bk_")) {
            names = names ++ [_][]const u8{decl.name};
        }
    }
    break :blk names;
};

comptime {
    // Linear admission, source geometry, and the immutable pipeline manifest
    // are the extensions to the frozen eight-function Phase 1 surface.
    assert(exported_names.len == 11);
}

test "the hand-written header declares exactly the exported surface" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const header = try std.Io.Dir.cwd().readFileAlloc(
        io,
        "include/banksia.h",
        gpa,
        std.Io.Limit.limited(1 << 20),
    );
    defer gpa.free(header);

    // Each export is declared (name followed by an open paren), and the
    // count of `bk_*(` occurrences matches: nothing extra hides in there.
    var declarations: usize = 0;
    var search: usize = 0;
    while (std.mem.indexOfPos(u8, header, search, "bk_")) |at| {
        var end = at;
        while (end < header.len and
            (std.ascii.isLower(header[end]) or header[end] == '_')) end += 1;
        if (end < header.len and header[end] == '(') declarations += 1;
        search = at + 3;
    }
    try std.testing.expectEqual(exported_names.len, declarations);
    inline for (exported_names) |name| {
        try std.testing.expect(std.mem.indexOf(u8, header, name ++ "(") != null);
    }
}

test "error paths set a code and a message; success clears it" {
    const engine = bk_engine_create() orelse return error.OutOfMemory;
    defer bk_engine_destroy(engine);

    // Render before load: null pixels, a message, and untouched outputs.
    var width: u32 = 0;
    var height: u32 = 0;
    try std.testing.expectEqual(err_no_raw, bk_raw_dimensions(engine, &width, &height));
    try std.testing.expect(message_length(engine) > 0);
    try std.testing.expectEqual(null, bk_render(engine, 0, &width, &height));
    try std.testing.expect(message_length(engine) > 0);
    try std.testing.expectEqual(@as(u32, 0), width);

    try std.testing.expectEqual(
        err_io,
        bk_load_raw(engine, "definitely/not/a/real/banksia.dng"),
    );
    try std.testing.expect(message_length(engine) > 0);

    try std.testing.expectEqual(err_recipe, bk_set_recipe_json(engine, "{ not json"));
    try std.testing.expect(message_length(engine) > 0);

    // Structurally valid JSON that the pipeline rejects fails at render.
    try std.testing.expectEqual(
        ok,
        bk_set_recipe_json(engine, "{\"engine_version\":1,\"ops\":[]}"),
    );
    try std.testing.expectEqual(@as(usize, 0), message_length(engine));

    try std.testing.expectEqual(err_invalid_argument, bk_load_raw(engine, null));
    try std.testing.expectEqual(err_invalid_argument, bk_load_raw(null, "x"));
    try std.testing.expectEqual(null, bk_render(null, 0, &width, &height));
}

test "create/load/render/destroy round trip through a real DNG file" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const bayer = try gpa.alloc(u16, 64 * 40);
    defer gpa.free(bayer);
    for (bayer, 0..) |*site, i| site.* = @intCast(1024 + (i * 331) % 14000);
    const blob = try emu.dng_write.write(gpa, .{
        .width = 64,
        .height = 40,
        .cfa = .{ .red, .green, .green, .blue },
        .black_level = 1024,
        .white_level = 15360,
        .wb_neutral = .{ 0.6, 1.0, 0.8 },
        .bayer = bayer,
    });
    defer gpa.free(blob);
    try tmp.dir.writeFile(io, .{ .sub_path = "roundtrip.dng", .data = blob });
    const path = try std.fmt.allocPrintSentinel(
        gpa,
        ".zig-cache/tmp/{s}/roundtrip.dng",
        .{tmp.sub_path},
        0,
    );
    defer gpa.free(path);

    const engine = bk_engine_create() orelse return error.OutOfMemory;
    defer bk_engine_destroy(engine);

    try std.testing.expectEqual(ok, bk_load_raw(engine, path));
    var source_width: u32 = 0;
    var source_height: u32 = 0;
    try std.testing.expectEqual(
        ok,
        bk_raw_dimensions(engine, &source_width, &source_height),
    );
    try std.testing.expectEqual(@as(u32, 64), source_width);
    try std.testing.expectEqual(@as(u32, 40), source_height);
    const manifest_pointer = bk_pipeline_manifest_json(
        engine,
        emu.calibration.database_path_default,
    ) orelse return error.TestUnexpectedResult;
    const manifest_json = std.mem.span(manifest_pointer);
    try std.testing.expect(std.mem.indexOf(
        u8,
        manifest_json,
        "\"active_graph_id\":\"graph.banksia.reconstruction.v3\"",
    ) != null);
    try std.testing.expect(std.mem.indexOf(
        u8,
        manifest_json,
        "\"resolution_state\":\"generic_fallback\"",
    ) != null);
    var width: u32 = 0;
    var height: u32 = 0;

    // Preview then full resolution: dims follow the longest-edge contract,
    // and the second render invalidates (frees) the first buffer.
    const preview = bk_render(engine, 16, &width, &height);
    try std.testing.expect(preview != null);
    try std.testing.expectEqual(@as(u32, 16), width);
    try std.testing.expectEqual(@as(u32, 10), height);

    const full = bk_render(engine, 0, &width, &height);
    try std.testing.expect(full != null);
    try std.testing.expectEqual(@as(u32, 64), width);
    try std.testing.expectEqual(@as(u32, 40), height);
    try std.testing.expectEqual(@as(u8, 255), full.?[3]); // alpha is opaque

    try std.testing.expectEqual(ok, bk_set_recipe_json(
        engine,
        "{\"engine_version\":2,\"ops\":[" ++
            "{\"black_point\":{}},{\"white_balance\":{\"as_shot\":true," ++
            "\"gain_r\":1,\"gain_g\":1,\"gain_b\":1}},{\"demosaic\":{}}," ++
            "{\"exposure\":{\"ev\":0}},{\"tone_curve\":{\"contrast\":0}}," ++
            "{\"srgb_encode\":{}}]}",
    ));
    const linear = bk_render_linear(engine, 16, &width, &height);
    try std.testing.expect(linear != null);
    try std.testing.expectEqual(@as(u32, 16), width);
    try std.testing.expectEqual(@as(u32, 10), height);
    try std.testing.expectEqual(@as(f32, 1), linear.?[3]);

    // Engine v3 is calibration-backed: the manifest resolution above snapshots
    // a generic fallback, which is still an explicit and valid resolved default.
    try std.testing.expectEqual(ok, bk_set_recipe_json(
        engine,
        "{\"engine_version\":3,\"ops\":[" ++
            "{\"black_point\":{}},{\"white_balance\":{\"as_shot\":true," ++
            "\"gain_r\":1,\"gain_g\":1,\"gain_b\":1}},{\"demosaic\":{}}," ++
            "{\"exposure\":{\"ev\":0}},{\"tone_curve\":{\"contrast\":0}}," ++
            "{\"srgb_encode\":{}}]}",
    ));
    const calibrated_linear = bk_render_linear(engine, 16, &width, &height);
    try std.testing.expect(calibrated_linear != null);
    try std.testing.expectEqual(@as(u32, 16), width);
    try std.testing.expectEqual(@as(u32, 10), height);
    try std.testing.expectEqual(@as(f32, 1), calibrated_linear.?[3]);

    try std.testing.expectEqual(
        null,
        bk_render_linear_with_admission(engine, 16, 1, null, null, &width, &height),
    );
    try std.testing.expect(std.mem.indexOf(
        u8,
        std.mem.span(bk_last_error(engine)),
        "OutOfMemory",
    ) != null);

    try std.testing.expectEqual(
        null,
        bk_render_linear_with_admission(
            engine,
            16,
            std.math.maxInt(u64),
            test_should_cancel,
            null,
            &width,
            &height,
        ),
    );
    try std.testing.expect(std.mem.indexOf(
        u8,
        std.mem.span(bk_last_error(engine)),
        "Cancelled",
    ) != null);
}

fn test_should_cancel(context: ?*anyopaque) callconv(.c) i32 {
    assert(context == null);
    return 1;
}

fn message_length(engine: *const Engine) usize {
    return std.mem.span(bk_last_error(engine)).len;
}
