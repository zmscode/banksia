//! CLI entry point for banksia.
//!
//!   banksia render <raw.dng> <recipe.json> <out.png>
//!   banksia synth <out.dng> [<width> <height>]
//!       write a synthetic demo DNG (dev fixture; defaults to 512x384)
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

    var sensor = emu.dng.decode(gpa, raw_bytes) catch |err| {
        return fail("cannot decode '{s}': {s}", .{ raw_path, @errorName(err) });
    };
    defer sensor.deinit(gpa);

    var rendered = emu.pipeline.render(gpa, &sensor, recipe.value, .{}) catch |err| {
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
        \\
    , .{});
    return error.Usage;
}

fn fail(comptime fmt: []const u8, args: anytype) error{Failed} {
    std.debug.print("banksia: " ++ fmt ++ "\n", args);
    return error.Failed;
}
