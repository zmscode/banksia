//! ReleaseFast catalog latency benchmarks.
//!
//! The default fixture contains 100k deterministic assets. Fixture construction
//! is never timed. The measured workloads are two filters, public page reads,
//! snapshot serialization, snapshot reopen, and replay of a 1,000-record WAL.
//!
//!   zig build bench
//!   zig build bench -- --assets N

const std = @import("std");
const wombat = @import("wombat");

const Catalog = wombat.catalog.CatalogType(wombat.vfs.Sim);
const default_asset_count: u32 = 100_000;
const filter_iterations: u32 = 200;
const page_iterations: u32 = 10_000;
const page_capacity: u32 = 256;
const wal_record_count: u32 = 1_000;

// Rounded-up Phase 2A baselines. Budgets are 2x baseline, additionally
// capped by the product hard ceilings where one is specified.
const rating_lens_baseline_ns: u64 = 500 * std.time.ns_per_us;
const rejected_baseline_ns: u64 = 100 * std.time.ns_per_us;
const page_baseline_ns: u64 = 10 * std.time.ns_per_us;
const compact_baseline_ns: u64 = 25 * std.time.ns_per_ms;
const snapshot_reopen_baseline_ns: u64 = 50 * std.time.ns_per_ms;
const wal_replay_baseline_ns: u64 = 5 * std.time.ns_per_ms;

const rating_lens_budget_ns = @min(
    2 * rating_lens_baseline_ns,
    10 * std.time.ns_per_ms,
);
const rejected_budget_ns = 2 * rejected_baseline_ns;
const page_budget_ns = 2 * page_baseline_ns;
const compact_budget_ns = 2 * compact_baseline_ns;
const snapshot_reopen_budget_ns = @min(
    2 * snapshot_reopen_baseline_ns,
    500 * std.time.ns_per_ms,
);
const wal_replay_budget_ns = 2 * wal_replay_baseline_ns;

const cameras = [_][]const u8{
    "Canon EOS 350D",
    "Canon EOS 5D",
    "Nikon D700",
};

const lenses = [_][]const u8{
    "EF 35mm f/2",
    "EF 50mm f/1.8",
    "EF 85mm f/1.8",
    "EF 24-70",
};

const FilterResult = struct {
    per_scan_ns: u64,
    matched: u32,
};

const PageResult = struct {
    per_fetch_ns: u64,
    rows: usize,
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    const asset_count = try parse_asset_count(init);

    var sim = wombat.vfs.Sim.init(gpa, 1, .{});
    defer sim.deinit();
    var catalog = try Catalog.open(gpa, &sim);
    defer catalog.deinit();

    try catalog_fill(&catalog, asset_count);
    std.debug.print("bench: built deterministic fixture: {d} assets\n", .{catalog.count()});

    const lens_target = catalog.lenses.ids.get("EF 35mm f/2").?;
    const rating_lens = try filter_bench(io, &catalog, .{
        .rating_min = 4,
        .lens = lens_target,
    });
    std.debug.print(
        "bench: rating>=4 AND lens=X, {d} assets: {d} matched, " ++
            "{d:.3} ms/scan ({d} iterations)\n",
        .{
            asset_count,
            rating_lens.matched,
            ms(rating_lens.per_scan_ns),
            filter_iterations,
        },
    );

    const rejected = try filter_bench(io, &catalog, .{ .rejected = true });
    std.debug.print(
        "bench: rejected-only, {d} assets: {d} matched, " ++
            "{d:.3} ms/scan ({d} iterations)\n",
        .{
            asset_count,
            rejected.matched,
            ms(rejected.per_scan_ns),
            filter_iterations,
        },
    );

    const page = page_bench(io, &catalog);
    std.debug.print(
        "bench: Catalog.page_read, {d}-row page: {d} rows, " ++
            "{d:.3} ms/fetch ({d} iterations)\n",
        .{ page_capacity, page.rows, ms(page.per_fetch_ns), page_iterations },
    );

    const compact_started = std.Io.Clock.now(.awake, io);
    try catalog.compact();
    const compact_finished = std.Io.Clock.now(.awake, io);
    const compact_ns: u64 = @intCast(
        compact_started.durationTo(compact_finished).nanoseconds,
    );
    std.debug.print(
        "bench: catalog.compact snapshot, {d} assets: {d:.3} ms\n",
        .{ asset_count, ms(compact_ns) },
    );

    const reopen_started = std.Io.Clock.now(.awake, io);
    var reopened = try Catalog.open(gpa, &sim);
    const reopen_finished = std.Io.Clock.now(.awake, io);
    const reopen_ns: u64 = @intCast(
        reopen_started.durationTo(reopen_finished).nanoseconds,
    );
    const reopened_count = reopened.count();
    reopened.deinit();
    if (reopened_count != asset_count) return error.BenchFixtureMismatch;
    std.debug.print(
        "bench: snapshot reopen, {d} assets: {d:.3} ms\n",
        .{ reopened_count, ms(reopen_ns) },
    );

    var wal_sim = wombat.vfs.Sim.init(gpa, 2, .{});
    defer wal_sim.deinit();
    {
        var wal_fixture = try Catalog.open(gpa, &wal_sim);
        defer wal_fixture.deinit();
        try wal_fill(&wal_fixture, wal_record_count);
    }
    std.debug.print(
        "bench: built deterministic WAL fixture: {d} records\n",
        .{wal_record_count},
    );

    const replay_started = std.Io.Clock.now(.awake, io);
    var replayed = try Catalog.open(gpa, &wal_sim);
    const replay_finished = std.Io.Clock.now(.awake, io);
    const replay_ns: u64 = @intCast(
        replay_started.durationTo(replay_finished).nanoseconds,
    );
    const replayed_count = replayed.count();
    replayed.deinit();
    if (replayed_count != wal_record_count) return error.BenchFixtureMismatch;
    std.debug.print(
        "bench: WAL replay, {d} records: {d:.3} ms\n",
        .{ wal_record_count, ms(replay_ns) },
    );

    if (asset_count >= default_asset_count) {
        try enforce_budget(
            "rating+lens filter",
            rating_lens.per_scan_ns,
            rating_lens_budget_ns,
        );
        try enforce_budget(
            "snapshot reopen",
            reopen_ns,
            snapshot_reopen_budget_ns,
        );
    }
    if (asset_count == default_asset_count) {
        try enforce_budget(
            "rejected-only filter",
            rejected.per_scan_ns,
            rejected_budget_ns,
        );
        try enforce_budget("snapshot compact", compact_ns, compact_budget_ns);
    }
    try enforce_budget("Catalog.page_read", page.per_fetch_ns, page_budget_ns);
    try enforce_budget("1k-record WAL replay", replay_ns, wal_replay_budget_ns);
}

fn parse_asset_count(init: std.process.Init) !u32 {
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    var asset_count = default_asset_count;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--assets")) {
            const value = args.next() orelse return error.Usage;
            asset_count = try std.fmt.parseInt(u32, value, 10);
        } else {
            std.debug.print("bench: unknown argument '{s}'\n", .{arg});
            return error.Usage;
        }
    }
    if (asset_count == 0) return error.Usage;
    return asset_count;
}

fn filter_bench(
    io: std.Io,
    catalog: *const Catalog,
    filter: wombat.catalog.Filter,
) !FilterResult {
    var sink: u64 = 0;
    var warm: u32 = 0;
    while (warm < 8) : (warm += 1) {
        sink +%= catalog.filter_count(filter);
    }

    const started = std.Io.Clock.now(.awake, io);
    var iteration: u32 = 0;
    var matched: u32 = 0;
    while (iteration < filter_iterations) : (iteration += 1) {
        matched = catalog.filter_count(filter);
        sink +%= matched;
    }
    const finished = std.Io.Clock.now(.awake, io);
    std.mem.doNotOptimizeAway(sink);

    const elapsed_ns: u64 = @intCast(started.durationTo(finished).nanoseconds);
    return .{
        .per_scan_ns = elapsed_ns / filter_iterations,
        .matched = matched,
    };
}

fn page_bench(io: std.Io, catalog: *const Catalog) PageResult {
    var out: [page_capacity]wombat.catalog.AssetView = undefined;
    _ = catalog.page_read(0, &out);

    const start_count = catalog.count() -| page_capacity;
    var sink: u64 = 0;
    var rows: usize = 0;
    const started = std.Io.Clock.now(.awake, io);
    var iteration: u32 = 0;
    while (iteration < page_iterations) : (iteration += 1) {
        const start = if (start_count == 0)
            0
        else
            (iteration *% page_capacity) % (start_count + 1);
        rows = catalog.page_read(start, &out);
        sink +%= rows;
        if (rows > 0) sink +%= out[rows - 1].id;
    }
    const finished = std.Io.Clock.now(.awake, io);
    std.mem.doNotOptimizeAway(sink);

    const elapsed_ns: u64 = @intCast(started.durationTo(finished).nanoseconds);
    return .{
        .per_fetch_ns = elapsed_ns / page_iterations,
        .rows = rows,
    };
}

fn catalog_fill(catalog: *Catalog, asset_count: u32) !void {
    var prng: u64 = 0xB0BA_CAFE;
    var index: u32 = 0;
    while (index < asset_count) : (index += 1) {
        const roll = splitmix64(&prng);
        _ = try catalog.asset_add_for_bench(asset_description(index, roll));
    }
}

fn wal_fill(catalog: *Catalog, record_count: u32) !void {
    var prng: u64 = 0xC0FF_EE11;
    var index: u32 = 0;
    while (index < record_count) : (index += 1) {
        const roll = splitmix64(&prng);
        _ = try catalog.asset_add(asset_description(index, roll));
    }
}

fn asset_description(index: u32, roll: u64) wombat.catalog.AssetDescription {
    var hash: wombat.vault.Hash = @splat(0);
    std.mem.writeInt(u32, hash[0..4], index, .little);
    return .{
        .hash = hash,
        .camera = cameras[roll % cameras.len],
        .lens = lenses[(roll >> 8) % lenses.len],
        .iso = @intCast(100 + (roll >> 16) % 6400),
        .rating = @intCast((roll >> 32) % 6),
        .flags = .{
            .rejected = roll & 1 != 0,
            .pick = roll & 2 != 0,
        },
        .capture_time = @intCast(roll >> 20),
    };
}

fn enforce_budget(name: []const u8, actual_ns: u64, budget_ns: u64) !void {
    if (actual_ns < budget_ns) return;
    std.debug.print(
        "bench: FAIL {s}: {d:.3} ms exceeds {d:.3} ms budget\n",
        .{ name, ms(actual_ns), ms(budget_ns) },
    );
    return error.BenchRegression;
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
