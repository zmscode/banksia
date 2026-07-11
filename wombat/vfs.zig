//! The filesystem seam: every byte wombat puts on disk goes through one of
//! these two backends, selected at comptime (the Ghostty pattern — zero-cost
//! dispatch, identical method sets, duck-typed by the code that uses them).
//!
//! `Real` wraps `std.Io` rooted at a directory. `Sim` is an in-memory tree
//! with fault injection: crashes between any two operations, torn or lost
//! unsynced writes, un-fsynced names and renames that may not survive, and
//! directory listings in shuffled order. Injection probabilities are
//! integer `Ratio`s — floats are a determinism hazard and never enter the
//! test substrate. Every run replays from a `u64` seed.
//!
//! Durability model (what `Sim.reboot` enforces, mirroring POSIX):
//!
//! - file contents are durable after `fsync_file`;
//! - a created or renamed *name* is durable after `fsync_dir` of its
//!   parent — until then a crash may drop the name or undo the rename;
//! - unsynced content may survive in full, as a prefix (torn), or not at
//!   all.
//!
//! Nothing outside `wombat/` opens a file for writing; tidy enforces it.

const std = @import("std");
const assert = std.debug.assert;

pub const Error = error{ NotFound, IoFailure, OutOfMemory, Crashed };

/// A directory entry as `list_dir` reports it.
pub const Entry = struct {
    name: []const u8,
    kind: enum { file, directory },
};

/// Longest path and deepest tree wombat ever builds; a bound, not a target.
pub const path_bytes_max: u32 = 1024;
pub const dir_entries_max: u32 = 1 << 20;

/// An integer probability: `numerator` in `denominator` events fire.
pub const Ratio = struct {
    numerator: u64,
    denominator: u64,

    pub fn init(numerator: u64, denominator: u64) Ratio {
        assert(denominator > 0);
        assert(numerator <= denominator);
        return .{ .numerator = numerator, .denominator = denominator };
    }

    pub const never: Ratio = .{ .numerator = 0, .denominator = 1 };
};

// ---- the real backend ----------------------------------------------------------

pub const Real = struct {
    io: std.Io,
    root: std.Io.Dir,

    pub fn init(io: std.Io, root: std.Io.Dir) Real {
        return .{ .io = io, .root = root };
    }

    pub fn read_alloc(
        self: *Real,
        gpa: std.mem.Allocator,
        path: []const u8,
        bytes_limit: u64,
    ) Error![]u8 {
        path_assert(path);
        return self.root.readFileAlloc(
            self.io,
            path,
            gpa,
            std.Io.Limit.limited(bytes_limit),
        ) catch |err| switch (err) {
            error.FileNotFound => error.NotFound,
            error.OutOfMemory => error.OutOfMemory,
            else => error.IoFailure,
        };
    }

    /// Create or truncate, write everything, close. Durability needs an
    /// explicit `fsync_file` — matching what the hardware actually promises.
    pub fn write_file(self: *Real, path: []const u8, bytes: []const u8) Error!void {
        path_assert(path);
        var file = self.root.createFile(self.io, path, .{}) catch |err| switch (err) {
            error.FileNotFound => return error.NotFound,
            else => return error.IoFailure,
        };
        defer file.close(self.io);
        file.writeStreamingAll(self.io, bytes) catch return error.IoFailure;
    }

    pub fn append_file(self: *Real, path: []const u8, bytes: []const u8) Error!void {
        path_assert(path);
        var file = self.root.openFile(self.io, path, .{ .mode = .read_write }) catch |err|
            switch (err) {
                error.FileNotFound => return error.NotFound,
                else => return error.IoFailure,
            };
        defer file.close(self.io);
        const end = file.length(self.io) catch return error.IoFailure;
        file.writePositionalAll(self.io, bytes, end) catch return error.IoFailure;
    }

    pub fn fsync_file(self: *Real, path: []const u8) Error!void {
        path_assert(path);
        var file = self.root.openFile(self.io, path, .{ .mode = .read_write }) catch |err|
            switch (err) {
                error.FileNotFound => return error.NotFound,
                else => return error.IoFailure,
            };
        defer file.close(self.io);
        file.sync(self.io) catch return error.IoFailure;
    }

    /// Make a created or renamed name in `path` durable ("" is the root).
    pub fn fsync_dir(self: *Real, path: []const u8) Error!void {
        var dir = if (path.len == 0) self.root else self.root.openDir(
            self.io,
            path,
            .{},
        ) catch |err| switch (err) {
            error.FileNotFound => return error.NotFound,
            else => return error.IoFailure,
        };
        defer if (path.len != 0) dir.close(self.io);
        const as_file = std.Io.File{ .handle = dir.handle, .flags = .{ .nonblocking = false } };
        as_file.sync(self.io) catch return error.IoFailure;
    }

    pub fn rename(self: *Real, source: []const u8, target: []const u8) Error!void {
        path_assert(source);
        path_assert(target);
        self.root.rename(source, self.root, target, self.io) catch |err| switch (err) {
            error.FileNotFound => return error.NotFound,
            else => return error.IoFailure,
        };
    }

    pub fn make_path(self: *Real, path: []const u8) Error!void {
        path_assert(path);
        self.root.createDirPath(self.io, path) catch return error.IoFailure;
    }

    pub fn exists(self: *Real, path: []const u8) Error!bool {
        path_assert(path);
        self.root.access(self.io, path, .{}) catch |err| switch (err) {
            error.FileNotFound => return false,
            else => return error.IoFailure,
        };
        return true;
    }

    pub fn remove_file(self: *Real, path: []const u8) Error!void {
        path_assert(path);
        self.root.deleteFile(self.io, path) catch |err| switch (err) {
            error.FileNotFound => return error.NotFound,
            else => return error.IoFailure,
        };
    }

    /// Entries in on-disk order; free with `entries_free`.
    pub fn list_dir(
        self: *Real,
        gpa: std.mem.Allocator,
        path: []const u8,
    ) Error![]Entry {
        var dir = self.root.openDir(self.io, path, .{ .iterate = true }) catch |err|
            switch (err) {
                error.FileNotFound => return error.NotFound,
                else => return error.IoFailure,
            };
        defer dir.close(self.io);

        var entries: std.ArrayList(Entry) = .empty;
        errdefer entries_free(gpa, entries.items);
        errdefer entries.deinit(gpa);
        var iterator = dir.iterate();
        var count: u32 = 0;
        while (iterator.next(self.io) catch return error.IoFailure) |entry| {
            count += 1;
            if (count > dir_entries_max) return error.IoFailure;
            if (entry.kind != .file and entry.kind != .directory) continue;
            try entries.append(gpa, .{
                .name = try gpa.dupe(u8, entry.name),
                .kind = if (entry.kind == .file) .file else .directory,
            });
        }
        return entries.toOwnedSlice(gpa);
    }
};

pub fn entries_free(gpa: std.mem.Allocator, entries: []Entry) void {
    for (entries) |entry| gpa.free(entry.name);
    gpa.free(entries);
}

/// One-shot write of a user-directed output file (CLI render/synth output,
/// the golden baseline). The one door for bytes that leave the process
/// outside a vault: the path is the user's own — absolute or relative —
/// so it is not part of the seam's crash model, but the write still lives
/// in wombat, where every byte on disk belongs.
pub fn user_file_write(
    io: std.Io,
    base: std.Io.Dir,
    path: []const u8,
    bytes: []const u8,
) error{IoFailure}!void {
    assert(path.len > 0);
    var file = base.createFile(io, path, .{}) catch return error.IoFailure;
    defer file.close(io);
    file.writeStreamingAll(io, bytes) catch return error.IoFailure;
}

// ---- the simulated backend -------------------------------------------------------

pub const Faults = struct {
    /// Chance, per operation, that the power dies before it runs.
    crash_per_operation: Ratio = Ratio.never,
    /// At crash: chance an unsynced write survives only as a prefix.
    write_torn: Ratio = Ratio.init(1, 3),
    /// At crash: chance an unsynced write vanishes entirely.
    write_lost: Ratio = Ratio.init(1, 3),
    /// At crash: chance an un-fsynced name (create or rename) is dropped
    /// or undone.
    name_lost: Ratio = Ratio.init(1, 2),
    /// Chance a directory listing comes back shuffled.
    list_shuffle: Ratio = Ratio.init(1, 2),
};

pub const Sim = struct {
    arena_state: std.heap.ArenaAllocator,
    prng_state: u64,
    faults: Faults,
    crashed: bool = false,
    files: std.StringArrayHashMapUnmanaged(SimFile) = .empty,
    dirs: std.StringArrayHashMapUnmanaged(SimDir) = .empty,
    renames_pending: std.ArrayList(RenamePending) = .empty,
    /// Statistics the harness prints on failure.
    operations: u64 = 0,
    crashes: u64 = 0,

    const SimFile = struct {
        bytes: []const u8,
        /// Content guaranteed after a crash (null: never fsynced).
        bytes_durable: ?[]const u8,
        /// The name itself survives a crash (parent dir fsynced since the
        /// name appeared).
        name_durable: bool,
    };

    /// Directories are durable objects too: a freshly created directory
    /// entry can be lost on reboot until its *parent* is fsynced, exactly
    /// like a file name. Modelling this is what makes the vault's shard-dir
    /// fsyncs load-bearing rather than decorative.
    const SimDir = struct {
        name_durable: bool,
    };

    const RenamePending = struct {
        source: []const u8,
        target: []const u8,
        /// What the source name held before the rename, for the undo arm.
        source_was_durable: bool,
    };

    pub fn init(gpa: std.mem.Allocator, seed: u64, faults: Faults) Sim {
        var sim = Sim{
            .arena_state = std.heap.ArenaAllocator.init(gpa),
            .prng_state = seed,
            .faults = faults,
        };
        // Mix the seed once so seed 0 and seed 1 diverge immediately.
        sim.prng_state = splitmix64(&sim.prng_state);
        return sim;
    }

    pub fn deinit(self: *Sim) void {
        self.arena_state.deinit();
        self.* = undefined;
    }

    fn arena(self: *Sim) std.mem.Allocator {
        return self.arena_state.allocator();
    }

    /// Every public operation calls this first: the power may die between
    /// any two operations, never inside the model's own bookkeeping.
    fn operation_begin(self: *Sim) Error!void {
        assert(!self.crashed); // callers must reboot after a crash
        self.operations += 1;
        if (self.chance(self.faults.crash_per_operation)) {
            self.crashed = true;
            self.crashes += 1;
            return error.Crashed;
        }
    }

    /// Resolve the crash: unsynced content tears or vanishes, un-fsynced
    /// names flip a coin, pending renames land or undo. The survivor tree
    /// becomes both current and durable.
    pub fn reboot(self: *Sim) void {
        assert(self.crashed);
        // Renames first: each either persisted (target keeps the file) or
        // undid (file reappears at source). Iterate in reverse so chains
        // resolve latest-first.
        while (self.renames_pending.pop()) |pending| {
            if (self.chance(self.faults.name_lost)) {
                if (self.files.fetchSwapRemove(pending.target)) |kv| {
                    var file = kv.value;
                    file.name_durable = pending.source_was_durable;
                    self.files.put(self.arena(), pending.source, file) catch @panic("sim oom");
                }
            } else if (self.files.getPtr(pending.target)) |file| {
                file.name_durable = true;
            }
        }

        self.reboot_dirs();

        var index: usize = 0;
        while (index < self.files.count()) {
            const file = &self.files.values()[index];
            const key = self.files.keys()[index];
            const self_survives = file.name_durable or !self.chance(self.faults.name_lost);
            // A file cannot outlive a directory that was itself lost.
            if (!self_survives or !self.parent_survived(key)) {
                self.files.swapRemoveAt(index);
                continue;
            }
            file.bytes = self.crash_content_resolve(file.*);
            file.bytes_durable = file.bytes;
            file.name_durable = true;
            index += 1;
        }
        self.crashed = false;
    }

    /// Resolve directory survival top-down: a directory survives only if it
    /// is itself durable (or wins its coin flip) *and* its parent survives.
    /// Sorted shortest-first, a parent is always judged before its children,
    /// so one pass settles the whole tree; a `dead` set records the losers.
    fn reboot_dirs(self: *Sim) void {
        const Context = struct {
            keys: [][]const u8,
            pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
                return ctx.keys[a].len < ctx.keys[b].len;
            }
        };
        self.dirs.sort(Context{ .keys = self.dirs.keys() });

        var dead: std.StringHashMapUnmanaged(void) = .empty;
        defer dead.deinit(self.arena());
        for (self.dirs.keys(), self.dirs.values()) |key, *dir| {
            const parent = path_parent(key);
            const parent_dead = parent.len != 0 and dead.contains(parent);
            const self_survives = dir.name_durable or !self.chance(self.faults.name_lost);
            if (!self_survives or parent_dead) {
                dead.put(self.arena(), key, {}) catch @panic("sim oom");
            } else {
                dir.name_durable = true;
            }
        }

        var index: usize = 0;
        while (index < self.dirs.count()) {
            if (dead.contains(self.dirs.keys()[index])) {
                self.dirs.swapRemoveAt(index);
            } else index += 1;
        }
    }

    /// The parent directory of `path` still exists (root is always present).
    fn parent_survived(self: *const Sim, path: []const u8) bool {
        const parent = path_parent(path);
        if (parent.len == 0) return true;
        return self.dirs.contains(parent);
    }

    fn crash_content_resolve(self: *Sim, file: SimFile) []const u8 {
        const durable = file.bytes_durable orelse "";
        if (durable.ptr == file.bytes.ptr and durable.len == file.bytes.len) {
            return file.bytes; // fully synced: nothing to lose
        }
        if (self.chance(self.faults.write_lost)) return durable;
        if (self.chance(self.faults.write_torn)) {
            // A torn write keeps a strict prefix of what was in flight.
            const keep = self.prng_next() % (file.bytes.len + 1);
            return file.bytes[0..keep];
        }
        return file.bytes;
    }

    // -- the operation set, mirroring Real ------------------------------------

    pub fn read_alloc(
        self: *Sim,
        gpa: std.mem.Allocator,
        path: []const u8,
        bytes_limit: u64,
    ) Error![]u8 {
        path_assert(path);
        try self.operation_begin();
        const file = self.files.get(path) orelse return error.NotFound;
        if (file.bytes.len > bytes_limit) return error.IoFailure;
        return gpa.dupe(u8, file.bytes);
    }

    pub fn write_file(self: *Sim, path: []const u8, bytes: []const u8) Error!void {
        path_assert(path);
        try self.operation_begin();
        try self.parent_require(path);
        const copy = try self.arena().dupe(u8, bytes);
        const slot = try self.files.getOrPut(self.arena(), try self.key_own(path));
        if (slot.found_existing) {
            slot.value_ptr.bytes = copy;
        } else {
            slot.value_ptr.* = .{
                .bytes = copy,
                .bytes_durable = null,
                .name_durable = false,
            };
        }
    }

    pub fn append_file(self: *Sim, path: []const u8, bytes: []const u8) Error!void {
        path_assert(path);
        try self.operation_begin();
        const file = self.files.getPtr(path) orelse return error.NotFound;
        const joined = try self.arena().alloc(u8, file.bytes.len + bytes.len);
        @memcpy(joined[0..file.bytes.len], file.bytes);
        @memcpy(joined[file.bytes.len..], bytes);
        file.bytes = joined;
    }

    pub fn fsync_file(self: *Sim, path: []const u8) Error!void {
        path_assert(path);
        try self.operation_begin();
        const file = self.files.getPtr(path) orelse return error.NotFound;
        file.bytes_durable = file.bytes;
    }

    pub fn fsync_dir(self: *Sim, path: []const u8) Error!void {
        try self.operation_begin();
        if (path.len > 0 and !self.dirs.contains(path)) return error.NotFound;
        // fsync of a directory persists the entries it contains: both the
        // files and the child directories whose parent is this path.
        for (self.files.keys(), self.files.values()) |key, *file| {
            if (path_parent_is(key, path)) file.name_durable = true;
        }
        for (self.dirs.keys(), self.dirs.values()) |key, *dir| {
            if (path_parent_is(key, path)) dir.name_durable = true;
        }
        // Pending renames whose target lives here are now on stone.
        var index: usize = 0;
        while (index < self.renames_pending.items.len) {
            if (path_parent_is(self.renames_pending.items[index].target, path)) {
                _ = self.renames_pending.swapRemove(index);
            } else index += 1;
        }
    }

    pub fn rename(self: *Sim, source: []const u8, target: []const u8) Error!void {
        path_assert(source);
        path_assert(target);
        try self.operation_begin();
        try self.parent_require(target);
        const removed = self.files.fetchSwapRemove(source) orelse return error.NotFound;
        var file = removed.value;
        try self.renames_pending.append(self.arena(), .{
            .source = try self.key_own(source),
            .target = try self.key_own(target),
            .source_was_durable = file.name_durable,
        });
        file.name_durable = false;
        try self.files.put(self.arena(), try self.key_own(target), file);
    }

    pub fn make_path(self: *Sim, path: []const u8) Error!void {
        path_assert(path);
        try self.operation_begin();
        // Register every prefix, the way createDirPath does. A newly created
        // directory entry starts non-durable — it survives a crash only once
        // its parent is fsynced. An existing prefix keeps whatever
        // durability it already had (make_path is idempotent).
        var end: usize = 0;
        while (end < path.len) {
            end = std.mem.indexOfScalarPos(u8, path, end, '/') orelse path.len;
            const slot = try self.dirs.getOrPut(self.arena(), try self.key_own(path[0..end]));
            if (!slot.found_existing) slot.value_ptr.* = .{ .name_durable = false };
            end += 1;
        }
    }

    pub fn exists(self: *Sim, path: []const u8) Error!bool {
        path_assert(path);
        try self.operation_begin();
        return self.files.contains(path) or self.dirs.contains(path);
    }

    pub fn remove_file(self: *Sim, path: []const u8) Error!void {
        path_assert(path);
        try self.operation_begin();
        if (self.files.fetchSwapRemove(path) == null) return error.NotFound;
    }

    pub fn list_dir(
        self: *Sim,
        gpa: std.mem.Allocator,
        path: []const u8,
    ) Error![]Entry {
        try self.operation_begin();
        if (path.len > 0 and !self.dirs.contains(path)) return error.NotFound;
        var entries: std.ArrayList(Entry) = .empty;
        errdefer entries_free(gpa, entries.items);
        errdefer entries.deinit(gpa);
        for (self.files.keys()) |key| {
            if (!path_parent_is(key, path)) continue;
            try entries.append(gpa, .{
                .name = try gpa.dupe(u8, key[if (path.len == 0) 0 else path.len + 1 ..]),
                .kind = .file,
            });
        }
        for (self.dirs.keys()) |key| {
            if (!path_parent_is(key, path)) continue;
            try entries.append(gpa, .{
                .name = try gpa.dupe(u8, key[if (path.len == 0) 0 else path.len + 1 ..]),
                .kind = .directory,
            });
        }
        if (self.chance(self.faults.list_shuffle)) self.entries_shuffle(entries.items);
        return entries.toOwnedSlice(gpa);
    }

    // -- internals ---------------------------------------------------------------

    fn parent_require(self: *Sim, path: []const u8) Error!void {
        const parent = path_parent(path);
        if (parent.len > 0 and !self.dirs.contains(parent)) return error.NotFound;
    }

    fn key_own(self: *Sim, path: []const u8) Error![]const u8 {
        return self.arena().dupe(u8, path);
    }

    fn entries_shuffle(self: *Sim, entries: []Entry) void {
        if (entries.len < 2) return;
        var index = entries.len - 1;
        while (index > 0) : (index -= 1) {
            const other = self.prng_next() % (index + 1);
            std.mem.swap(Entry, &entries[index], &entries[other]);
        }
    }

    fn chance(self: *Sim, ratio: Ratio) bool {
        assert(ratio.numerator <= ratio.denominator);
        if (ratio.numerator == 0) return false;
        return self.prng_next() % ratio.denominator < ratio.numerator;
    }

    fn prng_next(self: *Sim) u64 {
        return splitmix64(&self.prng_state);
    }
};

/// The doctrine generator: integer in, integer out, reproducible forever.
fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}

// ---- path helpers ------------------------------------------------------------

/// Paths are wombat-internal: relative, '/'-separated, no dot segments.
/// These are our own composed strings — asserts, not errors.
fn path_assert(path: []const u8) void {
    assert(path.len > 0);
    assert(path.len <= path_bytes_max);
    assert(path[0] != '/');
    assert(path[path.len - 1] != '/');
    assert(std.mem.indexOf(u8, path, "..") == null);
    assert(std.mem.indexOf(u8, path, "//") == null);
}

fn path_parent(path: []const u8) []const u8 {
    const slash = std.mem.lastIndexOfScalar(u8, path, '/') orelse return "";
    return path[0..slash];
}

fn path_parent_is(path: []const u8, parent: []const u8) bool {
    return std.mem.eql(u8, path_parent(path), parent);
}

// ---- tests ---------------------------------------------------------------------

test "sim: write, fsync, read roundtrip with no faults" {
    const gpa = std.testing.allocator;
    var sim = Sim.init(gpa, 42, .{});
    defer sim.deinit();

    try sim.make_path("vault/objects");
    try sim.write_file("vault/objects/aa", "hello wombat");
    try sim.fsync_file("vault/objects/aa");
    try sim.fsync_dir("vault/objects");

    const bytes = try sim.read_alloc(gpa, "vault/objects/aa", 1 << 20);
    defer gpa.free(bytes);
    try std.testing.expectEqualStrings("hello wombat", bytes);
    try std.testing.expect(try sim.exists("vault/objects/aa"));
    try std.testing.expect(!try sim.exists("vault/objects/bb"));
}

test "sim: the full sync protocol survives any crash; skipping it may not" {
    const gpa = std.testing.allocator;
    // Across many seeds: a file written with the full protocol is always
    // intact after reboot; the same content written without fsync must be
    // observed to vanish or tear for at least one seed (the faults exist).
    var unsynced_losses: u32 = 0;
    var seed: u64 = 0;
    while (seed < 200) : (seed += 1) {
        var sim = Sim.init(gpa, seed, .{});
        defer sim.deinit();
        try sim.make_path("v");
        try sim.fsync_dir(""); // persist the directory `v` itself
        try sim.write_file("v/synced", "acknowledged-bytes");
        try sim.fsync_file("v/synced");
        try sim.fsync_dir("v");
        try sim.write_file("v/unsynced", "maybe-bytes");

        sim.crashed = true; // force the crash at this exact point
        sim.crashes += 1;
        sim.reboot();

        const synced = try sim.read_alloc(gpa, "v/synced", 1 << 20);
        defer gpa.free(synced);
        try std.testing.expectEqualStrings("acknowledged-bytes", synced);

        const unsynced = sim.read_alloc(gpa, "v/unsynced", 1 << 20) catch |err| blk: {
            try std.testing.expectEqual(error.NotFound, err);
            unsynced_losses += 1;
            break :blk try gpa.dupe(u8, "");
        };
        defer gpa.free(unsynced);
        // Whatever survived must be a prefix — corruption is never silent.
        try std.testing.expect(std.mem.startsWith(u8, "maybe-bytes", unsynced));
        if (unsynced.len < "maybe-bytes".len) unsynced_losses += 1;
    }
    try std.testing.expect(unsynced_losses > 0);
}

test "sim: a directory survives a crash only once its parent is fsynced" {
    const gpa = std.testing.allocator;
    var durable_survivals: u32 = 0;
    var unsynced_losses: u32 = 0;
    var seed: u64 = 0;
    while (seed < 300) : (seed += 1) {
        var sim = Sim.init(gpa, seed, .{});
        defer sim.deinit();

        // `durable` is fsynced through its parent (root); `volatile_dir` is
        // created and left unsynced.
        try sim.make_path("durable");
        try sim.fsync_dir("");
        try sim.make_path("volatile_dir");

        sim.crashed = true;
        sim.crashes += 1;
        sim.reboot();

        // The parent-fsynced directory is always there.
        try std.testing.expect(try sim.exists("durable"));
        durable_survivals += 1;
        // The unsynced one is sometimes gone; when present it is usable.
        if (!try sim.exists("volatile_dir")) unsynced_losses += 1;
    }
    try std.testing.expectEqual(@as(u32, 300), durable_survivals);
    try std.testing.expect(unsynced_losses > 0); // the fault arm fires
}

test "sim: an un-fsynced rename can undo; a dir-fsynced one cannot" {
    const gpa = std.testing.allocator;
    var undone: u32 = 0;
    var seed: u64 = 0;
    while (seed < 200) : (seed += 1) {
        var sim = Sim.init(gpa, seed, .{});
        defer sim.deinit();
        try sim.make_path("v/tmp");
        try sim.make_path("v/objects");
        // Persist the directories themselves so only file/rename durability
        // is under test here, not the parent dirs.
        try sim.fsync_dir("");
        try sim.fsync_dir("v");

        // Fully acknowledged object: rename + dir fsync.
        try sim.write_file("v/tmp/one", "one");
        try sim.fsync_file("v/tmp/one");
        try sim.rename("v/tmp/one", "v/objects/one");
        try sim.fsync_dir("v/objects");

        // Unacknowledged: the tmp name is durable (dir fsync before the
        // rename) but the rename itself is not — so a crash resolves to
        // exactly one of the two names, never both, never neither.
        try sim.write_file("v/tmp/two", "two");
        try sim.fsync_file("v/tmp/two");
        try sim.fsync_dir("v/tmp");
        try sim.rename("v/tmp/two", "v/objects/two");

        sim.crashed = true;
        sim.crashes += 1;
        sim.reboot();

        const one = try sim.read_alloc(gpa, "v/objects/one", 1 << 20);
        defer gpa.free(one);
        try std.testing.expectEqualStrings("one", one);

        // Two is at exactly one of its names, with intact content (it was
        // file-fsynced; only the *name* was in flight).
        const at_target = try sim.exists("v/objects/two");
        const at_source = try sim.exists("v/tmp/two");
        try std.testing.expect(at_target != at_source);
        if (at_source) undone += 1;
        const where = if (at_target) "v/objects/two" else "v/tmp/two";
        const two = try sim.read_alloc(gpa, where, 1 << 20);
        defer gpa.free(two);
        try std.testing.expectEqualStrings("two", two);
    }
    try std.testing.expect(undone > 0); // the fault arm actually fires
}

test "sim: crash injection fires and replays identically from the seed" {
    const gpa = std.testing.allocator;
    const faults = Faults{ .crash_per_operation = Ratio.init(1, 10) };

    // The same seed must produce the same crash at the same operation.
    var operations: [2]u64 = undefined;
    for (&operations) |*count| {
        var sim = Sim.init(gpa, 7, faults);
        defer sim.deinit();
        try sim.make_path("v");
        var i: u32 = 0;
        const crashed_at: u64 = while (i < 1000) : (i += 1) {
            var name_buffer: [32]u8 = undefined;
            const name = std.fmt.bufPrint(&name_buffer, "v/f{d}", .{i}) catch unreachable;
            sim.write_file(name, "x") catch |err| {
                try std.testing.expectEqual(error.Crashed, err);
                break sim.operations;
            };
        } else 0;
        try std.testing.expect(crashed_at > 0);
        count.* = crashed_at;
    }
    try std.testing.expectEqual(operations[0], operations[1]);
}

test "sim: listings shuffle but never lie" {
    const gpa = std.testing.allocator;
    var sim = Sim.init(gpa, 3, .{ .list_shuffle = Ratio.init(1, 1) });
    defer sim.deinit();
    try sim.make_path("v");
    try sim.write_file("v/a", "1");
    try sim.write_file("v/b", "2");
    try sim.write_file("v/c", "3");

    const entries = try sim.list_dir(gpa, "v");
    defer entries_free(gpa, entries);
    try std.testing.expectEqual(@as(usize, 3), entries.len);
    var seen = [_]bool{ false, false, false };
    for (entries) |entry| {
        try std.testing.expectEqual(@as(usize, 1), entry.name.len);
        seen[entry.name[0] - 'a'] = true;
    }
    for (seen) |s| try std.testing.expect(s);
}

test "real: roundtrip through an actual directory" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var real = Real.init(io, tmp.dir);
    try real.make_path("vault/objects/aa");
    try real.write_file("vault/objects/aa/bee", "buzz");
    try real.fsync_file("vault/objects/aa/bee");
    try real.fsync_dir("vault/objects/aa");
    try real.append_file("vault/objects/aa/bee", " buzz");

    const bytes = try real.read_alloc(gpa, "vault/objects/aa/bee", 1 << 20);
    defer gpa.free(bytes);
    try std.testing.expectEqualStrings("buzz buzz", bytes);

    try real.rename("vault/objects/aa/bee", "vault/objects/aa/wasp");
    try std.testing.expect(!try real.exists("vault/objects/aa/bee"));
    try std.testing.expect(try real.exists("vault/objects/aa/wasp"));

    const entries = try real.list_dir(gpa, "vault/objects/aa");
    defer entries_free(gpa, entries);
    try std.testing.expectEqual(@as(usize, 1), entries.len);
    try std.testing.expectEqualStrings("wasp", entries[0].name);

    try std.testing.expectEqual(error.NotFound, real.read_alloc(gpa, "vault/nope", 16));
    try real.remove_file("vault/objects/aa/wasp");
    try std.testing.expect(!try real.exists("vault/objects/aa/wasp"));
}
