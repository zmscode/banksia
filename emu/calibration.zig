//! Read-only access to Banksia's versioned camera calibration bundle.
//!
//! SQLite is control-plane storage. A render resolves immutable records once,
//! then uploads or copies compact values into the CPU/Metal data plane.

const std = @import("std");
const assert = std.debug.assert;
const dng = @import("dng.zig");

const c = @cImport({
    @cInclude("sqlite3.h");
});

pub const schema_version_expected: u32 = 1;
pub const database_path_default = "data/calibration/banksia-calibration-v1.sqlite3";

const text_bytes_max: u32 = 160;
const profile_blob_bytes_max: u32 = 2 * 1024 * 1024;
pub const curve_points_max: u32 = 64;

comptime {
    assert(text_bytes_max <= 255);
    assert(profile_blob_bytes_max >= 3 * 33 * 33 * 33 * 2);
    assert(curve_points_max <= 255);
}

pub const Error = error{
    OpenFailed,
    SchemaMismatch,
    QueryFailed,
    NotFound,
    Ambiguous,
    InvalidData,
    TextTooLong,
    BlobTooLarge,
    OutOfMemory,
};

pub const Text = struct {
    bytes: [text_bytes_max]u8 = @splat(0),
    len: u8 = 0,

    pub fn init(value: []const u8) Error!Text {
        if (value.len > text_bytes_max) return error.TextTooLong;
        var text: Text = .{};
        @memcpy(text.bytes[0..value.len], value);
        text.len = @intCast(value.len);
        return text;
    }

    pub fn slice(text: *const Text) []const u8 {
        return text.bytes[0..text.len];
    }
};

pub const CameraDefaults = struct {
    camera_id: Text,
    input_profile_id: Text,
    film_curve_id: Text,
    base_gain: f32,
    sensor_range_gain: f32,
    adaptive_green_enabled: bool,
};

pub const IsoDefaults = struct {
    requested_iso: f32,
    noise_floor: ?IsoValue,
    noise_poisson: ?IsoValue,
    base_gain: ?IsoValue,
    sensor_range_gain: ?IsoValue,
    sharpen_amount: ?IsoValue,
    sharpen_radius: ?IsoValue,
    sharpen_threshold: ?IsoValue,
    anti_color_aliasing: ?IsoValue,
    long_exposure_cleanup: ?IsoValue,
    fine_grain: ?IsoValue,
};

pub const IsoValue = struct {
    value: f32,
    iso_record_id: Text,
    node_iso: f32,
    upper_iso_record_id: ?Text = null,
    upper_node_iso: ?f32 = null,
    resolution: IsoResolution,
};

pub const IsoResolution = enum {
    exact,
    interpolated,
    inherited,
};

const IsoPropertyBehavior = enum {
    continuous,
    discrete,
};

const IsoNode = struct {
    value: f32,
    iso_record_id: Text,
    iso: f32,
    ordinal: u32,
};

pub const LensSummary = struct {
    lens_id: Text,
    full_name: Text,
    node_count: u32,
    attribute_count: u32,
};

pub const FallbackReason = enum {
    capture_fact_missing,
    unsupported_camera,
    unsupported_lens,
    ambiguous_record,
    malformed_record,
    iso_unavailable,
    correction_disabled,
};

pub const CameraSelection = union(enum) {
    resolved: CameraDefaults,
    generic_fallback: FallbackReason,
};

pub const IsoSelection = union(enum) {
    resolved: IsoDefaults,
    skipped: FallbackReason,
};

pub const LensSelection = union(enum) {
    resolved: LensSummary,
    correction_off: FallbackReason,
};

pub const ResolutionState = enum {
    resolved,
    partial,
    generic_fallback,
};

pub const ResolveOptions = struct {
    lens_corrections_enabled: bool = true,
};

pub const ResolvedCalibration = struct {
    bundle_id: Text,
    processing_graph_id: Text,
    camera: CameraSelection,
    iso: IsoSelection,
    lens: LensSelection,
    state: ResolutionState,
};

pub const ProfileSummary = struct {
    profile_id: Text,
    byte_size: u32,
    tag_count: u16,
    input_channels: u8,
    output_channels: u8,
    grid_points: u8,
    input_entries: u16,
    output_entries: u16,
};

pub const Point = struct {
    x: f64,
    y: f64,
};

pub const FilmCurve = struct {
    curve_id: Text,
    format_version: u32,
    flags: u32,
    film: [curve_points_max]Point = @splat(.{ .x = 0, .y = 0 }),
    ccd: [curve_points_max]Point = @splat(.{ .x = 0, .y = 0 }),
    contrast: [curve_points_max]Point = @splat(.{ .x = 0, .y = 0 }),
    film_count: u8 = 0,
    ccd_count: u8 = 0,
    contrast_count: u8 = 0,
};

pub const Mft2 = struct {
    profile_id: Text,
    input_channels: u8,
    output_channels: u8,
    grid_points: u8,
    input_entries: u16,
    output_entries: u16,
    storage: []u8,
    matrix_s15fixed16: []const u8,
    input_tables_u16be: []const u8,
    clut_u16be: []const u8,
    output_tables_u16be: []const u8,

    pub fn deinit(mft2: *Mft2, gpa: std.mem.Allocator) void {
        gpa.free(mft2.storage);
        mft2.* = undefined;
    }
};

pub const Database = struct {
    handle: *c.sqlite3,

    pub fn open(path: [:0]const u8) Error!Database {
        var handle_optional: ?*c.sqlite3 = null;
        const flags = c.SQLITE_OPEN_READONLY | c.SQLITE_OPEN_NOMUTEX;
        const result = c.sqlite3_open_v2(path.ptr, &handle_optional, flags, null);
        if (result != c.SQLITE_OK) {
            if (handle_optional) |handle| {
                const close_result = c.sqlite3_close_v2(handle);
                assert(close_result == c.SQLITE_OK);
            }
            return error.OpenFailed;
        }
        const handle = handle_optional orelse return error.OpenFailed;
        errdefer {
            const close_result = c.sqlite3_close_v2(handle);
            assert(close_result == c.SQLITE_OK);
        }

        var database = Database{ .handle = handle };
        try database.validateSchema();
        return database;
    }

    pub fn deinit(database: *Database) void {
        const result = c.sqlite3_close_v2(database.handle);
        assert(result == c.SQLITE_OK);
        database.* = undefined;
    }

    pub fn bundleId(database: *Database) Error!Text {
        return database.metadataValue("bundle_id");
    }

    pub fn processingGraphId(database: *Database) Error!Text {
        return database.metadataValue("processing_graph_id");
    }

    pub fn resolve(
        database: *Database,
        metadata: *const dng.Metadata,
        options: ResolveOptions,
    ) Error!ResolvedCalibration {
        const camera = try database.resolveCamera(metadata);
        const iso = try database.resolveIso(metadata, camera);
        const lens = try database.resolveLens(metadata, options);
        const state: ResolutionState = switch (camera) {
            .generic_fallback => .generic_fallback,
            .resolved => switch (iso) {
                .skipped => .partial,
                .resolved => switch (lens) {
                    .correction_off => .partial,
                    .resolved => .resolved,
                },
            },
        };
        return .{
            .bundle_id = try database.bundleId(),
            .processing_graph_id = try database.processingGraphId(),
            .camera = camera,
            .iso = iso,
            .lens = lens,
            .state = state,
        };
    }

    fn metadataValue(database: *Database, key: []const u8) Error!Text {
        var statement = try database.prepare(
            "SELECT value FROM bundle_metadata WHERE key = ?1",
        );
        defer statement.deinit();
        try statement.bindText(1, key);
        if (try statement.step() != .row) return error.SchemaMismatch;
        const value = try statement.columnText(0);
        const result = try Text.init(value);
        if (try statement.step() != .done) return error.SchemaMismatch;
        return result;
    }

    pub fn cameraDefaults(
        database: *Database,
        make: []const u8,
        model: []const u8,
    ) Error!CameraDefaults {
        var make_buffer: [text_bytes_max]u8 = undefined;
        var model_buffer: [text_bytes_max]u8 = undefined;
        const make_normalized = try normalizeIdentity(&make_buffer, make);
        const model_normalized = try normalizeIdentity(&model_buffer, model);

        var statement = try database.prepare(
            \\SELECT c.camera_id, c.input_profile_id, c.film_curve_id,
            \\       CAST(gain.value AS REAL), CAST(sensor.value AS REAL),
            \\       CAST(adaptive.value AS INTEGER)
            \\FROM camera_alias AS alias
            \\JOIN camera AS c USING(camera_id)
            \\JOIN camera_property AS gain
            \\  ON gain.camera_id = c.camera_id AND gain.name = 'gain'
            \\JOIN camera_property AS sensor
            \\  ON sensor.camera_id = c.camera_id AND sensor.name = 'sensorRangeGain'
            \\JOIN camera_property AS adaptive
            \\  ON adaptive.camera_id = c.camera_id
            \\ AND adaptive.name = 'G1G2AdaptiveGainEnabled'
            \\WHERE alias.make_normalized = ?1 AND alias.model_normalized = ?2
        );
        defer statement.deinit();
        try statement.bindText(1, make_normalized);
        try statement.bindText(2, model_normalized);

        if (try statement.step() != .row) return error.NotFound;
        const defaults = CameraDefaults{
            .camera_id = try Text.init(try statement.columnText(0)),
            .input_profile_id = try Text.init(try statement.columnText(1)),
            .film_curve_id = try Text.init(try statement.columnText(2)),
            .base_gain = try statement.columnF32(3),
            .sensor_range_gain = try statement.columnF32(4),
            .adaptive_green_enabled = try statement.columnBool(5),
        };
        if (try statement.step() != .done) return error.Ambiguous;
        return defaults;
    }

    pub fn isoDefaults(
        database: *Database,
        camera_id: []const u8,
        requested_iso: f32,
    ) Error!IsoDefaults {
        if (!std.math.isFinite(requested_iso)) return error.InvalidData;
        if (requested_iso < 0) return error.InvalidData;
        return .{
            .requested_iso = requested_iso,
            .noise_floor = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "noiseFloorCoeff_ISO",
                .continuous,
            ),
            .noise_poisson = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "noisePoissonCoeff_ISO",
                .continuous,
            ),
            .base_gain = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "gain",
                .discrete,
            ),
            .sensor_range_gain = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "sensorRangeGain",
                .discrete,
            ),
            .sharpen_amount = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "USMAmount_default",
                .discrete,
            ),
            .sharpen_radius = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "USMRadius_default",
                .discrete,
            ),
            .sharpen_threshold = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "USMThreshold_default",
                .discrete,
            ),
            .anti_color_aliasing = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "antiColorAliasingBlend",
                .discrete,
            ),
            .long_exposure_cleanup = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "cleanLongExposureAmount_default",
                .discrete,
            ),
            .fine_grain = try database.resolveIsoFloat(
                camera_id,
                requested_iso,
                "FineGrain_default",
                .discrete,
            ),
        };
    }

    pub fn lensSummary(database: *Database, lens_name: []const u8) Error!LensSummary {
        var name_buffer: [text_bytes_max]u8 = undefined;
        const name_normalized = try normalizeIdentity(&name_buffer, lens_name);
        var statement = try database.prepare(
            \\SELECT lens.lens_id, lens.full_name,
            \\       (SELECT COUNT(*) FROM lens_node WHERE lens_id = lens.lens_id),
            \\       (SELECT COUNT(*) FROM lens_attribute WHERE lens_id = lens.lens_id)
            \\FROM lens_alias AS alias JOIN lens USING(lens_id)
            \\WHERE alias.name_normalized = ?1
        );
        defer statement.deinit();
        try statement.bindText(1, name_normalized);
        if (try statement.step() != .row) return error.NotFound;
        const summary = LensSummary{
            .lens_id = try Text.init(try statement.columnText(0)),
            .full_name = try Text.init(try statement.columnText(1)),
            .node_count = try statement.columnU32(2),
            .attribute_count = try statement.columnU32(3),
        };
        if (try statement.step() != .done) return error.Ambiguous;
        return summary;
    }

    pub fn profileSummary(
        database: *Database,
        profile_id: []const u8,
    ) Error!ProfileSummary {
        var statement = try database.prepare(
            \\SELECT profile.profile_id, profile.byte_size, profile.tag_count,
            \\       mft2.input_channels, mft2.output_channels, mft2.grid_points,
            \\       mft2.input_entries, mft2.output_entries
            \\FROM input_profile AS profile
            \\JOIN input_profile_mft2 AS mft2 USING(profile_id)
            \\WHERE profile.profile_id = ?1
        );
        defer statement.deinit();
        try statement.bindText(1, profile_id);
        if (try statement.step() != .row) return error.NotFound;
        const summary = ProfileSummary{
            .profile_id = try Text.init(try statement.columnText(0)),
            .byte_size = try statement.columnU32(1),
            .tag_count = try statement.columnU16(2),
            .input_channels = try statement.columnU8(3),
            .output_channels = try statement.columnU8(4),
            .grid_points = try statement.columnU8(5),
            .input_entries = try statement.columnU16(6),
            .output_entries = try statement.columnU16(7),
        };
        if (try statement.step() != .done) return error.Ambiguous;
        return summary;
    }

    pub fn loadFilmCurve(database: *Database, curve_id: []const u8) Error!FilmCurve {
        var header = try database.prepare(
            "SELECT curve_id, format_version, flags FROM film_curve WHERE curve_id = ?1",
        );
        defer header.deinit();
        try header.bindText(1, curve_id);
        if (try header.step() != .row) return error.NotFound;
        var curve = FilmCurve{
            .curve_id = try Text.init(try header.columnText(0)),
            .format_version = try header.columnU32(1),
            .flags = try header.columnU32(2),
        };
        if (try header.step() != .done) return error.Ambiguous;

        var points = try database.prepare(
            \\SELECT component, point_index, x, y FROM film_curve_point
            \\WHERE curve_id = ?1 ORDER BY component, point_index
        );
        defer points.deinit();
        try points.bindText(1, curve_id);
        var row_count: u32 = 0;
        while (try points.step() == .row) {
            row_count += 1;
            if (row_count > 3 * curve_points_max) return error.InvalidData;
            const component = try points.columnText(0);
            const point_index = try points.columnU8(1);
            if (point_index >= curve_points_max) return error.InvalidData;
            const point = Point{
                .x = try points.columnF64(2),
                .y = try points.columnF64(3),
            };
            try putPoint(&curve, component, point_index, point);
        }
        if (row_count == 0) return error.InvalidData;
        return curve;
    }

    pub fn loadMft2(
        database: *Database,
        gpa: std.mem.Allocator,
        profile_id: []const u8,
    ) Error!Mft2 {
        var statement = try database.prepare(
            \\SELECT input_channels, output_channels, grid_points,
            \\       input_entries, output_entries, matrix_s15fixed16,
            \\       input_tables_u16be, clut_u16be, output_tables_u16be
            \\FROM input_profile_mft2 WHERE profile_id = ?1
        );
        defer statement.deinit();
        try statement.bindText(1, profile_id);
        if (try statement.step() != .row) return error.NotFound;

        const matrix = try statement.columnBlob(5);
        const input_tables = try statement.columnBlob(6);
        const clut = try statement.columnBlob(7);
        const output_tables = try statement.columnBlob(8);
        const total_bytes: u32 = @intCast(
            matrix.len + input_tables.len + clut.len + output_tables.len,
        );
        if (total_bytes > profile_blob_bytes_max) return error.BlobTooLarge;
        const storage = gpa.alloc(u8, total_bytes) catch return error.OutOfMemory;
        errdefer gpa.free(storage);

        var cursor: u32 = 0;
        const matrix_copy = copyBlob(storage, &cursor, matrix);
        const input_copy = copyBlob(storage, &cursor, input_tables);
        const clut_copy = copyBlob(storage, &cursor, clut);
        const output_copy = copyBlob(storage, &cursor, output_tables);
        assert(cursor == storage.len);

        const result = Mft2{
            .profile_id = try Text.init(profile_id),
            .input_channels = try statement.columnU8(0),
            .output_channels = try statement.columnU8(1),
            .grid_points = try statement.columnU8(2),
            .input_entries = try statement.columnU16(3),
            .output_entries = try statement.columnU16(4),
            .storage = storage,
            .matrix_s15fixed16 = matrix_copy,
            .input_tables_u16be = input_copy,
            .clut_u16be = clut_copy,
            .output_tables_u16be = output_copy,
        };
        try validateMft2(result);
        if (try statement.step() != .done) return error.Ambiguous;
        return result;
    }

    fn resolveCamera(
        database: *Database,
        metadata: *const dng.Metadata,
    ) Error!CameraSelection {
        if (metadata.make.len == 0 or metadata.model.len == 0) {
            return .{ .generic_fallback = .capture_fact_missing };
        }
        const defaults = database.cameraDefaults(
            metadata.make.slice(),
            metadata.model.slice(),
        ) catch |err| {
            const reason = selectionFallbackReason(err, .unsupported_camera) orelse return err;
            return .{ .generic_fallback = reason };
        };
        return .{ .resolved = defaults };
    }

    fn resolveIso(
        database: *Database,
        metadata: *const dng.Metadata,
        camera: CameraSelection,
    ) Error!IsoSelection {
        const defaults = switch (camera) {
            .generic_fallback => return .{ .skipped = .unsupported_camera },
            .resolved => |value| value,
        };
        const requested_iso = metadata.effective_iso orelse metadata.iso orelse {
            return .{ .skipped = .iso_unavailable };
        };
        const resolved = database.isoDefaults(
            defaults.camera_id.slice(),
            requested_iso,
        ) catch |err| {
            const reason = selectionFallbackReason(err, .iso_unavailable) orelse return err;
            return .{ .skipped = reason };
        };
        return .{ .resolved = resolved };
    }

    fn resolveLens(
        database: *Database,
        metadata: *const dng.Metadata,
        options: ResolveOptions,
    ) Error!LensSelection {
        if (!options.lens_corrections_enabled) {
            return .{ .correction_off = .correction_disabled };
        }
        if (metadata.lens.len == 0) {
            return .{ .correction_off = .capture_fact_missing };
        }
        const summary = database.lensSummary(metadata.lens.slice()) catch |err| {
            const reason = selectionFallbackReason(err, .unsupported_lens) orelse return err;
            return .{ .correction_off = reason };
        };
        return .{ .resolved = summary };
    }

    fn validateSchema(database: *Database) Error!void {
        var statement = try database.prepare("PRAGMA user_version");
        defer statement.deinit();
        if (try statement.step() != .row) return error.SchemaMismatch;
        const version = try statement.columnU32(0);
        if (version != schema_version_expected) return error.SchemaMismatch;
        if (try statement.step() != .done) return error.SchemaMismatch;
        const bundle_id = try database.bundleId();
        if (bundle_id.len == 0) return error.SchemaMismatch;
    }

    fn resolveIsoFloat(
        database: *Database,
        camera_id: []const u8,
        requested_iso: f32,
        property_name: []const u8,
        behavior: IsoPropertyBehavior,
    ) Error!?IsoValue {
        const lower = try database.isoNodeLower(camera_id, requested_iso, property_name) orelse {
            return null;
        };
        if (lower.iso == requested_iso) return isoValueFromNode(lower, .exact);
        if (behavior == .discrete) return isoValueFromNode(lower, .inherited);

        const upper = try database.isoNodeUpper(camera_id, requested_iso, property_name) orelse {
            return isoValueFromNode(lower, .inherited);
        };
        assert(lower.iso < requested_iso);
        assert(upper.iso > requested_iso);
        assert(lower.ordinal < upper.ordinal);
        if (try database.isoRangeHasDiscontinuity(
            camera_id,
            lower.ordinal,
            upper.ordinal,
        )) {
            return isoValueFromNode(lower, .inherited);
        }

        const range = upper.iso - lower.iso;
        assert(range > 0);
        const weight = (requested_iso - lower.iso) / range;
        assert(weight > 0);
        assert(weight < 1);
        const value = lower.value + (upper.value - lower.value) * weight;
        if (!std.math.isFinite(value)) return error.InvalidData;
        return .{
            .value = value,
            .iso_record_id = lower.iso_record_id,
            .node_iso = lower.iso,
            .upper_iso_record_id = upper.iso_record_id,
            .upper_node_iso = upper.iso,
            .resolution = .interpolated,
        };
    }

    fn isoNodeLower(
        database: *Database,
        camera_id: []const u8,
        requested_iso: f32,
        property_name: []const u8,
    ) Error!?IsoNode {
        var statement = try database.prepare(
            \\SELECT CAST(property.value AS REAL), node.iso_record_id, node.iso,
            \\       node.iso_ordinal
            \\FROM camera_iso_property AS property
            \\JOIN camera_iso AS node USING(camera_id, iso_ordinal)
            \\WHERE property.camera_id = ?1 AND node.iso <= ?2 AND property.name = ?3
            \\ORDER BY node.iso DESC, node.iso_ordinal DESC LIMIT 1
        );
        defer statement.deinit();
        try statement.bindText(1, camera_id);
        try statement.bindF64(2, requested_iso);
        try statement.bindText(3, property_name);
        if (try statement.step() == .done) return null;
        const node = IsoNode{
            .value = try statement.columnF32(0),
            .iso_record_id = try Text.init(try statement.columnText(1)),
            .iso = try statement.columnF32(2),
            .ordinal = try statement.columnU32(3),
        };
        if (try statement.step() != .done) return error.Ambiguous;
        return node;
    }

    fn isoNodeUpper(
        database: *Database,
        camera_id: []const u8,
        requested_iso: f32,
        property_name: []const u8,
    ) Error!?IsoNode {
        var statement = try database.prepare(
            \\SELECT CAST(property.value AS REAL), node.iso_record_id, node.iso,
            \\       node.iso_ordinal
            \\FROM camera_iso_property AS property
            \\JOIN camera_iso AS node USING(camera_id, iso_ordinal)
            \\WHERE property.camera_id = ?1 AND node.iso > ?2 AND property.name = ?3
            \\ORDER BY node.iso ASC, node.iso_ordinal ASC LIMIT 1
        );
        defer statement.deinit();
        try statement.bindText(1, camera_id);
        try statement.bindF64(2, requested_iso);
        try statement.bindText(3, property_name);
        if (try statement.step() == .done) return null;
        const node = IsoNode{
            .value = try statement.columnF32(0),
            .iso_record_id = try Text.init(try statement.columnText(1)),
            .iso = try statement.columnF32(2),
            .ordinal = try statement.columnU32(3),
        };
        if (try statement.step() != .done) return error.Ambiguous;
        return node;
    }

    fn isoRangeHasDiscontinuity(
        database: *Database,
        camera_id: []const u8,
        ordinal_lower: u32,
        ordinal_upper: u32,
    ) Error!bool {
        assert(ordinal_lower < ordinal_upper);
        var statement = try database.prepare(
            \\SELECT 1 FROM camera_iso_property
            \\WHERE camera_id = ?1 AND iso_ordinal > ?2 AND iso_ordinal <= ?3
            \\  AND name IN ('gain', 'sensorRangeGain') LIMIT 1
        );
        defer statement.deinit();
        try statement.bindText(1, camera_id);
        try statement.bindU32(2, ordinal_lower);
        try statement.bindU32(3, ordinal_upper);
        return switch (try statement.step()) {
            .row => true,
            .done => false,
        };
    }

    fn prepare(database: *Database, sql: [*:0]const u8) Error!Statement {
        var handle_optional: ?*c.sqlite3_stmt = null;
        const result = c.sqlite3_prepare_v2(
            database.handle,
            sql,
            -1,
            &handle_optional,
            null,
        );
        if (result != c.SQLITE_OK) return error.QueryFailed;
        return .{ .handle = handle_optional orelse return error.QueryFailed };
    }
};

const Step = enum { row, done };

const Statement = struct {
    handle: *c.sqlite3_stmt,

    fn deinit(statement: *Statement) void {
        const result = c.sqlite3_finalize(statement.handle);
        assert(result == c.SQLITE_OK);
        statement.* = undefined;
    }

    fn bindText(statement: *Statement, index: u8, value: []const u8) Error!void {
        const result = c.sqlite3_bind_text(
            statement.handle,
            index,
            value.ptr,
            @intCast(value.len),
            // Every bound slice outlives stepping/finalizing this statement.
            null,
        );
        if (result != c.SQLITE_OK) return error.QueryFailed;
    }

    fn bindF64(statement: *Statement, index: u8, value: f64) Error!void {
        if (!std.math.isFinite(value)) return error.InvalidData;
        const result = c.sqlite3_bind_double(statement.handle, index, value);
        if (result != c.SQLITE_OK) return error.QueryFailed;
    }

    fn bindU32(statement: *Statement, index: u8, value: u32) Error!void {
        const result = c.sqlite3_bind_int64(statement.handle, index, @intCast(value));
        if (result != c.SQLITE_OK) return error.QueryFailed;
    }

    fn step(statement: *Statement) Error!Step {
        return switch (c.sqlite3_step(statement.handle)) {
            c.SQLITE_ROW => .row,
            c.SQLITE_DONE => .done,
            else => error.QueryFailed,
        };
    }

    fn columnText(statement: *Statement, index: u8) Error![]const u8 {
        if (c.sqlite3_column_type(statement.handle, index) != c.SQLITE_TEXT) {
            return error.InvalidData;
        }
        const bytes = c.sqlite3_column_text(statement.handle, index);
        const len = c.sqlite3_column_bytes(statement.handle, index);
        if (bytes == null) return error.InvalidData;
        if (len < 0) return error.InvalidData;
        return bytes[0..@intCast(len)];
    }

    fn columnBlob(statement: *Statement, index: u8) Error![]const u8 {
        if (c.sqlite3_column_type(statement.handle, index) != c.SQLITE_BLOB) {
            return error.InvalidData;
        }
        const bytes = c.sqlite3_column_blob(statement.handle, index);
        const len = c.sqlite3_column_bytes(statement.handle, index);
        if (len < 0) return error.InvalidData;
        if (len == 0) return &.{};
        const pointer: [*]const u8 = @ptrCast(bytes orelse return error.InvalidData);
        return pointer[0..@intCast(len)];
    }

    fn columnF64(statement: *Statement, index: u8) Error!f64 {
        const value = c.sqlite3_column_double(statement.handle, index);
        if (!std.math.isFinite(value)) return error.InvalidData;
        return value;
    }

    fn columnF32(statement: *Statement, index: u8) Error!f32 {
        const value = try statement.columnF64(index);
        if (value > std.math.floatMax(f32)) return error.InvalidData;
        if (value < -std.math.floatMax(f32)) return error.InvalidData;
        return @floatCast(value);
    }

    fn columnU32(statement: *Statement, index: u8) Error!u32 {
        const value = c.sqlite3_column_int64(statement.handle, index);
        if (value < 0) return error.InvalidData;
        if (value > std.math.maxInt(u32)) return error.InvalidData;
        return @intCast(value);
    }

    fn columnU16(statement: *Statement, index: u8) Error!u16 {
        const value = try statement.columnU32(index);
        if (value > std.math.maxInt(u16)) return error.InvalidData;
        return @intCast(value);
    }

    fn columnU8(statement: *Statement, index: u8) Error!u8 {
        const value = try statement.columnU32(index);
        if (value > std.math.maxInt(u8)) return error.InvalidData;
        return @intCast(value);
    }

    fn columnBool(statement: *Statement, index: u8) Error!bool {
        const value = try statement.columnU8(index);
        return switch (value) {
            0 => false,
            1 => true,
            else => error.InvalidData,
        };
    }
};

fn isoValueFromNode(node: IsoNode, resolution: IsoResolution) IsoValue {
    assert(resolution != .interpolated);
    return .{
        .value = node.value,
        .iso_record_id = node.iso_record_id,
        .node_iso = node.iso,
        .resolution = resolution,
    };
}

fn selectionFallbackReason(
    err: Error,
    not_found_reason: FallbackReason,
) ?FallbackReason {
    return switch (err) {
        error.NotFound => not_found_reason,
        error.Ambiguous => .ambiguous_record,
        error.InvalidData, error.TextTooLong, error.BlobTooLarge => .malformed_record,
        else => null,
    };
}

fn normalizeIdentity(buffer: []u8, value: []const u8) Error![]const u8 {
    var len: u32 = 0;
    for (value) |byte| {
        if (std.ascii.isAlphanumeric(byte)) {
            if (len == buffer.len) return error.TextTooLong;
            buffer[len] = std.ascii.toLower(byte);
            len += 1;
        }
    }
    if (len == 0) return error.InvalidData;
    return buffer[0..len];
}

fn copyBlob(storage: []u8, cursor: *u32, source: []const u8) []const u8 {
    assert(cursor.* <= storage.len);
    assert(source.len <= storage.len - cursor.*);
    const start = cursor.*;
    const end: u32 = @intCast(start + source.len);
    @memcpy(storage[start..end], source);
    cursor.* = end;
    return storage[start..end];
}

fn validateMft2(mft2: Mft2) Error!void {
    if (mft2.input_channels == 0) return error.InvalidData;
    if (mft2.output_channels == 0) return error.InvalidData;
    if (mft2.grid_points < 2) return error.InvalidData;
    if (mft2.matrix_s15fixed16.len != 36) return error.InvalidData;
    const input_bytes = @as(u32, mft2.input_channels) * mft2.input_entries * 2;
    const output_bytes = @as(u32, mft2.output_channels) * mft2.output_entries * 2;
    var clut_values: u32 = mft2.output_channels;
    var dimension: u8 = 0;
    while (dimension < mft2.input_channels) : (dimension += 1) {
        clut_values = std.math.mul(u32, clut_values, mft2.grid_points) catch {
            return error.InvalidData;
        };
    }
    const clut_bytes = std.math.mul(u32, clut_values, 2) catch return error.InvalidData;
    if (mft2.input_tables_u16be.len != input_bytes) return error.InvalidData;
    if (mft2.output_tables_u16be.len != output_bytes) return error.InvalidData;
    if (mft2.clut_u16be.len != clut_bytes) return error.InvalidData;
}

fn putPoint(curve: *FilmCurve, component: []const u8, index: u8, point: Point) Error!void {
    if (!std.math.isFinite(point.x)) return error.InvalidData;
    if (!std.math.isFinite(point.y)) return error.InvalidData;
    const next_count: u8 = index + 1;
    if (std.mem.eql(u8, component, "film")) {
        if (index != curve.film_count) return error.InvalidData;
        curve.film[index] = point;
        curve.film_count = next_count;
    } else if (std.mem.eql(u8, component, "ccd")) {
        if (index != curve.ccd_count) return error.InvalidData;
        curve.ccd[index] = point;
        curve.ccd_count = next_count;
    } else if (std.mem.eql(u8, component, "contrast")) {
        if (index != curve.contrast_count) return error.InvalidData;
        curve.contrast[index] = point;
        curve.contrast_count = next_count;
    } else {
        return error.InvalidData;
    }
}

test "the committed calibration bundle resolves the two initial cameras" {
    var database = try Database.open(database_path_default);
    defer database.deinit();

    const bundle_id = try database.bundleId();
    try std.testing.expectEqualStrings(
        "calibration.capture-one-16.7.3.31.initial-canon.v1",
        bundle_id.slice(),
    );

    const one_dx = try database.cameraDefaults("Canon", "EOS-1D X Mark II");
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), one_dx.base_gain, 0.0001);
    try std.testing.expectApproxEqAbs(
        @as(f32, 1.15),
        one_dx.sensor_range_gain,
        0.0001,
    );

    const r3 = try database.cameraDefaults("Canon Inc.", "EOS R3");
    try std.testing.expectApproxEqAbs(@as(f32, 1.07), r3.base_gain, 0.0001);
    try std.testing.expect(r3.adaptive_green_enabled);
}

test "ISO defaults inherit sparse changes without crossing upward" {
    var database = try Database.open(database_path_default);
    defer database.deinit();
    const camera = try database.cameraDefaults("Canon", "EOS-1D X Mark II");
    const iso_6400 = try database.isoDefaults(camera.camera_id.slice(), 6400);
    try std.testing.expectApproxEqAbs(
        @as(f32, 0.0106085),
        iso_6400.noise_floor.?.value,
        0.0000001,
    );
    try std.testing.expectEqual(@as(f32, 140), iso_6400.sharpen_amount.?.value);
    try std.testing.expectEqual(@as(f32, 1), iso_6400.anti_color_aliasing.?.value);
    try std.testing.expectEqual(@as(f32, 6400), iso_6400.sharpen_amount.?.node_iso);
    try std.testing.expectEqual(@as(f32, 3200), iso_6400.anti_color_aliasing.?.node_iso);
    try std.testing.expectEqual(IsoResolution.exact, iso_6400.sharpen_amount.?.resolution);
    try std.testing.expectEqual(
        IsoResolution.inherited,
        iso_6400.anti_color_aliasing.?.resolution,
    );
}

test "ISO resolution interpolates continuous fields but stops at gain boundaries" {
    var database = try Database.open(database_path_default);
    defer database.deinit();
    const camera = try database.cameraDefaults("Canon", "EOS-1D X Mark II");

    const iso_600 = try database.isoDefaults(camera.camera_id.slice(), 600);
    const floor_600 = iso_600.noise_floor.?;
    try std.testing.expectEqual(IsoResolution.interpolated, floor_600.resolution);
    try std.testing.expectEqual(@as(f32, 400), floor_600.node_iso);
    try std.testing.expectEqual(@as(?f32, 800), floor_600.upper_node_iso);
    try std.testing.expectApproxEqAbs(@as(f32, 0.02421125), floor_600.value, 0.0000001);

    const iso_125 = try database.isoDefaults(camera.camera_id.slice(), 125);
    const floor_125 = iso_125.noise_floor.?;
    try std.testing.expectEqual(IsoResolution.inherited, floor_125.resolution);
    try std.testing.expectEqual(@as(f32, 100), floor_125.node_iso);
    try std.testing.expectEqual(@as(?f32, null), floor_125.upper_node_iso);
}

test "complete resolver distinguishes resolved partial fallback and correction-off states" {
    var database = try Database.open(database_path_default);
    defer database.deinit();

    var metadata = testMetadata(
        "Canon",
        "EOS R3",
        "Canon EF 24-70mm f/2.8L II USM",
        100,
    );
    metadata.effective_iso = 1600;
    const resolved = try database.resolve(&metadata, .{});
    try std.testing.expectEqual(ResolutionState.resolved, resolved.state);
    switch (resolved.iso) {
        .skipped => return error.TestUnexpectedResult,
        .resolved => |iso| {
            try std.testing.expectEqual(@as(f32, 1600), iso.requested_iso);
            try std.testing.expectEqual(IsoResolution.exact, iso.anti_color_aliasing.?.resolution);
        },
    }

    const disabled = try database.resolve(&metadata, .{ .lens_corrections_enabled = false });
    try std.testing.expectEqual(ResolutionState.partial, disabled.state);
    switch (disabled.lens) {
        .resolved => return error.TestUnexpectedResult,
        .correction_off => |reason| {
            try std.testing.expectEqual(FallbackReason.correction_disabled, reason);
        },
    }

    const unknown = testMetadata("Unknown", "Camera", "", 100);
    const fallback = try database.resolve(&unknown, .{});
    try std.testing.expectEqual(ResolutionState.generic_fallback, fallback.state);
    switch (fallback.camera) {
        .resolved => return error.TestUnexpectedResult,
        .generic_fallback => |reason| {
            try std.testing.expectEqual(FallbackReason.unsupported_camera, reason);
        },
    }
}

test "initial camera and lens selection tables resolve every committed alias" {
    var database = try Database.open(database_path_default);
    defer database.deinit();

    const cameras = [_]struct {
        make: []const u8,
        model: []const u8,
        camera_id: []const u8,
    }{
        .{
            .make = "Canon",
            .model = "EOS-1D X Mark II",
            .camera_id = "camera.capture-one.canon-eos-1d-x-mark-ii.v1",
        },
        .{
            .make = "Canon Inc.",
            .model = "EOS-1D X Mark II",
            .camera_id = "camera.capture-one.canon-eos-1d-x-mark-ii.v1",
        },
        .{
            .make = "Canon",
            .model = "EOS R3",
            .camera_id = "camera.capture-one.canon-eos-r3.v1",
        },
        .{
            .make = "Canon Inc.",
            .model = "EOS R3",
            .camera_id = "camera.capture-one.canon-eos-r3.v1",
        },
    };
    for (cameras) |camera_case| {
        const camera = try database.cameraDefaults(camera_case.make, camera_case.model);
        try std.testing.expectEqualStrings(camera_case.camera_id, camera.camera_id.slice());
    }

    const lenses = [_]struct {
        alias: []const u8,
        lens_id: []const u8,
    }{
        .{
            .alias = "Canon EF 24-70mm f/2.8L II USM",
            .lens_id = "lens.capture-one.66B9FA28-EFDB-4C38-ABEE-654C84967049.v1",
        },
        .{
            .alias = "EF24-70mm f/2.8L II USM",
            .lens_id = "lens.capture-one.66B9FA28-EFDB-4C38-ABEE-654C84967049.v1",
        },
        .{
            .alias = "Canon EF 70-200mm f/4 L IS USM",
            .lens_id = "lens.capture-one.A57EBD6F-86D3-47FC-A295-F75DC0EA3B7C.v1",
        },
        .{
            .alias = "EF70-200mm f/4L IS USM",
            .lens_id = "lens.capture-one.A57EBD6F-86D3-47FC-A295-F75DC0EA3B7C.v1",
        },
        .{
            .alias = "Canon EF 24-105mm f/4L IS II USM",
            .lens_id = "lens.capture-one.D52D61FC-82C8-4E2F-96AF-70BBA6538D40.v1",
        },
        .{
            .alias = "EF24-105mm f/4L IS II USM",
            .lens_id = "lens.capture-one.D52D61FC-82C8-4E2F-96AF-70BBA6538D40.v1",
        },
    };
    for (lenses) |lens_case| {
        const lens = try database.lensSummary(lens_case.alias);
        try std.testing.expectEqualStrings(lens_case.lens_id, lens.lens_id.slice());
    }
}

test "selection fallback mapping covers every recoverable record failure" {
    try std.testing.expectEqual(
        FallbackReason.unsupported_camera,
        selectionFallbackReason(error.NotFound, .unsupported_camera).?,
    );
    try std.testing.expectEqual(
        FallbackReason.unsupported_lens,
        selectionFallbackReason(error.NotFound, .unsupported_lens).?,
    );
    try std.testing.expectEqual(
        FallbackReason.ambiguous_record,
        selectionFallbackReason(error.Ambiguous, .unsupported_camera).?,
    );
    for ([_]Error{ error.InvalidData, error.TextTooLong, error.BlobTooLarge }) |err| {
        try std.testing.expectEqual(
            FallbackReason.malformed_record,
            selectionFallbackReason(err, .unsupported_camera).?,
        );
    }
    try std.testing.expectEqual(
        @as(?FallbackReason, null),
        selectionFallbackReason(error.OpenFailed, .unsupported_camera),
    );
}

test "profile curves and lens records are complete and bounded" {
    const gpa = std.testing.allocator;
    var database = try Database.open(database_path_default);
    defer database.deinit();
    const camera = try database.cameraDefaults("Canon", "EOS R3");

    const summary = try database.profileSummary(camera.input_profile_id.slice());
    try std.testing.expectEqual(@as(u8, 33), summary.grid_points);
    try std.testing.expectEqual(@as(u16, 1025), summary.input_entries);

    var mft2 = try database.loadMft2(gpa, camera.input_profile_id.slice());
    defer mft2.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 215_622), mft2.clut_u16be.len);

    const curve = try database.loadFilmCurve(camera.film_curve_id.slice());
    try std.testing.expectEqual(@as(u8, 10), curve.film_count);
    try std.testing.expectEqual(@as(u8, 10), curve.ccd_count);
    try std.testing.expectEqual(@as(u8, 4), curve.contrast_count);

    const lens = try database.lensSummary("Canon EF 24-70mm f/2.8L II USM");
    try std.testing.expectEqual(@as(u32, 231), lens.node_count);
    try std.testing.expectEqual(@as(u32, 321), lens.attribute_count);

    const lens_wide = try database.lensSummary("Canon EF24-105mm f/4L IS II USM");
    try std.testing.expectEqual(@as(u32, 460), lens_wide.node_count);
    const lens_tele = try database.lensSummary("EF70-200mm f/4L IS USM");
    try std.testing.expectEqual(@as(u32, 190), lens_tele.node_count);
}

fn testMetadata(make: []const u8, model: []const u8, lens: []const u8, iso: f32) dng.Metadata {
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
        .make = dng.Text.init(make),
        .model = dng.Text.init(model),
        .lens = dng.Text.init(lens),
        .iso = iso,
    };
}
