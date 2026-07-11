//! The columnar catalog: a hundred-thousand-asset library as a
//! `std.MultiArrayList` — every interesting operation is a filter or sort
//! touching two or three columns, so filters scan dense contiguous arrays
//! and nothing else (plan.md, design pillars).
//!
//! Persistence is snapshot + write-ahead log, all through the vfs seam so
//! the crash simulator covers it:
//!
//! - the snapshot is column sections behind a header, sealed by a BLAKE3
//!   trailer; it is replaced atomically (tmp → fsync → rename → fsync dir);
//! - every mutation appends one checksummed WAL record and fsyncs before
//!   returning — returning is the acknowledgement;
//! - open = load snapshot, replay the WAL; a torn tail is truncated,
//!   never half-applied;
//! - records carry the snapshot generation, so a crash between "snapshot
//!   renamed" and "WAL cleared" cannot double-apply history.
//!
//! Strings (camera, lens) intern once into id tables; rows store u16 ids.

const std = @import("std");
const assert = std.debug.assert;
const vfs = @import("vfs.zig");
const vault = @import("vault.zig");

pub const Error = vfs.Error || error{CorruptCatalog};

pub const assets_max: u32 = 1 << 24;
const strings_max: u32 = 1 << 16;
const string_bytes_max: u32 = 256;
const wal_record_bytes_max: u32 = 1024;
const snapshot_path = "catalog";
const snapshot_tmp_path = "catalog.tmp";
const wal_path = "wal";
const snapshot_magic = [4]u8{ 'b', 'k', 'c', 't' };
const snapshot_version: u32 = 1;

pub const Flags = packed struct(u8) {
    rejected: bool = false,
    pick: bool = false,
    padding: u6 = 0,
};

/// One row. Small on purpose: smaller rows = fewer cache misses = faster
/// scans (the Zig-compiler lesson). Large payloads live out-of-band.
pub const Asset = struct {
    /// Handle into the blob-hash side table.
    hash_id: u32,
    /// Current edit head (Phase 3); 0 = none yet.
    recipe_head: u32,
    capture_time: i64,
    rating: u3,
    flags: Flags,
    camera: u16,
    lens: u16,
    iso: u32,
    /// Populated by lyrebird (Phase 4).
    burst_group: u32,
    /// Populated by lyrebird (Phase 4); f16 keeps the row small.
    sharpness: f16,
};

/// What an importer knows about one photo.
pub const AssetDescription = struct {
    hash: vault.Hash,
    capture_time: i64 = 0,
    camera: []const u8 = "",
    lens: []const u8 = "",
    iso: u32 = 0,
    rating: u3 = 0,
    flags: Flags = .{},
};

/// A conjunctive predicate; null fields don't participate, so the scan
/// touches only the columns the query names.
pub const Filter = struct {
    rating_min: ?u3 = null,
    camera: ?u16 = null,
    lens: ?u16 = null,
    rejected: ?bool = null,
};

const StringTable = struct {
    strings: std.ArrayList([]const u8) = .empty,
    ids: std.StringHashMapUnmanaged(u16) = .empty,

    fn deinit(table: *StringTable, gpa: std.mem.Allocator) void {
        for (table.strings.items) |string| gpa.free(string);
        table.strings.deinit(gpa);
        table.ids.deinit(gpa);
        table.* = undefined;
    }

    fn intern(table: *StringTable, gpa: std.mem.Allocator, string: []const u8) Error!u16 {
        assert(string.len <= string_bytes_max);
        if (table.ids.get(string)) |id| return id;
        if (table.strings.items.len >= strings_max) return error.CorruptCatalog;
        const id: u16 = @intCast(table.strings.items.len);
        const copy = try gpa.dupe(u8, string);
        errdefer gpa.free(copy);
        try table.strings.append(gpa, copy);
        errdefer _ = table.strings.pop();
        try table.ids.put(gpa, copy, id);
        return id;
    }

    fn get(table: *const StringTable, id: u16) []const u8 {
        assert(id < table.strings.items.len);
        return table.strings.items[id];
    }
};

pub fn CatalogType(comptime Fs: type) type {
    return struct {
        const Catalog = @This();

        gpa: std.mem.Allocator,
        fs: *Fs,
        assets: std.MultiArrayList(Asset) = .empty,
        hashes: std.ArrayList(vault.Hash) = .empty,
        hash_ids: std.AutoHashMapUnmanaged(vault.Hash, u32) = .empty,
        asset_by_hash_id: std.AutoHashMapUnmanaged(u32, u32) = .empty,
        cameras: StringTable = .{},
        lenses: StringTable = .{},
        /// Bumped by every compaction; WAL records from another generation
        /// are dead history and skipped on replay.
        generation: u64 = 0,

        /// Load snapshot (if any), replay the WAL, truncate any torn tail.
        pub fn open(gpa: std.mem.Allocator, fs: *Fs) Error!Catalog {
            var catalog = Catalog{ .gpa = gpa, .fs = fs };
            errdefer catalog.deinit();
            try catalog.snapshot_load();
            try catalog.wal_replay();
            return catalog;
        }

        pub fn deinit(catalog: *Catalog) void {
            const gpa = catalog.gpa;
            catalog.assets.deinit(gpa);
            catalog.hashes.deinit(gpa);
            catalog.hash_ids.deinit(gpa);
            catalog.asset_by_hash_id.deinit(gpa);
            catalog.cameras.deinit(gpa);
            catalog.lenses.deinit(gpa);
            catalog.* = undefined;
        }

        pub fn count(catalog: *const Catalog) u32 {
            return @intCast(catalog.assets.len);
        }

        /// The asset already holding this blob, if any — import dedup.
        pub fn asset_by_hash(catalog: *const Catalog, hash: vault.Hash) ?u32 {
            const hash_id = catalog.hash_ids.get(hash) orelse return null;
            return catalog.asset_by_hash_id.get(hash_id);
        }

        /// Append an asset. Durable when this returns.
        pub fn asset_add(catalog: *Catalog, description: AssetDescription) Error!u32 {
            assert(catalog.assets.len < assets_max);
            assert(catalog.asset_by_hash(description.hash) == null);
            var record: [wal_record_bytes_max]u8 = undefined;
            const payload = record_encode_add(&record, catalog.generation, description);
            try catalog.wal_append(payload);
            return catalog.asset_add_apply(description);
        }

        /// In-memory append with no WAL record: the benchmark builds a
        /// 100k-row catalog and measures the scan, not 100k fsyncs. Not
        /// durable — never call it outside a benchmark.
        pub fn asset_add_for_bench(catalog: *Catalog, description: AssetDescription) Error!u32 {
            return catalog.asset_add_apply(description);
        }

        pub fn rating_set(catalog: *Catalog, asset: u32, rating: u3) Error!void {
            assert(asset < catalog.assets.len);
            var record: [wal_record_bytes_max]u8 = undefined;
            const payload =
                record_encode_set(&record, catalog.generation, .set_rating, asset, rating);
            try catalog.wal_append(payload);
            catalog.assets.items(.rating)[asset] = rating;
        }

        pub fn flags_set(catalog: *Catalog, asset: u32, flags: Flags) Error!void {
            assert(asset < catalog.assets.len);
            var record: [wal_record_bytes_max]u8 = undefined;
            const payload =
                record_encode_set(&record, catalog.generation, .set_flags, asset, @bitCast(flags));
            try catalog.wal_append(payload);
            catalog.assets.items(.flags)[asset] = flags;
        }

        /// Fold the WAL into a fresh snapshot: write to a tmp name, fsync,
        /// rename over the old snapshot, fsync the directory, then clear
        /// the log. A crash anywhere in between replays cleanly: the new
        /// snapshot's generation disowns the old records.
        pub fn compact(catalog: *Catalog) Error!void {
            const generation_next = catalog.generation + 1;
            const bytes = try catalog.snapshot_serialize(generation_next);
            defer catalog.gpa.free(bytes);

            try catalog.fs.write_file(snapshot_tmp_path, bytes);
            try catalog.fs.fsync_file(snapshot_tmp_path);
            try catalog.fs.rename(snapshot_tmp_path, snapshot_path);
            try catalog.fs.fsync_dir("");
            catalog.generation = generation_next;

            try catalog.fs.write_file(wal_path, "");
            try catalog.fs.fsync_file(wal_path);
        }

        // -- filtering ---------------------------------------------------------

        /// Count assets matching the filter, touching only named columns.
        pub fn filter_count(catalog: *const Catalog, filter: Filter) u32 {
            var total: u32 = 0;
            var index: u32 = 0;
            const len: u32 = @intCast(catalog.assets.len);

            // One pass per named column over a match bitmap would be the
            // full columnar treatment; at Phase 2 scale a fused scan of
            // the two or three touched columns is already single-digit
            // milliseconds at 100k (the bench holds the number).
            const ratings = catalog.assets.items(.rating);
            const cameras = catalog.assets.items(.camera);
            const lenses = catalog.assets.items(.lens);
            const flags = catalog.assets.items(.flags);
            while (index < len) : (index += 1) {
                if (filter.rating_min) |minimum| {
                    if (ratings[index] < minimum) continue;
                }
                if (filter.camera) |camera| {
                    if (cameras[index] != camera) continue;
                }
                if (filter.lens) |lens| {
                    if (lenses[index] != lens) continue;
                }
                if (filter.rejected) |rejected| {
                    if (flags[index].rejected != rejected) continue;
                }
                total += 1;
            }
            return total;
        }

        // -- WAL ----------------------------------------------------------------

        fn wal_append(catalog: *Catalog, payload: []const u8) Error!void {
            assert(payload.len <= wal_record_bytes_max - 8);
            var frame: [wal_record_bytes_max]u8 = undefined;
            std.mem.writeInt(u32, frame[0..4], @intCast(payload.len), .little);
            std.mem.writeInt(u32, frame[4..8], std.hash.crc.Crc32.hash(payload), .little);
            @memcpy(frame[8..][0..payload.len], payload);

            if (!try catalog.fs.exists(wal_path)) try catalog.fs.write_file(wal_path, "");
            try catalog.fs.append_file(wal_path, frame[0 .. 8 + payload.len]);
            try catalog.fs.fsync_file(wal_path);
        }

        fn wal_replay(catalog: *Catalog) Error!void {
            const bytes = catalog.fs.read_alloc(catalog.gpa, wal_path, 1 << 32) catch |err|
                switch (err) {
                    error.NotFound => return,
                    else => return err,
                };
            defer catalog.gpa.free(bytes);

            var offset: usize = 0;
            while (offset < bytes.len) {
                const valid = wal_record_validate(bytes[offset..]) orelse break;
                try catalog.record_apply(valid);
                offset += 8 + valid.len;
            }
            if (offset < bytes.len) {
                // Torn tail: truncate to the valid prefix so future appends
                // land after intact records, never after garbage.
                try catalog.fs.write_file(wal_path, bytes[0..offset]);
                try catalog.fs.fsync_file(wal_path);
            }
        }

        /// The payload of the record at the head of `bytes`, or null for a
        /// torn/corrupt head (length insane, frame truncated, crc wrong).
        fn wal_record_validate(bytes: []const u8) ?[]const u8 {
            if (bytes.len < 8) return null;
            const len = std.mem.readInt(u32, bytes[0..4], .little);
            if (len > wal_record_bytes_max - 8) return null;
            if (bytes.len < 8 + len) return null;
            const payload = bytes[8..][0..len];
            const crc = std.mem.readInt(u32, bytes[4..8], .little);
            if (std.hash.crc.Crc32.hash(payload) != crc) return null;
            return payload;
        }

        const RecordTag = enum(u8) { add_asset = 1, set_rating = 2, set_flags = 3 };

        fn record_apply(catalog: *Catalog, payload: []const u8) Error!void {
            if (payload.len < 9) return error.CorruptCatalog;
            const generation = std.mem.readInt(u64, payload[0..8], .little);
            if (generation != catalog.generation) return; // dead history
            const tag: RecordTag = switch (payload[8]) {
                1 => .add_asset,
                2 => .set_rating,
                3 => .set_flags,
                else => return error.CorruptCatalog,
            };
            const body = payload[9..];
            switch (tag) {
                .add_asset => {
                    const description = record_decode_add(body) orelse
                        return error.CorruptCatalog;
                    if (catalog.asset_by_hash(description.hash) != null) {
                        return error.CorruptCatalog;
                    }
                    _ = try catalog.asset_add_apply(description);
                },
                .set_rating, .set_flags => {
                    if (body.len != 5) return error.CorruptCatalog;
                    const asset = std.mem.readInt(u32, body[0..4], .little);
                    if (asset >= catalog.assets.len) return error.CorruptCatalog;
                    if (tag == .set_rating) {
                        if (body[4] > 5) return error.CorruptCatalog;
                        catalog.assets.items(.rating)[asset] = @intCast(body[4]);
                    } else {
                        catalog.assets.items(.flags)[asset] = @bitCast(body[4]);
                    }
                },
            }
        }

        fn record_encode_add(
            buffer: *[wal_record_bytes_max]u8,
            generation: u64,
            description: AssetDescription,
        ) []const u8 {
            var writer = std.Io.Writer.fixed(buffer);
            writer.writeInt(u64, generation, .little) catch unreachable;
            writer.writeByte(@intFromEnum(RecordTag.add_asset)) catch unreachable;
            writer.writeAll(&description.hash) catch unreachable;
            writer.writeInt(i64, description.capture_time, .little) catch unreachable;
            writer.writeInt(u32, description.iso, .little) catch unreachable;
            writer.writeByte(description.rating) catch unreachable;
            writer.writeByte(@bitCast(description.flags)) catch unreachable;
            writer.writeByte(@intCast(description.camera.len)) catch unreachable;
            writer.writeAll(description.camera) catch unreachable;
            writer.writeByte(@intCast(description.lens.len)) catch unreachable;
            writer.writeAll(description.lens) catch unreachable;
            return writer.buffered();
        }

        fn record_decode_add(body: []const u8) ?AssetDescription {
            if (body.len < 32 + 8 + 4 + 1 + 1 + 1) return null;
            var description = AssetDescription{ .hash = undefined };
            @memcpy(&description.hash, body[0..32]);
            description.capture_time = std.mem.readInt(i64, body[32..40], .little);
            description.iso = std.mem.readInt(u32, body[40..44], .little);
            if (body[44] > 5) return null;
            description.rating = @intCast(body[44]);
            description.flags = @bitCast(body[45]);
            var offset: usize = 46;
            const camera_len = body[offset];
            offset += 1;
            if (offset + camera_len > body.len) return null;
            description.camera = body[offset..][0..camera_len];
            offset += camera_len;
            if (offset >= body.len) return null;
            const lens_len = body[offset];
            offset += 1;
            if (offset + lens_len != body.len) return null;
            description.lens = body[offset..][0..lens_len];
            return description;
        }

        fn record_encode_set(
            buffer: *[wal_record_bytes_max]u8,
            generation: u64,
            tag: RecordTag,
            asset: u32,
            value: u8,
        ) []const u8 {
            assert(tag == .set_rating or tag == .set_flags);
            var writer = std.Io.Writer.fixed(buffer);
            writer.writeInt(u64, generation, .little) catch unreachable;
            writer.writeByte(@intFromEnum(tag)) catch unreachable;
            writer.writeInt(u32, asset, .little) catch unreachable;
            writer.writeByte(value) catch unreachable;
            return writer.buffered();
        }

        /// Mutate in-memory state only; the WAL record is the caller's job.
        fn asset_add_apply(catalog: *Catalog, description: AssetDescription) Error!u32 {
            const gpa = catalog.gpa;
            const hash_id: u32 = if (catalog.hash_ids.get(description.hash)) |id| id else blk: {
                const id: u32 = @intCast(catalog.hashes.items.len);
                try catalog.hashes.append(gpa, description.hash);
                try catalog.hash_ids.put(gpa, description.hash, id);
                break :blk id;
            };
            const index: u32 = @intCast(catalog.assets.len);
            try catalog.assets.append(gpa, .{
                .hash_id = hash_id,
                .recipe_head = 0,
                .capture_time = description.capture_time,
                .rating = description.rating,
                .flags = description.flags,
                .camera = try catalog.cameras.intern(gpa, description.camera),
                .lens = try catalog.lenses.intern(gpa, description.lens),
                .iso = description.iso,
                .burst_group = 0,
                .sharpness = 0,
            });
            try catalog.asset_by_hash_id.put(gpa, hash_id, index);
            return index;
        }

        // -- snapshot -----------------------------------------------------------

        fn snapshot_serialize(catalog: *Catalog, generation: u64) Error![]u8 {
            const gpa = catalog.gpa;
            var bytes: std.ArrayList(u8) = .empty;
            errdefer bytes.deinit(gpa);

            try bytes.appendSlice(gpa, &snapshot_magic);
            try append_int(gpa, &bytes, u32, snapshot_version);
            try append_int(gpa, &bytes, u64, generation);
            try append_int(gpa, &bytes, u32, @intCast(catalog.assets.len));
            try append_int(gpa, &bytes, u32, @intCast(catalog.hashes.items.len));
            try append_int(gpa, &bytes, u16, @intCast(catalog.cameras.strings.items.len));
            try append_int(gpa, &bytes, u16, @intCast(catalog.lenses.strings.items.len));

            for (catalog.hashes.items) |hash| try bytes.appendSlice(gpa, &hash);
            for (catalog.cameras.strings.items) |string| {
                try append_int(gpa, &bytes, u16, @intCast(string.len));
                try bytes.appendSlice(gpa, string);
            }
            for (catalog.lenses.strings.items) |string| {
                try append_int(gpa, &bytes, u16, @intCast(string.len));
                try bytes.appendSlice(gpa, string);
            }

            // Column sections, one per field, in declaration order.
            for (catalog.assets.items(.hash_id)) |v| try append_int(gpa, &bytes, u32, v);
            for (catalog.assets.items(.recipe_head)) |v| try append_int(gpa, &bytes, u32, v);
            for (catalog.assets.items(.capture_time)) |v| try append_int(gpa, &bytes, i64, v);
            for (catalog.assets.items(.rating)) |v| try bytes.append(gpa, v);
            for (catalog.assets.items(.flags)) |v| try bytes.append(gpa, @bitCast(v));
            for (catalog.assets.items(.camera)) |v| try append_int(gpa, &bytes, u16, v);
            for (catalog.assets.items(.lens)) |v| try append_int(gpa, &bytes, u16, v);
            for (catalog.assets.items(.iso)) |v| try append_int(gpa, &bytes, u32, v);
            for (catalog.assets.items(.burst_group)) |v| try append_int(gpa, &bytes, u32, v);
            for (catalog.assets.items(.sharpness)) |v| {
                try append_int(gpa, &bytes, u16, @bitCast(v));
            }

            var trailer: [32]u8 = undefined;
            std.crypto.hash.Blake3.hash(bytes.items, &trailer, .{});
            try bytes.appendSlice(gpa, &trailer);
            return bytes.toOwnedSlice(gpa);
        }

        fn snapshot_load(catalog: *Catalog) Error!void {
            assert(catalog.assets.len == 0);
            const bytes = catalog.fs.read_alloc(catalog.gpa, snapshot_path, 1 << 32) catch |err|
                switch (err) {
                    error.NotFound => return, // fresh catalog
                    else => return err,
                };
            defer catalog.gpa.free(bytes);
            if (bytes.len < 24 + 32) return error.CorruptCatalog;

            // The trailer seals everything: verify before reading a field.
            const body = bytes[0 .. bytes.len - 32];
            var trailer: [32]u8 = undefined;
            std.crypto.hash.Blake3.hash(body, &trailer, .{});
            if (!std.mem.eql(u8, &trailer, bytes[bytes.len - 32 ..])) {
                return error.CorruptCatalog;
            }

            var reader = SnapshotReader{ .bytes = body };
            if (!std.mem.eql(u8, try reader.take(4), &snapshot_magic)) {
                return error.CorruptCatalog;
            }
            if (try reader.int(u32) != snapshot_version) return error.CorruptCatalog;
            catalog.generation = try reader.int(u64);
            const asset_count = try reader.int(u32);
            const hash_count = try reader.int(u32);
            const camera_count = try reader.int(u16);
            const lens_count = try reader.int(u16);
            if (asset_count > assets_max) return error.CorruptCatalog;

            try catalog.snapshot_load_tables(&reader, hash_count, camera_count, lens_count);
            try catalog.snapshot_load_columns(&reader, asset_count);
            if (reader.offset != reader.bytes.len) return error.CorruptCatalog;

            // Rebuild the asset-by-hash index from the rows.
            for (catalog.assets.items(.hash_id), 0..) |hash_id, index| {
                if (hash_id >= catalog.hashes.items.len) return error.CorruptCatalog;
                try catalog.asset_by_hash_id.put(
                    catalog.gpa,
                    hash_id,
                    @intCast(index),
                );
            }
        }

        fn snapshot_load_tables(
            catalog: *Catalog,
            reader: *SnapshotReader,
            hash_count: u32,
            camera_count: u16,
            lens_count: u16,
        ) Error!void {
            const gpa = catalog.gpa;
            var index: u32 = 0;
            while (index < hash_count) : (index += 1) {
                var hash: vault.Hash = undefined;
                @memcpy(&hash, try reader.take(32));
                try catalog.hashes.append(gpa, hash);
                try catalog.hash_ids.put(gpa, hash, index);
            }
            var camera: u16 = 0;
            while (camera < camera_count) : (camera += 1) {
                const len = try reader.int(u16);
                if (len > string_bytes_max) return error.CorruptCatalog;
                _ = try catalog.cameras.intern(gpa, try reader.take(len));
            }
            var lens: u16 = 0;
            while (lens < lens_count) : (lens += 1) {
                const len = try reader.int(u16);
                if (len > string_bytes_max) return error.CorruptCatalog;
                _ = try catalog.lenses.intern(gpa, try reader.take(len));
            }
        }

        fn snapshot_load_columns(
            catalog: *Catalog,
            reader: *SnapshotReader,
            asset_count: u32,
        ) Error!void {
            try catalog.assets.resize(catalog.gpa, asset_count);
            for (catalog.assets.items(.hash_id)) |*v| v.* = try reader.int(u32);
            for (catalog.assets.items(.recipe_head)) |*v| v.* = try reader.int(u32);
            for (catalog.assets.items(.capture_time)) |*v| v.* = try reader.int(i64);
            for (catalog.assets.items(.rating)) |*v| {
                const raw = try reader.int(u8);
                if (raw > 5) return error.CorruptCatalog;
                v.* = @intCast(raw);
            }
            for (catalog.assets.items(.flags)) |*v| v.* = @bitCast(try reader.int(u8));
            for (catalog.assets.items(.camera)) |*v| v.* = try reader.int(u16);
            for (catalog.assets.items(.lens)) |*v| v.* = try reader.int(u16);
            for (catalog.assets.items(.iso)) |*v| v.* = try reader.int(u32);
            for (catalog.assets.items(.burst_group)) |*v| v.* = try reader.int(u32);
            for (catalog.assets.items(.sharpness)) |*v| v.* = @bitCast(try reader.int(u16));
        }
    };
}

const SnapshotReader = struct {
    bytes: []const u8,
    offset: usize = 0,

    fn take(reader: *SnapshotReader, len: usize) Error![]const u8 {
        if (reader.offset + len > reader.bytes.len) return error.CorruptCatalog;
        defer reader.offset += len;
        return reader.bytes[reader.offset..][0..len];
    }

    fn int(reader: *SnapshotReader, comptime T: type) Error!T {
        const slice = try reader.take(@sizeOf(T));
        return std.mem.readInt(T, slice[0..@sizeOf(T)], .little);
    }
};

fn append_int(
    gpa: std.mem.Allocator,
    bytes: *std.ArrayList(u8),
    comptime T: type,
    value: T,
) !void {
    var buffer: [@sizeOf(T)]u8 = undefined;
    std.mem.writeInt(T, &buffer, value, .little);
    try bytes.appendSlice(gpa, &buffer);
}

// ---- tests ---------------------------------------------------------------------

const TestCatalog = CatalogType(vfs.Sim);

fn test_hash(seed: u8) vault.Hash {
    var hash: vault.Hash = @splat(seed);
    hash[0] = seed +% 1;
    return hash;
}

test "add, rate, flag: reopen replays the WAL to identical state" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 21, .{});
    defer sim.deinit();

    {
        var catalog = try TestCatalog.open(gpa, &sim);
        defer catalog.deinit();
        const a = try catalog.asset_add(.{
            .hash = test_hash(1),
            .camera = "Canon EOS 350D",
            .lens = "EF 35mm f/2",
            .iso = 400,
            .capture_time = 1_700_000_000,
        });
        _ = try catalog.asset_add(.{
            .hash = test_hash(2),
            .camera = "Canon EOS 350D",
            .lens = "EF 50mm f/1.8",
            .iso = 100,
        });
        try catalog.rating_set(a, 4);
        try catalog.flags_set(a, .{ .pick = true });
    }

    var catalog = try TestCatalog.open(gpa, &sim);
    defer catalog.deinit();
    try std.testing.expectEqual(@as(u32, 2), catalog.count());
    try std.testing.expectEqual(@as(u3, 4), catalog.assets.items(.rating)[0]);
    try std.testing.expect(catalog.assets.items(.flags)[0].pick);
    try std.testing.expectEqual(@as(u32, 100), catalog.assets.items(.iso)[1]);
    // Interning: one camera id shared, two lens ids distinct.
    try std.testing.expectEqual(
        catalog.assets.items(.camera)[0],
        catalog.assets.items(.camera)[1],
    );
    try std.testing.expect(
        catalog.assets.items(.lens)[0] != catalog.assets.items(.lens)[1],
    );
    try std.testing.expectEqualStrings(
        "Canon EOS 350D",
        catalog.cameras.get(catalog.assets.items(.camera)[0]),
    );
    try std.testing.expectEqual(@as(u32, 0), catalog.asset_by_hash(test_hash(1)).?);
}

test "compact folds the WAL into a snapshot; replay stays identical" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 22, .{});
    defer sim.deinit();

    {
        var catalog = try TestCatalog.open(gpa, &sim);
        defer catalog.deinit();
        var i: u8 = 0;
        while (i < 20) : (i += 1) {
            _ = try catalog.asset_add(.{
                .hash = test_hash(i),
                .camera = if (i % 2 == 0) "A" else "B",
                .lens = "L",
                .iso = @as(u32, i) * 100,
            });
        }
        try catalog.rating_set(7, 5);
        try catalog.compact();
        // Post-compact mutations land in the new generation's WAL.
        try catalog.rating_set(8, 3);
    }

    var catalog = try TestCatalog.open(gpa, &sim);
    defer catalog.deinit();
    try std.testing.expectEqual(@as(u32, 20), catalog.count());
    try std.testing.expectEqual(@as(u3, 5), catalog.assets.items(.rating)[7]);
    try std.testing.expectEqual(@as(u3, 3), catalog.assets.items(.rating)[8]);
    try std.testing.expectEqual(@as(u64, 1), catalog.generation);
}

test "a torn WAL tail is truncated, never half-applied (negative space)" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 23, .{});
    defer sim.deinit();

    {
        var catalog = try TestCatalog.open(gpa, &sim);
        defer catalog.deinit();
        _ = try catalog.asset_add(.{ .hash = test_hash(1), .camera = "A", .lens = "L" });
        _ = try catalog.asset_add(.{ .hash = test_hash(2), .camera = "A", .lens = "L" });
    }

    // Tear the last record mid-frame, the way a power cut would.
    const wal = try sim.read_alloc(gpa, wal_path, 1 << 20);
    defer gpa.free(wal);
    try sim.write_file(wal_path, wal[0 .. wal.len - 7]);

    var catalog = try TestCatalog.open(gpa, &sim);
    defer catalog.deinit();
    try std.testing.expectEqual(@as(u32, 1), catalog.count());

    // And appending after recovery lands cleanly on the truncated log.
    _ = try catalog.asset_add(.{ .hash = test_hash(3), .camera = "A", .lens = "L" });
    var reopened = try TestCatalog.open(gpa, &sim);
    defer reopened.deinit();
    try std.testing.expectEqual(@as(u32, 2), reopened.count());
}

test "a bit flipped anywhere in the snapshot is caught by the trailer" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 24, .{});
    defer sim.deinit();

    {
        var catalog = try TestCatalog.open(gpa, &sim);
        defer catalog.deinit();
        _ = try catalog.asset_add(.{ .hash = test_hash(9), .camera = "A", .lens = "L" });
        try catalog.compact();
    }

    const snapshot = try sim.read_alloc(gpa, snapshot_path, 1 << 20);
    defer gpa.free(snapshot);
    const tampered = try gpa.dupe(u8, snapshot);
    defer gpa.free(tampered);
    tampered[tampered.len / 2] ^= 1;
    try sim.write_file(snapshot_path, tampered);

    try std.testing.expectEqual(error.CorruptCatalog, TestCatalog.open(gpa, &sim));
}

test "property: random op sequences replay to identical state (seeded)" {
    const gpa = std.testing.allocator;
    var seed: u64 = 0;
    while (seed < 20) : (seed += 1) {
        var sim = vfs.Sim.init(gpa, 3000 + seed, .{});
        defer sim.deinit();
        var prng = seed *% 0x9E3779B97F4A7C15 +% 1;

        var expected_ratings: [64]u3 = @splat(0);
        var added: u32 = 0;
        {
            var catalog = try TestCatalog.open(gpa, &sim);
            defer catalog.deinit();
            var op: u32 = 0;
            while (op < 40) : (op += 1) {
                const roll = splitmix64(&prng);
                if (roll % 4 == 0 and added > 0) {
                    const asset: u32 = @intCast(splitmix64(&prng) % added);
                    const rating: u3 = @intCast(splitmix64(&prng) % 6);
                    try catalog.rating_set(asset, rating);
                    expected_ratings[asset] = rating;
                } else if (roll % 7 == 0 and added > 4) {
                    try catalog.compact();
                } else if (added < 64) {
                    _ = try catalog.asset_add(.{
                        .hash = test_hash(@intCast(added)),
                        .camera = if (roll % 2 == 0) "A" else "B",
                        .lens = "L",
                        .iso = @intCast(roll % 12800),
                    });
                    added += 1;
                }
            }
        }

        var catalog = try TestCatalog.open(gpa, &sim);
        defer catalog.deinit();
        try std.testing.expectEqual(added, catalog.count());
        for (catalog.assets.items(.rating), 0..) |rating, index| {
            try std.testing.expectEqual(expected_ratings[index], rating);
        }
    }
}

test "filter scans match a naive row-by-row oracle" {
    const gpa = std.testing.allocator;
    var sim = vfs.Sim.init(gpa, 25, .{});
    defer sim.deinit();
    var catalog = try TestCatalog.open(gpa, &sim);
    defer catalog.deinit();

    var prng: u64 = 77;
    var expected: u32 = 0;
    var i: u32 = 0;
    while (i < 200) : (i += 1) {
        const rating: u3 = @intCast(splitmix64(&prng) % 6);
        const lens: []const u8 = if (splitmix64(&prng) % 3 == 0) "wide" else "tele";
        var hash: vault.Hash = @splat(0);
        std.mem.writeInt(u32, hash[0..4], i, .little);
        const index = try catalog.asset_add(.{ .hash = hash, .camera = "C", .lens = lens });
        try catalog.rating_set(index, rating);
        if (rating >= 4 and std.mem.eql(u8, lens, "wide")) expected += 1;
    }

    const wide = catalog.lenses.ids.get("wide").?;
    const counted = catalog.filter_count(.{ .rating_min = 4, .lens = wide });
    try std.testing.expectEqual(expected, counted);
}

fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}
