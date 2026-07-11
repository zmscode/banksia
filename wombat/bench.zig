//! The catalog filter benchmark: this phase's latency speedometer.
//!
//! Builds a 100k-asset catalog in memory and times a two-column filter
//! (rating ≥ 4 AND lens = X) — the "smart collection as a full scan"
//! claim, measured. Prints milliseconds; CI records the number and a
//! regression is >2x the recorded budget.
//!
//!   zig build bench                 100k assets, default iterations
//!   zig build bench -- --assets N   scale the catalog
//!
//! Built ReleaseFast (the exit criterion is a ReleaseFast number). The
//! build uses the in-memory `Sim` fs with faults disabled — the benchmark
//! measures the scan, not the disk.

const std = @import("std");
const assert = std.debug.assert;
const wombat = @import("wombat");

const Catalog = wombat.catalog.CatalogType(wombat.vfs.Sim);

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    var asset_count: u32 = 100_000;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--assets")) {
            asset_count = try std.fmt.parseInt(u32, args.next() orelse return error.Usage, 10);
        } else {
            std.debug.print("bench: unknown argument '{s}'\n", .{arg});
            return error.Usage;
        }
    }

    var sim = wombat.vfs.Sim.init(gpa, 1, .{});
    defer sim.deinit();
    var catalog = try Catalog.open(gpa, &sim);
    defer catalog.deinit();

    // Build the catalog directly in memory: the WAL is not what we are
    // timing, so append rows through the in-memory apply path.
    try catalog_fill(&catalog, asset_count);
    std.debug.print("bench: built {d} assets\n", .{catalog.count()});

    const lens_target = catalog.lenses.ids.get("EF 35mm f/2").?;
    const filter = wombat.catalog.Filter{ .rating_min = 4, .lens = lens_target };

    // Warm, then time enough iterations to smooth out noise.
    var warm: u32 = 0;
    var sink: u64 = 0;
    while (warm < 8) : (warm += 1) sink +%= catalog.filter_count(filter);

    const iterations: u32 = 200;
    const started = std.Io.Clock.now(.awake, io);
    var iteration: u32 = 0;
    var matched: u32 = 0;
    while (iteration < iterations) : (iteration += 1) {
        matched = catalog.filter_count(filter);
        sink +%= matched;
    }
    const finished = std.Io.Clock.now(.awake, io);
    const elapsed_ns: u64 = @intCast(started.durationTo(finished).nanoseconds);
    const per_scan_ns = elapsed_ns / iterations;

    std.debug.print(
        "bench: rating>=4 AND lens=X over {d} assets: {d} matched, " ++
            "{d:.3} ms/scan ({d} iterations)\n",
        .{ asset_count, matched, ms(per_scan_ns), iterations },
    );
    std.mem.doNotOptimizeAway(sink);

    // The exit criterion: single-digit milliseconds at 100k.
    if (asset_count >= 100_000 and per_scan_ns > 10 * std.time.ns_per_ms) {
        std.debug.print("bench: FAIL — {d:.3} ms exceeds the 10 ms budget\n", .{ms(per_scan_ns)});
        return error.BenchRegression;
    }
}

fn catalog_fill(catalog: *Catalog, asset_count: u32) !void {
    const cameras = [_][]const u8{ "Canon EOS 350D", "Canon EOS 5D", "Nikon D700" };
    const lenses = [_][]const u8{ "EF 35mm f/2", "EF 50mm f/1.8", "EF 85mm f/1.8", "EF 24-70" };
    var prng: u64 = 0xB0BA_CAFE;
    var index: u32 = 0;
    while (index < asset_count) : (index += 1) {
        var hash: wombat.vault.Hash = @splat(0);
        std.mem.writeInt(u32, hash[0..4], index, .little);
        const roll = splitmix64(&prng);
        _ = try catalog.asset_add_for_bench(.{
            .hash = hash,
            .camera = cameras[roll % cameras.len],
            .lens = lenses[(roll >> 8) % lenses.len],
            .iso = @intCast(100 + (roll >> 16) % 6400),
            .rating = @intCast((roll >> 32) % 6),
            .capture_time = @intCast(roll >> 20),
        });
    }
}

fn ms(nanoseconds: u64) f64 {
    return @as(f64, @floatFromInt(nanoseconds)) / std.time.ns_per_ms;
}

fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}
