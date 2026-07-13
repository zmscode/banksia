//! Versioned render semantics and calibration dependency identities.
//!
//! The graph describes numerical meaning independently from a CPU or Metal
//! execution plan. Calibration resolution is control-plane work; compact IDs
//! enter artifact keys before any affected data-plane stage executes.

const std = @import("std");
const assert = std.debug.assert;
const calibration = @import("calibration.zig");
const dng = @import("dng.zig");

pub const recipe_schema_id_current = "recipe.banksia.global.v2";
pub const graph_id_legacy_v2 = "graph.banksia.matrix.v2";
pub const graph_id_calibrated_v1 = "graph.banksia.calibrated.v1";
pub const renderer_id_strict_cpu_v2 = "banksia.cpu.strict-f32.v2";
pub const renderer_id_metal_late_v1 = "banksia.metal.late-develop-f32.v1";
pub const demosaic_id_bilinear_v1 = "banksia.demosaic.bilinear.v1";
pub const demosaic_id_bilinear_chroma_safe_v2 =
    "banksia.demosaic.bilinear-chroma-safe.v2";
pub const demosaic_id_rcd_reference_v1 = "banksia.demosaic.rcd-reference.v1";

const iso_dependency_count_max: u8 = 20;

comptime {
    assert(iso_dependency_count_max >= 2 * 10);
    assert(calibrated_stages.len > legacy_stages.len);
}

pub const Domain = enum {
    sensor_cfa,
    camera_rgb,
    profiled_working_rgb,
    developed_linear_rgb,
    display_output_rgb,
};

pub const NeutralBehavior = enum {
    identity,
    metadata_default,
    calibration_default,
    always_on_technical,
};

pub const StageStatus = enum {
    active,
    planned,
};

pub const Stage = struct {
    stage_id: []const u8,
    implementation_id: []const u8,
    input: Domain,
    output: Domain,
    neutral: NeutralBehavior,
    status: StageStatus,
};

pub const Graph = struct {
    graph_id: []const u8,
    recipe_schema_id: []const u8,
    stages: []const Stage,
};

pub const legacy_stages = [_]Stage{
    .{
        .stage_id = "normalize",
        .implementation_id = "banksia.normalize.site-levels.v2",
        .input = .sensor_cfa,
        .output = .sensor_cfa,
        .neutral = .metadata_default,
        .status = .active,
    },
    .{
        .stage_id = "demosaic",
        .implementation_id = demosaic_id_bilinear_chroma_safe_v2,
        .input = .sensor_cfa,
        .output = .camera_rgb,
        .neutral = .always_on_technical,
        .status = .active,
    },
    .{
        .stage_id = "camera-matrix",
        .implementation_id = "banksia.color.dng-matrix.v2",
        .input = .camera_rgb,
        .output = .profiled_working_rgb,
        .neutral = .always_on_technical,
        .status = .active,
    },
    .{
        .stage_id = "global-develop",
        .implementation_id = "banksia.develop.global.v2",
        .input = .profiled_working_rgb,
        .output = .developed_linear_rgb,
        .neutral = .identity,
        .status = .active,
    },
    .{
        .stage_id = "display-output",
        .implementation_id = "banksia.output.srgb.v2",
        .input = .developed_linear_rgb,
        .output = .display_output_rgb,
        .neutral = .always_on_technical,
        .status = .active,
    },
};

pub const calibrated_stages = [_]Stage{
    .{
        .stage_id = "normalize",
        .implementation_id = "banksia.normalize.calibrated.v1",
        .input = .sensor_cfa,
        .output = .sensor_cfa,
        .neutral = .calibration_default,
        .status = .planned,
    },
    .{
        .stage_id = "sensor-cleanup",
        .implementation_id = "banksia.sensor-cleanup.reference.v1",
        .input = .sensor_cfa,
        .output = .sensor_cfa,
        .neutral = .identity,
        .status = .planned,
    },
    .{
        .stage_id = "demosaic",
        .implementation_id = demosaic_id_rcd_reference_v1,
        .input = .sensor_cfa,
        .output = .camera_rgb,
        .neutral = .always_on_technical,
        .status = .planned,
    },
    .{
        .stage_id = "highlight-reconstruction",
        .implementation_id = "banksia.highlight.channel-recovery.v1",
        .input = .camera_rgb,
        .output = .camera_rgb,
        .neutral = .identity,
        .status = .planned,
    },
    .{
        .stage_id = "camera-detail",
        .implementation_id = "banksia.detail.camera-iso.v1",
        .input = .camera_rgb,
        .output = .camera_rgb,
        .neutral = .identity,
        .status = .planned,
    },
    .{
        .stage_id = "camera-profile",
        .implementation_id = "banksia.color.icc-mft2.v1",
        .input = .camera_rgb,
        .output = .profiled_working_rgb,
        .neutral = .always_on_technical,
        .status = .planned,
    },
    .{
        .stage_id = "lens-optics",
        .implementation_id = "banksia.lens.calibrated.v1",
        .input = .profiled_working_rgb,
        .output = .profiled_working_rgb,
        .neutral = .identity,
        .status = .planned,
    },
    .{
        .stage_id = "camera-film-curve",
        .implementation_id = "banksia.film-curve.capture-one-bootstrap.v1",
        .input = .profiled_working_rgb,
        .output = .developed_linear_rgb,
        .neutral = .calibration_default,
        .status = .planned,
    },
    .{
        .stage_id = "global-develop",
        .implementation_id = "banksia.develop.global.v2",
        .input = .developed_linear_rgb,
        .output = .developed_linear_rgb,
        .neutral = .identity,
        .status = .active,
    },
    .{
        .stage_id = "capture-sharpen",
        .implementation_id = "banksia.sharpen.capture.v1",
        .input = .developed_linear_rgb,
        .output = .developed_linear_rgb,
        .neutral = .identity,
        .status = .planned,
    },
    .{
        .stage_id = "display-output",
        .implementation_id = "banksia.output.srgb.v2",
        .input = .developed_linear_rgb,
        .output = .display_output_rgb,
        .neutral = .always_on_technical,
        .status = .active,
    },
};

pub const graph_legacy_v2 = Graph{
    .graph_id = graph_id_legacy_v2,
    .recipe_schema_id = recipe_schema_id_current,
    .stages = &legacy_stages,
};

pub const graph_calibrated_v1 = Graph{
    .graph_id = graph_id_calibrated_v1,
    .recipe_schema_id = recipe_schema_id_current,
    .stages = &calibrated_stages,
};

pub const DependencyManifest = struct {
    bundle_id: calibration.Text,
    processing_graph_id: calibration.Text,
    camera_record_id: ?calibration.Text = null,
    input_profile_id: ?calibration.Text = null,
    film_curve_id: ?calibration.Text = null,
    lens_profile_id: ?calibration.Text = null,
    iso_record_ids: [iso_dependency_count_max]calibration.Text = @splat(.{}),
    iso_record_count: u8 = 0,

    pub fn init(resolved: *const calibration.ResolvedCalibration) DependencyManifest {
        var manifest = DependencyManifest{
            .bundle_id = resolved.bundle_id,
            .processing_graph_id = resolved.processing_graph_id,
        };
        switch (resolved.camera) {
            .generic_fallback => {},
            .resolved => |camera| {
                manifest.camera_record_id = camera.camera_id;
                manifest.input_profile_id = camera.input_profile_id;
                manifest.film_curve_id = camera.film_curve_id;
            },
        }
        switch (resolved.iso) {
            .skipped => {},
            .resolved => |iso| manifest.appendIsoDefaults(&iso),
        }
        switch (resolved.lens) {
            .correction_off => {},
            .resolved => |lens| manifest.lens_profile_id = lens.lens_id,
        }
        assert(manifest.iso_record_count <= iso_dependency_count_max);
        return manifest;
    }

    pub fn isoRecordIds(manifest: *const DependencyManifest) []const calibration.Text {
        assert(manifest.iso_record_count <= iso_dependency_count_max);
        return manifest.iso_record_ids[0..manifest.iso_record_count];
    }

    pub fn dependencyCount(manifest: *const DependencyManifest) u8 {
        var count: u8 = 2; // Bundle and processing graph are always present.
        if (manifest.camera_record_id != null) count += 1;
        if (manifest.input_profile_id != null) count += 1;
        if (manifest.film_curve_id != null) count += 1;
        if (manifest.lens_profile_id != null) count += 1;
        count += manifest.iso_record_count;
        assert(count >= 2);
        assert(count <= iso_dependency_count_max + 6);
        return count;
    }

    pub fn hash(manifest: *const DependencyManifest) [32]u8 {
        var state = std.crypto.hash.sha2.Sha256.init(.{});
        hashText(&state, &manifest.bundle_id);
        hashText(&state, &manifest.processing_graph_id);
        hashOptionalText(&state, manifest.camera_record_id);
        hashOptionalText(&state, manifest.input_profile_id);
        hashOptionalText(&state, manifest.film_curve_id);
        hashOptionalText(&state, manifest.lens_profile_id);
        for (manifest.isoRecordIds()) |*record_id| hashText(&state, record_id);
        return state.finalResult();
    }

    fn appendIsoDefaults(manifest: *DependencyManifest, iso: *const calibration.IsoDefaults) void {
        const values = [_]?calibration.IsoValue{
            iso.noise_floor,
            iso.noise_poisson,
            iso.base_gain,
            iso.sensor_range_gain,
            iso.sharpen_amount,
            iso.sharpen_radius,
            iso.sharpen_threshold,
            iso.anti_color_aliasing,
            iso.long_exposure_cleanup,
            iso.fine_grain,
        };
        for (values) |value_optional| {
            if (value_optional) |value| {
                manifest.appendIsoRecord(value.iso_record_id);
                if (value.upper_iso_record_id) |upper| manifest.appendIsoRecord(upper);
            }
        }
    }

    fn appendIsoRecord(manifest: *DependencyManifest, record_id: calibration.Text) void {
        for (manifest.isoRecordIds()) |*existing| {
            if (std.mem.eql(u8, existing.slice(), record_id.slice())) return;
        }
        assert(manifest.iso_record_count < iso_dependency_count_max);
        manifest.iso_record_ids[manifest.iso_record_count] = record_id;
        manifest.iso_record_count += 1;
    }
};

pub const ArtifactManifest = struct {
    source_id: []const u8,
    recipe_id: []const u8,
    output_id: []const u8,
    renderer_id: []const u8,
    backend_id: []const u8,
    precision_id: []const u8,
    graph: Graph,
    dependencies: DependencyManifest,

    pub fn firstAffectedStage(manifest: *const ArtifactManifest) Stage {
        assert(manifest.graph.stages.len > 0);
        return manifest.graph.stages[0];
    }

    pub fn firstStageCacheHash(manifest: *const ArtifactManifest) [32]u8 {
        const stage = manifest.firstAffectedStage();
        var state = std.crypto.hash.sha2.Sha256.init(.{});
        hashSlice(&state, manifest.source_id);
        hashSlice(&state, manifest.recipe_id);
        hashSlice(&state, manifest.output_id);
        hashSlice(&state, manifest.renderer_id);
        hashSlice(&state, manifest.backend_id);
        hashSlice(&state, manifest.precision_id);
        hashSlice(&state, manifest.graph.graph_id);
        hashSlice(&state, manifest.graph.recipe_schema_id);
        hashSlice(&state, stage.stage_id);
        hashSlice(&state, stage.implementation_id);
        const dependency_hash = manifest.dependencies.hash();
        state.update(&dependency_hash);
        return state.finalResult();
    }
};

pub const MigrationError = error{
    SourceGraphMismatch,
    UnsupportedTargetGraph,
    ExplicitAcceptanceRequired,
};

pub const MigrationRequest = struct {
    source_graph_id: []const u8,
    target_graph_id: []const u8,
    accept_numerical_change: bool,
};

pub fn migrate(request: MigrationRequest) MigrationError!Graph {
    if (!std.mem.eql(u8, request.source_graph_id, graph_id_legacy_v2)) {
        return error.SourceGraphMismatch;
    }
    if (!std.mem.eql(u8, request.target_graph_id, graph_id_calibrated_v1)) {
        return error.UnsupportedTargetGraph;
    }
    if (!request.accept_numerical_change) return error.ExplicitAcceptanceRequired;
    return graph_calibrated_v1;
}

fn hashOptionalText(
    state: *std.crypto.hash.sha2.Sha256,
    text_optional: ?calibration.Text,
) void {
    if (text_optional) |text| {
        hashText(state, &text);
    } else {
        hashSlice(state, "");
    }
}

fn hashText(state: *std.crypto.hash.sha2.Sha256, text: *const calibration.Text) void {
    hashSlice(state, text.slice());
}

fn hashSlice(state: *std.crypto.hash.sha2.Sha256, value: []const u8) void {
    var length: [8]u8 = undefined;
    std.mem.writeInt(u64, &length, value.len, .little);
    state.update(&length);
    state.update(value);
}

test "calibrated graph domains form one legal ordered chain" {
    try std.testing.expectEqual(Domain.sensor_cfa, calibrated_stages[0].input);
    for (calibrated_stages[1..], 0..) |stage, index| {
        try std.testing.expectEqual(calibrated_stages[index].output, stage.input);
    }
    try std.testing.expectEqual(
        Domain.display_output_rgb,
        calibrated_stages[calibrated_stages.len - 1].output,
    );
}

test "graph migration requires explicit numerical-change acceptance" {
    const request = MigrationRequest{
        .source_graph_id = graph_id_legacy_v2,
        .target_graph_id = graph_id_calibrated_v1,
        .accept_numerical_change = false,
    };
    try std.testing.expectError(error.ExplicitAcceptanceRequired, migrate(request));
    const migrated = try migrate(.{
        .source_graph_id = graph_id_legacy_v2,
        .target_graph_id = graph_id_calibrated_v1,
        .accept_numerical_change = true,
    });
    try std.testing.expectEqualStrings(graph_id_calibrated_v1, migrated.graph_id);
}

test "diagnostic demosaic implementations retain distinct stable identities" {
    try std.testing.expect(!std.mem.eql(
        u8,
        demosaic_id_bilinear_v1,
        demosaic_id_bilinear_chroma_safe_v2,
    ));
    try std.testing.expect(!std.mem.eql(
        u8,
        demosaic_id_bilinear_chroma_safe_v2,
        demosaic_id_rcd_reference_v1,
    ));
    try std.testing.expect(!std.mem.eql(
        u8,
        demosaic_id_bilinear_v1,
        demosaic_id_rcd_reference_v1,
    ));
}

test "artifact and first-stage keys include every resolved calibration dependency" {
    var database = try calibration.Database.open(calibration.database_path_default);
    defer database.deinit();
    const metadata = testMetadata();
    const resolved = try database.resolve(&metadata, .{});
    const dependencies = DependencyManifest.init(&resolved);
    try std.testing.expect(dependencies.camera_record_id != null);
    try std.testing.expect(dependencies.input_profile_id != null);
    try std.testing.expect(dependencies.film_curve_id != null);
    try std.testing.expect(dependencies.lens_profile_id != null);
    try std.testing.expect(dependencies.iso_record_count > 0);

    const artifact = ArtifactManifest{
        .source_id = "sha256:source",
        .recipe_id = "sha256:recipe",
        .output_id = "display.srgb.v1",
        .renderer_id = renderer_id_strict_cpu_v2,
        .backend_id = "cpu",
        .precision_id = "float32",
        .graph = graph_calibrated_v1,
        .dependencies = dependencies,
    };
    const full_hash = artifact.firstStageCacheHash();

    const resolved_without_lens = try database.resolve(
        &metadata,
        .{ .lens_corrections_enabled = false },
    );
    var without_lens = artifact;
    without_lens.dependencies = DependencyManifest.init(&resolved_without_lens);
    try std.testing.expect(!std.mem.eql(u8, &full_hash, &without_lens.firstStageCacheHash()));
}

fn testMetadata() dng.Metadata {
    return .{
        .width = 2,
        .height = 2,
        .compression = .none,
        .cfa = .{ .red, .green, .green, .blue },
        .black_level = 0,
        .white_level = 1023,
        .wb_neutral = .{ 1, 1, 1 },
        .orientation = .normal,
        .active_area = .{ .x = 0, .y = 0, .width = 2, .height = 2 },
        .default_crop = .{ .x = 0, .y = 0, .width = 2, .height = 2 },
        .make = dng.Text.init("Canon"),
        .model = dng.Text.init("EOS-1D X Mark II"),
        .lens = dng.Text.init("Canon EF 24-105mm f/4L IS II USM"),
        .iso = 600,
    };
}
