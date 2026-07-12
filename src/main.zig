//! CLI entry point for banksia.
//!
//!   banksia render <raw.dng> <recipe.json> <out.png>
//!   banksia synth <out.dng> [<width> <height>]
//!       write a synthetic demo DNG (dev fixture; defaults to 512x384)
//!   banksia convert-dng <raw> <out.dng> <storage>
//!       create a deterministic native-DNG corpus derivative
//!   banksia inspect <raw> [--decode|--render]
//!       parse metadata; optionally unpack the mosaic or complete a v2 render
//!
//! The CLI reads inputs itself; emu stays a pure function over the bytes
//! it is handed, and every output byte goes through wombat (which owns
//! every byte on disk — tidy enforces it).

const std = @import("std");
const emu = @import("emu");
const wombat = @import("wombat");

const file_bytes_max = std.Io.Limit.limited(512 * 1024 * 1024);

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next(); // argv[0]
    const command = args.next() orelse return usage();

    if (std.mem.eql(u8, command, "render")) {
        const raw_path = args.next() orelse return usage();
        const recipe_path = args.next() orelse return usage();
        const out_path = args.next() orelse return usage();
        if (args.next() != null) return usage();
        return render_file(gpa, io, raw_path, recipe_path, out_path);
    }
    if (std.mem.eql(u8, command, "inspect")) {
        const raw_path = args.next() orelse return usage();
        var decode_pixels = false;
        var render_pixels = false;
        if (args.next()) |option| {
            if (std.mem.eql(u8, option, "--decode")) {
                decode_pixels = true;
            } else if (std.mem.eql(u8, option, "--render")) {
                decode_pixels = true;
                render_pixels = true;
            } else return usage();
        }
        if (args.next() != null) return usage();
        return inspect_file(gpa, io, raw_path, decode_pixels, render_pixels);
    }
    if (std.mem.eql(u8, command, "convert-dng")) {
        const raw_path = args.next() orelse return usage();
        const out_path = args.next() orelse return usage();
        const storage_name = args.next() orelse return usage();
        if (args.next() != null) return usage();
        const storage = storage_parse(storage_name) orelse return usage();
        return convert_dng_file(gpa, io, raw_path, out_path, storage);
    }
    if (std.mem.eql(u8, command, "synth")) {
        const out_path = args.next() orelse return usage();
        var width: u32 = 512;
        var height: u32 = 384;
        if (args.next()) |width_text| {
            const height_text = args.next() orelse return usage();
            width = std.fmt.parseInt(u32, width_text, 10) catch return usage();
            height = std.fmt.parseInt(u32, height_text, 10) catch return usage();
        }
        if (args.next() != null) return usage();
        if (width < 2 or height < 2) return usage();
        if (width > emu.image.edge_px_max or height > emu.image.edge_px_max) return usage();
        return synth_file(gpa, io, out_path, width, height);
    }
    return usage();
}

const FixtureStorage = enum {
    uncompressed_strip,
    uncompressed_tile,
    lossless_strip,
    lossless_tile,
};

fn storage_parse(name: []const u8) ?FixtureStorage {
    inline for (std.meta.fields(FixtureStorage)) |field| {
        if (std.mem.eql(u8, name, field.name)) return @enumFromInt(field.value);
    }
    return null;
}

fn convert_dng_file(
    gpa: std.mem.Allocator,
    io: std.Io,
    raw_path: []const u8,
    out_path: []const u8,
    storage: FixtureStorage,
) !void {
    const cwd = std.Io.Dir.cwd();
    const bytes = cwd.readFileAlloc(io, raw_path, gpa, file_bytes_max) catch |err| {
        return fail("cannot read raw '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    defer gpa.free(bytes);
    var raw = emu.raw.decode_raw(gpa, bytes) catch |err| {
        return fail("cannot decode '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    defer raw.deinit(gpa);

    const camera_to_xyz = raw.metadata.camera_to_xyz orelse {
        return fail("'{s}' has no backend camera matrix", .{raw_path});
    };
    const xyz_to_camera = emu.color.Mat3.init(camera_to_xyz).inverse() catch |err| {
        return fail("cannot invert camera matrix for '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    const blob = try corpus_dng_make(gpa, &raw, xyz_to_camera.values, storage);
    defer gpa.free(blob);
    wombat.vfs.user_file_write(io, cwd, out_path, blob) catch |err| {
        return fail("cannot write DNG '{s}': {s}", .{ out_path, @errorName(err) });
    };
    try status(io, "converted {s} -> {s} ({d} bytes, {s})\n", .{
        raw_path,
        out_path,
        blob.len,
        @tagName(storage),
    });
}

fn corpus_dng_make(
    gpa: std.mem.Allocator,
    raw: *const emu.dng.DecodedRaw,
    color_matrix: emu.dng.Matrix3x3,
    storage: FixtureStorage,
) ![]u8 {
    const active = raw.metadata.active_area;
    const crop = raw.metadata.default_crop;
    const compression: emu.dng_write.Compression = switch (storage) {
        .uncompressed_strip, .uncompressed_tile => .none,
        .lossless_strip, .lossless_tile => .lossless_jpeg,
    };
    const tile: ?emu.dng_write.Tile = switch (storage) {
        .uncompressed_tile, .lossless_tile => .{ .width = 512, .height = 256 },
        .uncompressed_strip, .lossless_strip => null,
    };
    return emu.dng_write.write(gpa, .{
        .width = raw.sensor.width,
        .height = raw.sensor.height,
        .cfa = raw.sensor.cfa,
        .black_level = @intFromFloat(@round(raw.sensor.black_level)),
        .white_level = @intFromFloat(@round(raw.sensor.white_level)),
        .wb_neutral = raw.sensor.wb_neutral,
        .color_matrix_1 = color_matrix,
        .calibration_illuminant_1 = 21,
        .make = raw.metadata.make.slice(),
        .model = raw.metadata.model.slice(),
        .unique_model = raw.metadata.unique_model.slice(),
        .lens = raw.metadata.lens.slice(),
        .iso = if (raw.metadata.iso) |iso| @intFromFloat(@round(iso)) else null,
        .orientation = raw.metadata.orientation,
        .active_area = active,
        .default_crop = .{
            .x = active.x + crop.x,
            .y = active.y + crop.y,
            .width = crop.width,
            .height = crop.height,
        },
        .bayer = raw.sensor.bayer,
        .compression = compression,
        .tile = tile,
    });
}

fn inspect_file(
    gpa: std.mem.Allocator,
    io: std.Io,
    raw_path: []const u8,
    decode_pixels: bool,
    render_pixels: bool,
) !void {
    const bytes = std.Io.Dir.cwd().readFileAlloc(io, raw_path, gpa, file_bytes_max) catch |err| {
        return fail("cannot read raw '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    defer gpa.free(bytes);
    var decoded: ?emu.dng.DecodedRaw = null;
    defer if (decoded) |*raw| raw.deinit(gpa);
    const metadata = if (decode_pixels) decoded: {
        decoded = emu.raw.decode_raw(gpa, bytes) catch |err| {
            return fail("cannot unpack '{s}': {s}", .{ raw_path, @errorName(err) });
        };
        break :decoded decoded.?.metadata;
    } else emu.raw.decode_metadata(bytes) catch |err| {
        return fail("cannot inspect '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    try status(io, "{s}: {d}x{d}, {s}, orientation={s}\n", .{
        raw_path,
        metadata.width,
        metadata.height,
        @tagName(metadata.compression),
        @tagName(metadata.orientation),
    });
    try status(io, "  active: x={d} y={d} width={d} height={d}\n", .{
        metadata.active_area.x,
        metadata.active_area.y,
        metadata.active_area.width,
        metadata.active_area.height,
    });
    try status(io, "  default crop (active-relative): x={d} y={d} width={d} height={d}\n", .{
        metadata.default_crop.x,
        metadata.default_crop.y,
        metadata.default_crop.width,
        metadata.default_crop.height,
    });
    try status(io, "  CFA: {s} {s} / {s} {s}; black={d:.3} white={d:.3}\n", .{
        @tagName(metadata.cfa[0]),
        @tagName(metadata.cfa[1]),
        @tagName(metadata.cfa[2]),
        @tagName(metadata.cfa[3]),
        metadata.black_level,
        metadata.white_level,
    });
    if (metadata.black_level_site) |levels| {
        try status(io, "  black sites: {d:.0} {d:.0} / {d:.0} {d:.0}\n", .{
            levels[0], levels[1], levels[2], levels[3],
        });
    }
    try status(io, "  as-shot neutral: {d:.6} {d:.6} {d:.6}\n", .{
        metadata.wb_neutral[0],
        metadata.wb_neutral[1],
        metadata.wb_neutral[2],
    });
    try status(io, "  camera: {s} {s}; lens={s}\n", .{
        metadata.make.slice(),
        metadata.model.slice(),
        metadata.lens.slice(),
    });
    if (metadata.unique_model.len != 0) {
        try status(io, "  unique model: {s}\n", .{metadata.unique_model.slice()});
    }
    if (metadata.iso) |iso| try status(io, "  ISO: {d:.0}\n", .{iso});
    if (metadata.capture_datetime.len != 0) {
        try status(io, "  captured: {s}.{s}\n", .{
            metadata.capture_datetime.slice(),
            metadata.capture_subsecond.slice(),
        });
    }
    try status(io, "  colour calibration: matrix1={s} matrix2={s}\n", .{
        if (metadata.color_matrix_1 != null) "yes" else "no",
        if (metadata.color_matrix_2 != null) "yes" else "no",
    });
    if (metadata.camera_to_xyz) |matrix| {
        try status(io, "  backend camera-to-XYZ:\n", .{});
        for (0..3) |row| {
            try status(io, "    {d:.6} {d:.6} {d:.6}\n", .{
                matrix[row * 3], matrix[row * 3 + 1], matrix[row * 3 + 2],
            });
        }
    }
    if (decoded) |*raw| {
        try status(io, "  decoded sensor: {d} samples ({d} bytes)\n", .{
            raw.sensor.bayer.len,
            raw.sensor.bayer.len * @sizeOf(u16),
        });
        if (render_pixels) {
            var rendered = emu.pipeline.render_decoded(
                gpa,
                raw,
                .{ .engine_version = 2, .ops = &emu.recipe.default_ops },
                .{},
            ) catch |err| {
                return fail("cannot render '{s}': {s}", .{ raw_path, @errorName(err) });
            };
            defer rendered.deinit(gpa);
            try status(io, "  rendered v2: {d}x{d} ({d} bytes)\n", .{
                rendered.width,
                rendered.height,
                rendered.rgba.len,
            });
        }
    }
}

/// A synthetic scene with structure in every channel: a horizontal
/// luminance ramp, a vertical colour sweep, and a clipped hot spot.
fn synth_file(
    gpa: std.mem.Allocator,
    io: std.Io,
    out_path: []const u8,
    width: u32,
    height: u32,
) !void {
    const black: u16 = 1024;
    const white: u16 = 15360;
    const cfa = [4]emu.dng.CfaColor{ .red, .green, .green, .blue };

    const bayer = try gpa.alloc(u16, width * height);
    defer gpa.free(bayer);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const color = cfa[((y & 1) << 1) | (x & 1)];
            const ramp = @as(u64, x) * 700_000 / (width - 1);
            const sweep: u64 = switch (color) {
                .red => @as(u64, y) * 300_000 / (height - 1),
                .green => 150_000,
                .blue => 300_000 - @as(u64, y) * 300_000 / (height - 1),
            };
            const dx = @as(i64, x) - width / 2;
            const dy = @as(i64, y) - height / 2;
            const dist2: u64 = @intCast(dx * dx + dy * dy);
            const spot = if (dist2 < 2000) 600_000 - dist2 * 300 else 0;
            const level = @min(ramp + sweep + spot, 1_000_000);
            const span: u64 = white - black;
            bayer[@as(usize, y) * width + x] =
                @intCast(black + (span * level) / 1_000_000);
        }
    }

    const blob = try emu.dng_write.write(gpa, .{
        .width = width,
        .height = height,
        .cfa = cfa,
        .black_level = black,
        .white_level = white,
        .wb_neutral = .{ 0.55, 1.0, 0.7 },
        .bayer = bayer,
    });
    defer gpa.free(blob);

    wombat.vfs.user_file_write(io, std.Io.Dir.cwd(), out_path, blob) catch {
        return fail("cannot write '{s}'", .{out_path});
    };
    try status(io, "synthesized {d}x{d} -> {s} ({d} bytes)\n", .{
        width, height, out_path, blob.len,
    });
}

fn render_file(
    gpa: std.mem.Allocator,
    io: std.Io,
    raw_path: []const u8,
    recipe_path: []const u8,
    out_path: []const u8,
) !void {
    const cwd = std.Io.Dir.cwd();

    const raw_bytes = cwd.readFileAlloc(io, raw_path, gpa, file_bytes_max) catch |err| {
        return fail("cannot read raw '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    defer gpa.free(raw_bytes);
    const recipe_bytes = cwd.readFileAlloc(io, recipe_path, gpa, file_bytes_max) catch |err| {
        return fail("cannot read recipe '{s}': {s}", .{ recipe_path, @errorName(err) });
    };
    defer gpa.free(recipe_bytes);

    var recipe = emu.recipe.parse(gpa, recipe_bytes) catch |err| {
        return fail("recipe '{s}' is not a valid recipe: {s}", .{ recipe_path, @errorName(err) });
    };
    defer recipe.deinit();

    var raw = emu.raw.decode_raw(gpa, raw_bytes) catch |err| {
        return fail("cannot decode '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    defer raw.deinit(gpa);

    var rendered = emu.pipeline.render_decoded(gpa, &raw, recipe.value, .{}) catch |err| {
        return fail("render failed: {s}", .{@errorName(err)});
    };
    defer rendered.deinit(gpa);

    const png_bytes = try emu.png.encode_rgba(
        gpa,
        rendered.width,
        rendered.height,
        rendered.rgba,
    );
    defer gpa.free(png_bytes);

    wombat.vfs.user_file_write(io, cwd, out_path, png_bytes) catch {
        return fail("cannot write '{s}'", .{out_path});
    };

    try status(io, "rendered {d}x{d} -> {s} ({d} bytes)\n", .{
        rendered.width, rendered.height, out_path, png_bytes.len,
    });
}

/// Progress goes to stdout: stderr is reserved for failures, so build
/// runners (zig build's own included) don't mistake status for trouble.
fn status(io: std.Io, comptime fmt: []const u8, args: anytype) !void {
    var buffer: [256]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    try writer.interface.print(fmt, args);
    try writer.interface.flush();
}

fn usage() error{Usage} {
    std.debug.print(
        \\usage: banksia render <raw.dng> <recipe.json> <out.png>
        \\       banksia synth <out.dng> [<width> <height>]
        \\       banksia convert-dng <raw> <out.dng> <storage>
        \\       banksia inspect <raw> [--decode|--render]
        \\
    , .{});
    return error.Usage;
}

fn fail(comptime fmt: []const u8, args: anytype) error{Failed} {
    std.debug.print("banksia: " ++ fmt ++ "\n", args);
    return error.Failed;
}
