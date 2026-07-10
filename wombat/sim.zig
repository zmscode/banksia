//! The crash simulator: wombat's hard gate, run in CI as `zig build sim`.
//!
//! Each run drives a vault through a randomized workload over the `Sim`
//! filesystem with crash injection armed. Every `put` that *returns* is
//! recorded as acknowledged; every crash is followed by a reboot (unsynced
//! writes tear or vanish, un-fsynced names drop, pending renames undo) and
//! then the two invariants are checked:
//!
//!   1. every acknowledged blob reads back byte-identical (verify-on-read
//!      makes corruption loud, absence louder);
//!   2. every object in the store — acknowledged or not — rehashes to its
//!      own name: crashes may lose unacknowledged data, never corrupt it.
//!
//!   zig build sim                        10k runs, seed from the git commit
//!   zig build sim -Dsim-seed=<u64>       replay a failure exactly
//!   zig build sim -Dsim-runs=<n>         more or fewer runs
//!
//! Probabilities are integer ratios, the generator is SplitMix64, and the
//! seed is printed on every failure: any CI failure replays locally from
//! the hash alone.

const std = @import("std");
const assert = std.debug.assert;
const wombat = @import("wombat");

const Sim = wombat.vfs.Sim;
const Ratio = wombat.vfs.Ratio;
const Vault = wombat.vault.VaultType(Sim);
const Hash = wombat.vault.Hash;

const blob_bytes_max_test: u32 = 8 * 1024;
const operations_per_run_max: u32 = 64;
const acknowledged_max: u32 = operations_per_run_max;

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
    var run: u64 = 0;
    while (run < runs) : (run += 1) {
        var run_seed = seed ^ run;
        const stats = run_one(gpa, splitmix64(&run_seed)) catch |err| {
            std.debug.print(
                "sim: FAILED run {d} of {d}: {s}\n" ++
                    "sim: replay with `zig build sim -Dsim-seed={d} -Dsim-runs={d}`\n",
                .{ run, runs, @errorName(err), seed, run + 1 },
            );
            return err;
        };
        crashes_total += stats.crashes;
        blobs_total += stats.blobs_acknowledged;
    }
    std.debug.print(
        "sim: {d} runs, {d} crashes injected, {d} blobs acknowledged, zero lost (seed {d})\n",
        .{ runs, crashes_total, blobs_total, seed },
    );
}

const RunStats = struct { crashes: u64, blobs_acknowledged: u32 };

const Acknowledged = struct {
    hash: Hash,
    bytes: []const u8,
};

fn run_one(gpa: std.mem.Allocator, seed: u64) !RunStats {
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
