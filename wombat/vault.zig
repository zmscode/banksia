//! The content-addressed blob vault: BLAKE3 names, write-once objects,
//! dedup by existence. Owns the `vault/` namespace of whatever filesystem
//! root it is opened on (a session directory, the global library).
//!
//! Layout: `vault/objects/aa/bb/<64-hex>` (two shard levels from the hash's
//! leading bytes) and `vault/tmp/<64-hex>` for in-flight writes.
//!
//! The write path is the durability protocol the crash simulator exists to
//! attack: hash → write tmp → fsync file → rename into place → fsync the
//! object directory. `put` returning is the acknowledgement; an
//! acknowledged blob survives any crash (`sim.zig` proves it 10k times per
//! CI run), an unacknowledged one may vanish but can never corrupt.

const std = @import("std");
const assert = std.debug.assert;
const vfs = @import("vfs.zig");
const chunker = @import("chunker.zig");

pub const Hash = [32]u8;
pub const Error = vfs.Error || error{CorruptObject};

pub const blob_bytes_max: u64 = 4 * 1024 * 1024 * 1024; // a bound, not a target
const chunks_max: u32 = 1 << 20;
const manifest_magic = [4]u8{ 'b', 'k', 'c', 'h' };
const Chunker = chunker.ChunkerType(chunker.config_default);

pub fn hash_of(bytes: []const u8) Hash {
    var hash: Hash = undefined;
    std.crypto.hash.Blake3.hash(bytes, &hash, .{});
    return hash;
}

pub fn hex_of(hash: Hash) [64]u8 {
    return std.fmt.bytesToHex(hash, .lower);
}

pub fn VaultType(comptime Fs: type) type {
    return struct {
        const Vault = @This();

        fs: *Fs,
        /// Rehash every object on read and compare with its name — the
        /// pair assertion with the write-side hash. Always on in tests
        /// and simulation; callers may disable it on trusted volumes.
        verify_on_read: bool,

        pub fn open(fs: *Fs, options: struct { verify_on_read: bool = true }) Error!Vault {
            try fs.make_path("vault/objects");
            try fs.make_path("vault/tmp");
            return .{ .fs = fs, .verify_on_read = options.verify_on_read };
        }

        /// Store a blob and return its address. Returning is the
        /// acknowledgement: the object is durable past this point.
        /// Idempotent — an existing object is a dedup hit, no write.
        pub fn put(vault: *Vault, bytes: []const u8) Error!Hash {
            assert(bytes.len <= blob_bytes_max);
            const hash = hash_of(bytes);
            const path = object_path(hash);
            if (try vault.fs.exists(path.slice())) return hash;

            const tmp = tmp_path(hash);
            const dir = object_dir(hash);
            try vault.fs.write_file(tmp.slice(), bytes);
            try vault.fs.fsync_file(tmp.slice());
            try vault.fs.make_path(dir.slice());
            try vault.fs.rename(tmp.slice(), path.slice());
            try vault.fs.fsync_dir(dir.slice());

            // The pair assertion's write half: what we just acknowledged
            // is readable right now (cheap here; reboot is sim's job).
            // The probe is an operation like any other — under simulation
            // it may crash, which is fine: the blob is already durable.
            assert(try vault.fs.exists(path.slice()));
            return hash;
        }

        pub fn contains(vault: *Vault, hash: Hash) Error!bool {
            const path = object_path(hash);
            return vault.fs.exists(path.slice());
        }

        /// Read a blob back; with verify_on_read, contents that fail to
        /// rehash to their own name are `error.CorruptObject`, never
        /// silently returned.
        pub fn get_alloc(vault: *Vault, gpa: std.mem.Allocator, hash: Hash) Error![]u8 {
            const path = object_path(hash);
            const bytes = try vault.fs.read_alloc(gpa, path.slice(), blob_bytes_max);
            errdefer gpa.free(bytes);
            if (vault.verify_on_read) {
                if (!std.mem.eql(u8, &hash_of(bytes), &hash)) return error.CorruptObject;
            }
            return bytes;
        }

        /// Store a big mutable file (catalog snapshot, export) as
        /// content-defined chunks plus a manifest object naming them, and
        /// return the manifest's address. A rewritten file re-puts every
        /// chunk, but unchanged runs are dedup hits — only changed chunks
        /// cost bytes. RAW blobs use plain `put`: they never mutate.
        pub fn put_chunked(vault: *Vault, gpa: std.mem.Allocator, bytes: []const u8) Error!Hash {
            var manifest: std.ArrayList(u8) = .empty;
            defer manifest.deinit(gpa);
            try manifest.appendSlice(gpa, &manifest_magic);

            var chunks = Chunker.init(bytes);
            var count: u32 = 0;
            while (chunks.next()) |chunk| {
                count += 1;
                assert(count <= chunks_max);
                const hash = try vault.put(bytes[@intCast(chunk.offset)..][0..chunk.len]);
                try manifest.appendSlice(gpa, &hash);
            }
            return vault.put(manifest.items);
        }

        /// Reassemble a chunked file from its manifest address. Every
        /// chunk rides through `get_alloc`, so verify-on-read covers the
        /// whole reconstruction.
        pub fn get_chunked_alloc(
            vault: *Vault,
            gpa: std.mem.Allocator,
            manifest_hash: Hash,
        ) Error![]u8 {
            const manifest = try vault.get_alloc(gpa, manifest_hash);
            defer gpa.free(manifest);
            if (manifest.len < manifest_magic.len) return error.CorruptObject;
            if (!std.mem.startsWith(u8, manifest, &manifest_magic)) return error.CorruptObject;
            const body = manifest[manifest_magic.len..];
            if (body.len % 32 != 0) return error.CorruptObject;

            var bytes: std.ArrayList(u8) = .empty;
            errdefer bytes.deinit(gpa);
            var offset: usize = 0;
            while (offset < body.len) : (offset += 32) {
                var hash: Hash = undefined;
                @memcpy(&hash, body[offset..][0..32]);
                const chunk = try vault.get_alloc(gpa, hash);
                defer gpa.free(chunk);
                try bytes.appendSlice(gpa, chunk);
            }
            return bytes.toOwnedSlice(gpa);
        }

        /// Sweep objects not in `referenced` plus any leftover tmp files.
        /// Explicitly invoked only (`banksia gc`); nothing deletes
        /// implicitly. Returns how many objects were removed.
        pub fn gc(
            vault: *Vault,
            gpa: std.mem.Allocator,
            referenced: *const std.AutoHashMapUnmanaged(Hash, void),
        ) Error!u32 {
            var removed: u32 = 0;
            var iterator = try ObjectIterator.init(gpa, vault.fs);
            defer iterator.deinit();
            while (try iterator.next()) |hash| {
                if (referenced.contains(hash)) continue;
                const path = object_path(hash);
                try vault.fs.remove_file(path.slice());
                removed += 1;
            }

            const leftovers = try vault.fs.list_dir(gpa, "vault/tmp");
            defer vfs.entries_free(gpa, leftovers);
            for (leftovers) |entry| {
                var path: PathBuffer = .{};
                path.append("vault/tmp/");
                path.append(entry.name);
                try vault.fs.remove_file(path.slice());
            }
            return removed;
        }

        /// Walk every stored object hash: two shard levels then leaves —
        /// a fixed-depth loop nest, no recursion.
        pub const ObjectIterator = struct {
            gpa: std.mem.Allocator,
            fs: *Fs,
            shards_a: []vfs.Entry,
            shards_b: []vfs.Entry,
            leaves: []vfs.Entry,
            index_a: u32 = 0,
            index_b: u32 = 0,
            index_leaf: u32 = 0,

            pub fn init(gpa: std.mem.Allocator, fs: *Fs) Error!ObjectIterator {
                return .{
                    .gpa = gpa,
                    .fs = fs,
                    .shards_a = try fs.list_dir(gpa, "vault/objects"),
                    .shards_b = &.{},
                    .leaves = &.{},
                };
            }

            pub fn deinit(iterator: *ObjectIterator) void {
                vfs.entries_free(iterator.gpa, iterator.shards_a);
                vfs.entries_free(iterator.gpa, iterator.shards_b);
                vfs.entries_free(iterator.gpa, iterator.leaves);
                iterator.* = undefined;
            }

            pub fn next(iterator: *ObjectIterator) Error!?Hash {
                while (true) {
                    if (iterator.index_leaf < iterator.leaves.len) {
                        const name = iterator.leaves[iterator.index_leaf].name;
                        iterator.index_leaf += 1;
                        if (name.len != 64) continue; // not ours; skip
                        var hash: Hash = undefined;
                        _ = std.fmt.hexToBytes(&hash, name) catch continue;
                        return hash;
                    }
                    if (iterator.index_b < iterator.shards_b.len) {
                        const shard_b = iterator.shards_b[iterator.index_b];
                        const shard_a = iterator.shards_a[iterator.index_a - 1];
                        iterator.index_b += 1;
                        var path: PathBuffer = .{};
                        path.append("vault/objects/");
                        path.append(shard_a.name);
                        path.append("/");
                        path.append(shard_b.name);
                        vfs.entries_free(iterator.gpa, iterator.leaves);
                        iterator.leaves =
                            try iterator.fs.list_dir(iterator.gpa, path.slice());
                        iterator.index_leaf = 0;
                        continue;
                    }
                    if (iterator.index_a < iterator.shards_a.len) {
                        const shard_a = iterator.shards_a[iterator.index_a];
                        iterator.index_a += 1;
                        var path: PathBuffer = .{};
                        path.append("vault/objects/");
                        path.append(shard_a.name);
                        vfs.entries_free(iterator.gpa, iterator.shards_b);
                        iterator.shards_b =
                            try iterator.fs.list_dir(iterator.gpa, path.slice());
                        iterator.index_b = 0;
                        continue;
                    }
                    return null;
                }
            }
        };
    };
}

/// A fixed path buffer: callers bind it to a local and borrow `slice()` —
/// never call `slice()` on a temporary.
const PathBuffer = struct {
    bytes: [vfs.path_bytes_max]u8 = undefined,
    len: u32 = 0,

    fn append(path: *PathBuffer, text: []const u8) void {
        assert(path.len + text.len <= path.bytes.len);
        @memcpy(path.bytes[path.len..][0..text.len], text);
        path.len += @intCast(text.len);
    }

    fn slice(path: *const PathBuffer) []const u8 {
        assert(path.len > 0);
        return path.bytes[0..path.len];
    }
};

fn object_dir(hash: Hash) PathBuffer {
    const hex = hex_of(hash);
    var path: PathBuffer = .{};
    path.append("vault/objects/");
    path.append(hex[0..2]);
    path.append("/");
    path.append(hex[2..4]);
    return path;
}

fn object_path(hash: Hash) PathBuffer {
    const hex = hex_of(hash);
    var path = object_dir(hash);
    path.append("/");
    path.append(&hex);
    return path;
}

fn tmp_path(hash: Hash) PathBuffer {
    const hex = hex_of(hash);
    var path: PathBuffer = .{};
    path.append("vault/tmp/");
    path.append(&hex);
    return path;
}

// ---- tests ---------------------------------------------------------------------

test "vault roundtrip: put, contains, get with verify-on-read (sim)" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 11, .{});
    defer sim.deinit();
    var vault = try VaultType(vfs.Sim).open(&sim, .{});

    const hash = try vault.put("a raw file, allegedly");
    try std.testing.expect(try vault.contains(hash));

    const bytes = try vault.get_alloc(gpa, hash);
    defer gpa.free(bytes);
    try std.testing.expectEqualStrings("a raw file, allegedly", bytes);

    const absent: Hash = @splat(0xEE);
    try std.testing.expect(!try vault.contains(absent));
    try std.testing.expectEqual(error.NotFound, vault.get_alloc(gpa, absent));
}

test "put is idempotent: the second write is a dedup hit" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 12, .{});
    defer sim.deinit();
    var vault = try VaultType(vfs.Sim).open(&sim, .{});

    const first = try vault.put("same bytes");
    const operations_after_first = sim.operations;
    const second = try vault.put("same bytes");
    try std.testing.expectEqualSlices(u8, &first, &second);
    // Dedup path: exactly one operation (the existence probe), no writes.
    try std.testing.expectEqual(operations_after_first + 1, sim.operations);
}

test "verify-on-read turns silent corruption into an error (negative space)" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 13, .{});
    defer sim.deinit();
    var vault = try VaultType(vfs.Sim).open(&sim, .{});

    const hash = try vault.put("pristine");
    // Corrupt the object behind the vault's back.
    var path: PathBuffer = object_path(hash);
    try sim.write_file(path.slice(), "tampered");
    try std.testing.expectEqual(error.CorruptObject, vault.get_alloc(gpa, hash));
}

test "gc sweeps unreferenced objects and tmp leftovers, keeps the rest" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 14, .{});
    defer sim.deinit();
    var vault = try VaultType(vfs.Sim).open(&sim, .{});

    const keep = try vault.put("keep me");
    const drop = try vault.put("drop me");
    try sim.write_file("vault/tmp/deadbeef", "crash leftover");

    var referenced: std.AutoHashMapUnmanaged(Hash, void) = .empty;
    defer referenced.deinit(gpa);
    try referenced.put(gpa, keep, {});

    const removed = try vault.gc(gpa, &referenced);
    try std.testing.expectEqual(@as(u32, 1), removed);
    try std.testing.expect(try vault.contains(keep));
    try std.testing.expect(!try vault.contains(drop));
    try std.testing.expect(!try sim.exists("vault/tmp/deadbeef"));
}

test "chunked put/get roundtrips, and a prefix edit dedups the tail" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 15, .{});
    defer sim.deinit();
    var vault = try VaultType(vfs.Sim).open(&sim, .{});

    // ~3MiB of deterministic noise: a handful of default-config chunks.
    const original = try gpa.alloc(u8, 3 * 1024 * 1024);
    defer gpa.free(original);
    var state: u64 = 99;
    for (original, 0..) |*byte, i| {
        if (i % 8 == 0) state = state *% 0x100000001B3 +% 0x9E3779B9;
        byte.* = @truncate(state >> @intCast(8 * (i % 8)));
    }

    const manifest = try vault.put_chunked(gpa, original);
    const roundtrip = try vault.get_chunked_alloc(gpa, manifest);
    defer gpa.free(roundtrip);
    try std.testing.expectEqualSlices(u8, original, roundtrip);

    const objects_before = try test_object_count(gpa, &vault);

    // Insert one byte at the front and store again: content-defined
    // boundaries re-align, so only the leading chunk(s) and the manifest
    // are new objects.
    const edited = try gpa.alloc(u8, original.len + 1);
    defer gpa.free(edited);
    edited[0] = 0x42;
    @memcpy(edited[1..], original);
    const manifest_edited = try vault.put_chunked(gpa, edited);
    try std.testing.expect(!std.mem.eql(u8, &manifest, &manifest_edited));

    const objects_after = try test_object_count(gpa, &vault);
    try std.testing.expect(objects_after > objects_before);
    try std.testing.expect(objects_after - objects_before <= 3);
}

fn test_object_count(gpa: std.mem.Allocator, vault: *VaultType(vfs.Sim)) !u32 {
    var iterator = try VaultType(vfs.Sim).ObjectIterator.init(gpa, vault.fs);
    defer iterator.deinit();
    var count: u32 = 0;
    while (try iterator.next()) |_| count += 1;
    return count;
}

test "vault works identically over the real filesystem" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var real = vfs.Real.init(io, tmp.dir);
    var vault = try VaultType(vfs.Real).open(&real, .{});
    const hash = try vault.put("bytes on actual disk");
    try std.testing.expect(try vault.contains(hash));
    const bytes = try vault.get_alloc(gpa, hash);
    defer gpa.free(bytes);
    try std.testing.expectEqualStrings("bytes on actual disk", bytes);
}
