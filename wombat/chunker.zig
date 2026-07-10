//! FastCDC content-defined chunking, for the few big files that do mutate
//! (catalog snapshots, exports). RAW blobs are whole-file addressed — they
//! never change, and distinct RAWs share no bytes; that dedup won't happen
//! is documented, not hoped against.
//!
//! The cut condition is the FastCDC'16 shape: a gear hash rolls over the
//! bytes, judged against a hard mask before the average size (making small
//! chunks unlikely) and an easy mask after it (making oversized chunks
//! unlikely), clamped to [min, max]. The gear table is comptime-generated
//! from a fixed SplitMix64 seed: boundaries are a pure function of content,
//! reproducible forever — a boundary change is a format change.

const std = @import("std");
const assert = std.debug.assert;

pub const Config = struct {
    chunk_bytes_min: u32,
    chunk_bytes_avg: u32,
    chunk_bytes_max: u32,
};

/// 256KiB / 1MiB / 4MiB: snapshot-scale files land in a few dozen chunks.
pub const config_default = Config{
    .chunk_bytes_min = 256 * 1024,
    .chunk_bytes_avg = 1024 * 1024,
    .chunk_bytes_max = 4 * 1024 * 1024,
};

pub const Chunk = struct {
    offset: u64,
    len: u32,
};

pub fn ChunkerType(comptime config: Config) type {
    comptime {
        assert(std.math.isPowerOfTwo(config.chunk_bytes_avg));
        assert(config.chunk_bytes_min >= 64);
        assert(config.chunk_bytes_min < config.chunk_bytes_avg);
        assert(config.chunk_bytes_avg < config.chunk_bytes_max);
        // The two-stage masks need headroom either side of the average.
        assert(std.math.log2_int(u32, config.chunk_bytes_avg) >= 4);
        assert(std.math.log2_int(u32, config.chunk_bytes_avg) + 2 <= 62);
    }
    const average_bits = std.math.log2_int(u32, config.chunk_bytes_avg);
    // More bits before the average point (cuts are rare), fewer after
    // (cuts are likely): FastCDC's normalized chunking. High bits carry
    // the gear hash's entropy — the accumulator shifts left.
    const mask_hard: u64 = ~(~@as(u64, 0) >> (average_bits + 2));
    const mask_easy: u64 = ~(~@as(u64, 0) >> (average_bits - 2));

    return struct {
        bytes: []const u8,
        offset: u64 = 0,

        const Chunker = @This();

        pub fn init(bytes: []const u8) Chunker {
            return .{ .bytes = bytes };
        }

        /// Chunks tile the input exactly: offsets are contiguous, every
        /// byte lands in exactly one chunk, and only the final chunk may
        /// be shorter than `chunk_bytes_min`.
        pub fn next(chunker: *Chunker) ?Chunk {
            if (chunker.offset == chunker.bytes.len) return null;
            assert(chunker.offset < chunker.bytes.len);
            const remaining = chunker.bytes[chunker.offset..];
            const len = cut(remaining);
            assert(len > 0);
            assert(len <= remaining.len);
            const chunk = Chunk{ .offset = chunker.offset, .len = len };
            chunker.offset += len;
            return chunk;
        }

        /// Length of the first chunk of `bytes` — the boundary judgment.
        pub fn cut(bytes: []const u8) u32 {
            if (bytes.len <= config.chunk_bytes_min) return @intCast(bytes.len);
            const scan_end: u32 = @intCast(@min(bytes.len, config.chunk_bytes_max));
            const normal_point: u32 = @min(scan_end, config.chunk_bytes_avg);

            var hash: u64 = 0;
            var index: u32 = config.chunk_bytes_min;
            while (index < normal_point) : (index += 1) {
                hash = (hash << 1) +% gear[bytes[index]];
                if (hash & mask_hard == 0) return index + 1;
            }
            while (index < scan_end) : (index += 1) {
                hash = (hash << 1) +% gear[bytes[index]];
                if (hash & mask_easy == 0) return index + 1;
            }
            return scan_end;
        }
    };
}

/// The gear table: 256 constants from a fixed seed. Comptime, so the table
/// is a compile-time artifact — it cannot drift at runtime, and changing
/// the seed is visibly a format change.
const gear = blk: {
    @setEvalBranchQuota(4000);
    var table: [256]u64 = undefined;
    var state: u64 = 0xB05B_A11B_1237_2A97; // fixed forever; format constant
    for (&table) |*entry| entry.* = splitmix64(&state);
    break :blk table;
};

test "gear table spot values pin the format" {
    // Two spot values pin the table (and therefore every boundary ever
    // computed) against accidental regeneration.
    try std.testing.expectEqual(@as(u64, 0x6dad9c7741fb4c24), gear[0]);
    try std.testing.expectEqual(@as(u64, 0x0951c5dd1c039d41), gear[255]);
}

fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}

// ---- tests ---------------------------------------------------------------------

/// Small windows so tests exercise many boundaries cheaply; the judgment
/// logic is identical to the default config.
const TestChunker = ChunkerType(.{
    .chunk_bytes_min = 64,
    .chunk_bytes_avg = 256,
    .chunk_bytes_max = 1024,
});

fn test_content(gpa: std.mem.Allocator, len: usize, seed: u64) ![]u8 {
    const bytes = try gpa.alloc(u8, len);
    var state = seed;
    var index: usize = 0;
    while (index < bytes.len) : (index += 8) {
        const word = splitmix64(&state);
        const remain = @min(8, bytes.len - index);
        @memcpy(bytes[index..][0..remain], std.mem.asBytes(&word)[0..remain]);
    }
    return bytes;
}

test "chunks tile the input exactly, within bounds" {
    const gpa = std.testing.allocator;
    const bytes = try test_content(gpa, 100_000, 1);
    defer gpa.free(bytes);

    var chunker = TestChunker.init(bytes);
    var expected_offset: u64 = 0;
    var count: u32 = 0;
    while (chunker.next()) |chunk| {
        try std.testing.expectEqual(expected_offset, chunk.offset);
        try std.testing.expect(chunk.len <= 1024);
        expected_offset += chunk.len;
        count += 1;
        // Every chunk but the last respects the minimum.
        if (expected_offset < bytes.len) {
            try std.testing.expect(chunk.len >= 64);
        }
    }
    try std.testing.expectEqual(@as(u64, bytes.len), expected_offset);
    // ~100k / ~256 average: the cut condition is actually firing.
    try std.testing.expect(count > 100);
    try std.testing.expect(count < 1600);
}

test "boundaries are content-defined: one inserted byte only moves the front" {
    const gpa = std.testing.allocator;
    const original = try test_content(gpa, 200_000, 2);
    defer gpa.free(original);

    const shifted = try gpa.alloc(u8, original.len + 1);
    defer gpa.free(shifted);
    shifted[0] = 0xA5;
    @memcpy(shifted[1..], original);

    // Hash every chunk of both versions; the two lists must share an
    // identical tail — only the leading chunk(s) may differ.
    var hashes_original: std.ArrayList(u64) = .empty;
    defer hashes_original.deinit(gpa);
    var hashes_shifted: std.ArrayList(u64) = .empty;
    defer hashes_shifted.deinit(gpa);

    var chunker = TestChunker.init(original);
    while (chunker.next()) |chunk| {
        const slice = original[@intCast(chunk.offset)..][0..chunk.len];
        try hashes_original.append(gpa, std.hash.XxHash64.hash(0, slice));
    }
    chunker = TestChunker.init(shifted);
    while (chunker.next()) |chunk| {
        const slice = shifted[@intCast(chunk.offset)..][0..chunk.len];
        try hashes_shifted.append(gpa, std.hash.XxHash64.hash(0, slice));
    }

    // Find where the shifted list re-synchronizes with the original.
    const a = hashes_original.items;
    const b = hashes_shifted.items;
    var tail: usize = 0;
    while (tail < a.len and tail < b.len and
        a[a.len - 1 - tail] == b[b.len - 1 - tail]) tail += 1;
    // Nearly everything re-aligns: at ~780 chunks, all but the first few
    // are byte-identical content at shifted offsets.
    try std.testing.expect(tail + 8 >= a.len);
    try std.testing.expect(a.len - tail <= 8);
}

test "exhaustive small sweep: deterministic, snapshot-pinned boundaries" {
    const gpa = std.testing.allocator;
    // Every input length 0..8KiB: chunk, fold all boundaries into one
    // digest. The digest is pinned — a boundary change anywhere in the
    // sweep is a format change and must be deliberate.
    const bytes = try test_content(gpa, 8192, 3);
    defer gpa.free(bytes);

    var digest: u64 = 0;
    var len: usize = 0;
    while (len <= bytes.len) : (len += 1) {
        var chunker = TestChunker.init(bytes[0..len]);
        var tiled: u64 = 0;
        while (chunker.next()) |chunk| {
            digest = (digest *% 0x100000001B3) ^ chunk.offset ^ (@as(u64, chunk.len) << 32);
            tiled += chunk.len;
        }
        try std.testing.expectEqual(@as(u64, len), tiled);
    }
    try std.testing.expectEqual(@as(u64, 0x06555354ee9e7b44), digest);
}

test "the empty input yields no chunks (negative space)" {
    var chunker = TestChunker.init("");
    try std.testing.expectEqual(null, chunker.next());
}
