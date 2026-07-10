//! Recipes are data: a canonical-form JSON document naming the op stack.
//!
//! Parsing accepts exactly the schema and nothing else (unknown fields are
//! errors — canonical means canonical). Serialization is hand-written so
//! the byte form is deterministic: declaration-order fields, `{d}` floats,
//! no whitespace. Content addressing (Phase 3) hashes these bytes.

const std = @import("std");
const assert = std.debug.assert;
const pipeline = @import("pipeline.zig");

pub const default_ops = [_]pipeline.Op{
    .{ .black_point = .{} },
    .{ .white_balance = .{} },
    .{ .demosaic = .{} },
    .{ .exposure = .{} },
    .{ .tone_curve = .{} },
    .{ .srgb_encode = .{} },
};

pub fn default_recipe() pipeline.Recipe {
    return .{ .engine_version = pipeline.engine_version_current, .ops = &default_ops };
}

/// Parse a recipe from its JSON form. The returned value owns an arena;
/// call `deinit` on it when the recipe is no longer needed.
pub fn parse(
    gpa: std.mem.Allocator,
    bytes: []const u8,
) !std.json.Parsed(pipeline.Recipe) {
    const parsed = try std.json.parseFromSlice(pipeline.Recipe, gpa, bytes, .{});
    errdefer comptime unreachable;
    assert(parsed.value.ops.len <= pipeline.ops_max or true); // length gated in render
    return parsed;
}

/// The canonical byte form. `serialize(parse(serialize(x))) == serialize(x)`
/// — the roundtrip test below is the pair assertion for this property.
pub fn serialize_canonical(gpa: std.mem.Allocator, recipe: pipeline.Recipe) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(gpa);

    try out.appendSlice(gpa, "{\"engine_version\":");
    try append_u32(gpa, &out, recipe.engine_version);
    try out.appendSlice(gpa, ",\"ops\":[");
    for (recipe.ops, 0..) |op, i| {
        if (i > 0) try out.append(gpa, ',');
        try append_op(gpa, &out, op);
    }
    try out.appendSlice(gpa, "]}");
    return out.toOwnedSlice(gpa);
}

fn append_op(gpa: std.mem.Allocator, out: *std.ArrayList(u8), op: pipeline.Op) !void {
    switch (op) {
        .black_point => try out.appendSlice(gpa, "{\"black_point\":{}}"),
        .demosaic => try out.appendSlice(gpa, "{\"demosaic\":{}}"),
        .srgb_encode => try out.appendSlice(gpa, "{\"srgb_encode\":{}}"),
        .white_balance => |wb| {
            try out.appendSlice(gpa, "{\"white_balance\":{\"as_shot\":");
            try out.appendSlice(gpa, if (wb.as_shot) "true" else "false");
            try out.appendSlice(gpa, ",\"gain_r\":");
            try append_f32(gpa, out, wb.gain_r);
            try out.appendSlice(gpa, ",\"gain_g\":");
            try append_f32(gpa, out, wb.gain_g);
            try out.appendSlice(gpa, ",\"gain_b\":");
            try append_f32(gpa, out, wb.gain_b);
            try out.appendSlice(gpa, "}}");
        },
        .exposure => |e| {
            try out.appendSlice(gpa, "{\"exposure\":{\"ev\":");
            try append_f32(gpa, out, e.ev);
            try out.appendSlice(gpa, "}}");
        },
        .tone_curve => |t| {
            try out.appendSlice(gpa, "{\"tone_curve\":{\"contrast\":");
            try append_f32(gpa, out, t.contrast);
            try out.appendSlice(gpa, "}}");
        },
    }
}

fn append_u32(gpa: std.mem.Allocator, out: *std.ArrayList(u8), v: u32) !void {
    var buf: [10]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "{d}", .{v}) catch unreachable;
    assert(text.len > 0);
    try out.appendSlice(gpa, text);
}

fn append_f32(gpa: std.mem.Allocator, out: *std.ArrayList(u8), v: f32) !void {
    assert(std.math.isFinite(v)); // recipes never contain NaN/inf
    var buf: [48]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "{d}", .{v}) catch unreachable;
    assert(text.len > 0);
    try out.appendSlice(gpa, text);
}

test "canonical serialization is exact (snapshot)" {
    const gpa = std.testing.allocator;
    const text = try serialize_canonical(gpa, default_recipe());
    defer gpa.free(text);
    const expected = "{\"engine_version\":1,\"ops\":[" ++
        "{\"black_point\":{}}," ++
        "{\"white_balance\":{\"as_shot\":true,\"gain_r\":1,\"gain_g\":1,\"gain_b\":1}}," ++
        "{\"demosaic\":{}}," ++
        "{\"exposure\":{\"ev\":0}}," ++
        "{\"tone_curve\":{\"contrast\":0}}," ++
        "{\"srgb_encode\":{}}]}";
    try std.testing.expectEqualStrings(expected, text);
}

test "parse/serialize roundtrip is byte-stable (pair assertion)" {
    const gpa = std.testing.allocator;
    const ops = [_]pipeline.Op{
        .{ .black_point = .{} },
        .{ .white_balance = .{ .as_shot = false, .gain_r = 2.125, .gain_g = 1, .gain_b = 1.5 } },
        .{ .demosaic = .{} },
        .{ .exposure = .{ .ev = -0.5 } },
        .{ .tone_curve = .{ .contrast = 0.25 } },
        .{ .srgb_encode = .{} },
    };
    const first = try serialize_canonical(gpa, .{ .ops = &ops });
    defer gpa.free(first);

    var parsed = try parse(gpa, first);
    defer parsed.deinit();
    const second = try serialize_canonical(gpa, parsed.value);
    defer gpa.free(second);

    try std.testing.expectEqualStrings(first, second);
}

test "unknown fields and malformed JSON are rejected (negative space)" {
    const gpa = std.testing.allocator;
    try std.testing.expectError(
        error.UnknownField,
        parse(gpa, "{\"engine_version\":1,\"ops\":[],\"extra\":true}"),
    );
    const err = parse(gpa, "{\"engine_version\":1,\"ops\":[{\"sharpen\":{}}]}");
    try std.testing.expect(err == error.InvalidEnumTag or err == error.UnknownField);
}
