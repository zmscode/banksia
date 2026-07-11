//! The crash simulator: wombat's hard gate, run in CI as `zig build sim`.
//!
//! Runs paired vault and catalog workloads over the `Sim` filesystem with
//! crash injection armed, rebooting after every crash (unsynced writes tear
//! or vanish, un-fsynced names and directories drop, pending renames undo):
//!
//! - the **vault** workload puts random blobs and checks that (1) every
//!   acknowledged blob reads back byte-identical and (2) every object in the
//!   store rehashes to its own name — crashes may lose unacknowledged data,
//!   never corrupt it;
//! - the **catalog** workload adds/rates/flags/compacts assets against a
//!   vault and checks, after every reboot, that every acknowledged mutation
//!   survived with exact fields and that every asset points to a readable,
//!   hash-valid vault object. An independent oracle holds the truth; the
//!   single in-flight mutation of a crash is resolved by observing the
//!   settled state, everything else must match exactly.
//!
//!   zig build sim                        10k runs of each workload
//!   zig build sim -Dsim-seed=<u64>       replay a failure exactly
//!   zig build sim -Dsim-runs=<n>         more or fewer runs
//!
//! Probabilities are integer ratios, the generator is SplitMix64, and the
//! seed and run index are printed on every failure: any CI failure replays
//! locally from the hash alone.

const std = @import("std");
const assert = std.debug.assert;
const wombat = @import("wombat");

const Sim = wombat.vfs.Sim;
const Ratio = wombat.vfs.Ratio;
const Vault = wombat.vault.VaultType(Sim);
const Catalog = wombat.catalog.CatalogType(Sim);
const Flags = wombat.catalog.Flags;
const Hash = wombat.vault.Hash;

const trace = false; // flip on to dump per-op history when chasing a seed
const blob_bytes_max_test: u32 = 8 * 1024;
const operations_per_run_max: u32 = 64;
const acknowledged_max: u32 = operations_per_run_max;
const catalog_ops_per_run_max: u32 = 48;
const reopen_attempts_max: u32 = 1000;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next(); // argv[0]
    var seed: u64 = 0;
    var runs: u64 = 10_000;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--seed")) {
            seed = try std.fmt.parseInt(u64, args.next() orelse return error.Usage, 10);
        } else if (std.mem.eql(u8, arg, "--runs")) {
            runs = try std.fmt.parseInt(u64, args.next() orelse return error.Usage, 10);
        } else {
            std.debug.print("sim: unknown argument '{s}'\n", .{arg});
            return error.Usage;
        }
    }

    var crashes_total: u64 = 0;
    var blobs_total: u64 = 0;
    var mutations_total: u64 = 0;
    var run: u64 = 0;
    while (run < runs) : (run += 1) {
        var vault_seed = seed ^ run ^ 0xA0761D6478BD642F;
        const vault_stats = run_vault_one(gpa, splitmix64(&vault_seed)) catch |err| {
            sim_failure_print("vault", run, runs, seed, err);
            return err;
        };
        crashes_total += vault_stats.crashes;
        blobs_total += vault_stats.blobs_acknowledged;

        var catalog_seed = seed ^ run ^ 0xE7037ED1A0B428DB;
        const catalog_stats = run_catalog_one(gpa, splitmix64(&catalog_seed)) catch |err| {
            sim_failure_print("catalog", run, runs, seed, err);
            return err;
        };
        crashes_total += catalog_stats.crashes;
        mutations_total += catalog_stats.mutations_acknowledged;
    }
    std.debug.print(
        "sim: {d} vault + {d} catalog runs, {d} crashes injected, " ++
            "{d} blobs + {d} catalog mutations acknowledged, zero lost (seed {d})\n",
        .{ runs, runs, crashes_total, blobs_total, mutations_total, seed },
    );
}

fn sim_failure_print(
    workload: []const u8,
    run: u64,
    runs: u64,
    seed: u64,
    err: anyerror,
) void {
    std.debug.print(
        "sim: FAILED {s} run {d} of {d}: {s}\n" ++
            "sim: replay with `zig build sim -Dsim-seed={d} -Dsim-runs={d}`\n",
        .{ workload, run, runs, @errorName(err), seed, run + 1 },
    );
}

const RunStats = struct {
    crashes: u64,
    blobs_acknowledged: u32 = 0,
    mutations_acknowledged: u32 = 0,
};

const Acknowledged = struct {
    hash: Hash,
    bytes: []const u8,
};

fn run_vault_one(gpa: std.mem.Allocator, seed: u64) !RunStats {
    var prng = seed;

    var sim = Sim.init(gpa, splitmix64(&prng), .{
        .crash_per_operation = Ratio.init(1, 32),
    });
    defer sim.deinit();

    // Blob contents live in their own arena so acknowledged records stay
    // valid across sim reboots.
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var acknowledged: [acknowledged_max]Acknowledged = undefined;
    var acknowledged_len: u32 = 0;

    var open_attempts: u32 = 0;
    var vault = open: while (open_attempts < 1000) : (open_attempts += 1) {
        break :open Vault.open(&sim, .{}) catch |err| switch (err) {
            error.Crashed => {
                sim.reboot();
                continue;
            },
            else => return err,
        };
    } else unreachable; // crash chance 1/32: a thousand in a row is a bug

    var operation: u32 = 0;
    while (operation < operations_per_run_max) : (operation += 1) {
        const bytes = try blob_generate(arena, &prng);
        const expected = wombat.vault.hash_of(bytes);
        const hash = vault.put(bytes) catch |err| switch (err) {
            error.Crashed => {
                sim.reboot();
                try invariants_check(gpa, &sim, &vault, acknowledged[0..acknowledged_len]);
                continue;
            },
            else => return err,
        };
        assert(std.mem.eql(u8, &hash, &expected)); // put returns the content address
        if (acknowledged_len < acknowledged_max) {
            acknowledged[acknowledged_len] = .{ .hash = hash, .bytes = bytes };
            acknowledged_len += 1;
        }
    }

    // End-of-run audit even if no crash fired.
    sim.crashed = true;
    sim.crashes += 1;
    sim.reboot();
    try invariants_check(gpa, &sim, &vault, acknowledged[0..acknowledged_len]);

    return .{ .crashes = sim.crashes, .blobs_acknowledged = acknowledged_len };
}

/// The two invariants, checked after every reboot. Crash injection is
/// disarmed while checking — the power is already off.
fn invariants_check(
    gpa: std.mem.Allocator,
    sim: *Sim,
    vault: *Vault,
    acknowledged: []const Acknowledged,
) !void {
    const faults_armed = sim.faults;
    sim.faults.crash_per_operation = Ratio.never;
    defer sim.faults = faults_armed;

    for (acknowledged) |record| {
        const bytes = vault.get_alloc(gpa, record.hash) catch |err| {
            std.debug.print("sim: acknowledged blob {s} unreadable: {s}\n", .{
                wombat.vault.hex_of(record.hash), @errorName(err),
            });
            return error.AcknowledgedBlobLost;
        };
        defer gpa.free(bytes);
        if (!std.mem.eql(u8, bytes, record.bytes)) return error.AcknowledgedBlobMutated;
    }

    // Sweep the whole store: unacknowledged objects may be absent, but
    // whatever exists must rehash to its name (get_alloc verifies).
    var iterator = try Vault.ObjectIterator.init(gpa, vault.fs);
    defer iterator.deinit();
    while (try iterator.next()) |hash| {
        const bytes = vault.get_alloc(gpa, hash) catch |err| {
            std.debug.print("sim: object {s} corrupt after reboot: {s}\n", .{
                wombat.vault.hex_of(hash), @errorName(err),
            });
            return error.ObjectCorrupt;
        };
        gpa.free(bytes);
    }
}

// ---- catalog workload ----------------------------------------------------------

/// The oracle's record of one asset the workload believes is durable. Only
/// acknowledged mutations land here; `bytes` is kept so the vault object can
/// be verified against its content.
const OracleAsset = struct {
    bytes: []const u8,
    rating: u8,
    flags: Flags,
};

const Oracle = std.AutoHashMapUnmanaged(Hash, OracleAsset);

/// Context passed to the crash handler so it can resolve the one mutation
/// that was in flight when the power died.
const InFlight = union(enum) {
    none,
    /// An add whose blob is durable; the asset may or may not have landed.
    add: struct { hash: Hash, bytes: []const u8, rating: u8 },
    /// A rating/flag change to an existing asset; its value is now settled.
    mutate: Hash,
};

const CatalogTraceAction = enum { add, rating, flags, compact, reopen, skipped };

const CatalogTraceEntry = struct {
    operation: u32,
    action: CatalogTraceAction,
    hash: Hash = @splat(0),
    value: u8 = 0,
};

fn run_catalog_one(gpa: std.mem.Allocator, seed: u64) !RunStats {
    var prng = seed;
    var sim = Sim.init(gpa, splitmix64(&prng), .{ .crash_per_operation = Ratio.init(1, 64) });
    defer sim.deinit();

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var oracle: Oracle = .empty;
    defer oracle.deinit(gpa);
    var hashes: std.ArrayList(Hash) = .empty;
    defer hashes.deinit(gpa);
    var mutations: u32 = 0;
    var failure_trace: [catalog_ops_per_run_max]CatalogTraceEntry = undefined;
    var failure_trace_len: u32 = 0;

    var vault = try reopen_vault(&sim);
    var catalog = try reopen_catalog(gpa, &sim);
    defer catalog.deinit();

    var operation: u32 = 0;
    errdefer catalog_trace_dump(failure_trace[0..failure_trace_len], operation);
    while (operation < catalog_ops_per_run_max) : (operation += 1) {
        const roll = splitmix64(&prng);
        switch (roll % 8) {
            0, 1, 2 => {
                // Add: blob to the vault, then asset to the catalog.
                const bytes = try blob_generate(arena, &prng);
                const rating: u8 = @intCast(splitmix64(&prng) % 6);
                const expected_hash = wombat.vault.hash_of(bytes);
                catalog_trace_append(&failure_trace, &failure_trace_len, .{
                    .operation = operation,
                    .action = .add,
                    .hash = expected_hash,
                    .value = rating,
                });
                const hash = vault.put(bytes) catch |err| {
                    try crash_resolve(gpa, &sim, &vault, &catalog, &oracle, .none, err);
                    continue;
                };
                _ = catalog.asset_add(.{
                    .hash = hash,
                    .rating = rating,
                    .camera = if (roll & 8 != 0) "Canon" else "Nikon",
                    .lens = "50mm",
                    .iso = @intCast(100 + roll % 6400),
                }) catch |err| switch (err) {
                    error.DuplicateAsset => continue, // same blob twice: fine
                    else => {
                        try crash_resolve(gpa, &sim, &vault, &catalog, &oracle, .{
                            .add = .{ .hash = hash, .bytes = bytes, .rating = rating },
                        }, err);
                        continue;
                    },
                };
                try oracle.put(gpa, hash, .{ .bytes = bytes, .rating = rating, .flags = .{} });
                try hashes.append(gpa, hash);
                mutations += 1;
                if (trace) std.debug.print("add {s} rating={d} ACK\n", .{
                    wombat.vault.hex_of(hash), rating,
                });
            },
            3, 4, 5 => {
                // Rate or flag a random acknowledged asset.
                if (hashes.items.len == 0) {
                    catalog_trace_append(&failure_trace, &failure_trace_len, .{
                        .operation = operation,
                        .action = .skipped,
                    });
                    continue;
                }
                const hash = hashes.items[splitmix64(&prng) % hashes.items.len];
                const asset = catalog.asset_by_hash(hash).?;
                const entry = oracle.getPtr(hash).?;
                if (roll % 8 == 5) {
                    const flags = Flags{ .rejected = roll & 16 != 0, .pick = roll & 32 != 0 };
                    catalog_trace_append(&failure_trace, &failure_trace_len, .{
                        .operation = operation,
                        .action = .flags,
                        .hash = hash,
                        .value = @bitCast(flags),
                    });
                    catalog.flags_set(asset, flags) catch |err| {
                        try crash_resolve(gpa, &sim, &vault, &catalog, &oracle, .{
                            .mutate = hash,
                        }, err);
                        continue;
                    };
                    entry.flags = flags;
                } else {
                    const rating: u8 = @intCast(splitmix64(&prng) % 6);
                    catalog_trace_append(&failure_trace, &failure_trace_len, .{
                        .operation = operation,
                        .action = .rating,
                        .hash = hash,
                        .value = rating,
                    });
                    catalog.rating_set(asset, rating) catch |err| {
                        try crash_resolve(gpa, &sim, &vault, &catalog, &oracle, .{
                            .mutate = hash,
                        }, err);
                        continue;
                    };
                    entry.rating = rating;
                    if (trace) std.debug.print("rate {s} rating={d} ACK\n", .{
                        wombat.vault.hex_of(hash), rating,
                    });
                }
                mutations += 1;
            },
            6 => compact: {
                catalog_trace_append(&failure_trace, &failure_trace_len, .{
                    .operation = operation,
                    .action = .compact,
                });
                catalog.compact() catch |err| {
                    try crash_resolve(gpa, &sim, &vault, &catalog, &oracle, .none, err);
                    continue;
                };
                break :compact;
            },
            7 => {
                catalog_trace_append(&failure_trace, &failure_trace_len, .{
                    .operation = operation,
                    .action = .reopen,
                });
                // Clean reopen (no crash): durable state must already match.
                catalog.deinit();
                catalog = try reopen_catalog(gpa, &sim);
                try oracle_verify(gpa, &vault, &catalog, &oracle);
            },
            else => unreachable,
        }
    }

    // End-of-run crash and full audit: no mutation is in flight, so the
    // oracle must match the reopened catalog exactly.
    sim.crashed = true;
    sim.crashes += 1;
    sim.reboot();
    catalog.deinit();
    vault = try reopen_vault(&sim);
    catalog = try reopen_catalog(gpa, &sim);
    try oracle_verify(gpa, &vault, &catalog, &oracle);

    return .{ .crashes = sim.crashes, .mutations_acknowledged = mutations };
}

/// Handle a workload error: non-crash errors propagate; a crash reboots,
/// reopens the vault and catalog, resolves the single in-flight mutation by
/// observing the settled state, and then verifies every other acknowledged
/// mutation is intact.
fn crash_resolve(
    gpa: std.mem.Allocator,
    sim: *Sim,
    vault: *Vault,
    catalog: *Catalog,
    oracle: *Oracle,
    in_flight: InFlight,
    err: anyerror,
) !void {
    if (err != error.Crashed) return err;
    sim.reboot();
    vault.* = try reopen_vault(sim);
    catalog.deinit();
    catalog.* = try reopen_catalog(gpa, sim);

    // Adopt the settled state of whatever was in flight: it was never
    // acknowledged, so either outcome is legal — record what actually
    // happened so the rest of the run stays consistent.
    switch (in_flight) {
        .none => {},
        .add => |pending| {
            if (catalog.asset_by_hash(pending.hash)) |asset| {
                try oracle.put(gpa, pending.hash, .{
                    .bytes = pending.bytes,
                    .rating = @intCast(catalog.assets.items(.rating)[asset]),
                    .flags = catalog.assets.items(.flags)[asset],
                });
            }
        },
        .mutate => |hash| {
            if (oracle.getPtr(hash)) |entry| {
                const asset = catalog.asset_by_hash(hash) orelse {
                    std.debug.print("sim: acknowledged asset {s} lost resolving mutation\n", .{
                        wombat.vault.hex_of(hash),
                    });
                    return error.AcknowledgedAssetLost;
                };
                entry.rating = @intCast(catalog.assets.items(.rating)[asset]);
                entry.flags = catalog.assets.items(.flags)[asset];
                if (trace) std.debug.print("adopt-mutate {s} rating={d}\n", .{
                    wombat.vault.hex_of(hash), entry.rating,
                });
            }
        },
    }
    try oracle_verify(gpa, vault, catalog, oracle);
}

/// Every acknowledged asset is present with the oracle's exact fields and
/// points at a readable, hash-valid vault object. Acknowledged data is
/// never lost; the vault link is never dangling.
fn oracle_verify(gpa: std.mem.Allocator, vault: *Vault, catalog: *Catalog, oracle: *Oracle) !void {
    // The power is already off: inspection must not itself crash.
    const sim = vault.fs;
    const faults_armed = sim.faults;
    sim.faults.crash_per_operation = Ratio.never;
    defer sim.faults = faults_armed;

    var iterator = oracle.iterator();
    while (iterator.next()) |entry| {
        const hash = entry.key_ptr.*;
        const expected = entry.value_ptr.*;
        const asset = catalog.asset_by_hash(hash) orelse {
            std.debug.print("sim: acknowledged asset {s} lost after reboot\n", .{
                wombat.vault.hex_of(hash),
            });
            return error.AcknowledgedAssetLost;
        };
        if (catalog.assets.items(.rating)[asset] != expected.rating) {
            std.debug.print("sim: asset {s} rating expected {d} got {d} (asset idx {d})\n", .{
                wombat.vault.hex_of(hash),            expected.rating,
                catalog.assets.items(.rating)[asset], asset,
            });
            return error.AcknowledgedRatingWrong;
        }
        const flags = catalog.assets.items(.flags)[asset];
        if (@as(u8, @bitCast(flags)) != @as(u8, @bitCast(expected.flags))) {
            std.debug.print("sim: asset {s} flags expected {d} got {d} (asset idx {d})\n", .{
                wombat.vault.hex_of(hash), @as(u8, @bitCast(expected.flags)),
                @as(u8, @bitCast(flags)),  asset,
            });
            return error.AcknowledgedFlagsWrong;
        }
        // The catalog row must point at a blob that is present and verifies.
        const bytes = vault.get_alloc(gpa, hash) catch |err| {
            std.debug.print("sim: asset {s} points at unreadable object: {s}\n", .{
                wombat.vault.hex_of(hash), @errorName(err),
            });
            return error.AssetObjectMissing;
        };
        defer gpa.free(bytes);
        if (!std.mem.eql(u8, bytes, expected.bytes)) return error.AssetObjectMutated;
    }
}

fn catalog_trace_append(
    entries: *[catalog_ops_per_run_max]CatalogTraceEntry,
    len: *u32,
    entry: CatalogTraceEntry,
) void {
    assert(len.* < entries.len);
    entries[len.*] = entry;
    len.* += 1;
}

fn catalog_trace_dump(entries: []const CatalogTraceEntry, failed_operation: u32) void {
    std.debug.print(
        "sim: catalog failure trace ({d} entries, failed operation {d}):\n",
        .{ entries.len, failed_operation },
    );
    for (entries) |entry| {
        switch (entry.action) {
            .add, .rating, .flags => std.debug.print(
                "  {d}: {s} {s} value={d}\n",
                .{
                    entry.operation,
                    @tagName(entry.action),
                    wombat.vault.hex_of(entry.hash),
                    entry.value,
                },
            ),
            .compact, .reopen, .skipped => std.debug.print(
                "  {d}: {s}\n",
                .{ entry.operation, @tagName(entry.action) },
            ),
        }
    }
}

fn reopen_vault(sim: *Sim) !Vault {
    var attempts: u32 = 0;
    while (attempts < reopen_attempts_max) : (attempts += 1) {
        return Vault.open(sim, .{}) catch |err| switch (err) {
            error.Crashed => {
                sim.reboot();
                continue;
            },
            else => return err,
        };
    }
    unreachable; // 1/64 crash chance: this many in a row is a bug
}

fn reopen_catalog(gpa: std.mem.Allocator, sim: *Sim) !Catalog {
    var attempts: u32 = 0;
    while (attempts < reopen_attempts_max) : (attempts += 1) {
        return Catalog.open(gpa, sim) catch |err| switch (err) {
            error.Crashed => {
                sim.reboot();
                continue;
            },
            else => return err,
        };
    }
    unreachable;
}

/// Random blob: random length (zero included — the empty blob is a valid
/// object), content a pure function of the prng. Sizes skew small — tear
/// positions come cheap — with the occasional full-size blob.
fn blob_generate(arena: std.mem.Allocator, prng: *u64) ![]u8 {
    const roll = splitmix64(prng);
    const len = if (roll % 16 == 0)
        splitmix64(prng) % (blob_bytes_max_test + 1)
    else
        splitmix64(prng) % 512;
    const bytes = try arena.alloc(u8, len);
    var index: usize = 0;
    while (index < bytes.len) : (index += 8) {
        const word = splitmix64(prng);
        const remain = @min(8, bytes.len - index);
        @memcpy(bytes[index..][0..remain], std.mem.asBytes(&word)[0..remain]);
    }
    return bytes;
}

fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}
