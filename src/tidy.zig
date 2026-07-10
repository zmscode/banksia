//! Non-functional properties of the source itself, enforced as a test.
//!
//! Modelled on TigerBeetle's `src/tidy.zig` via bottlebrush's: every
//! convention that *can* be checked mechanically is, so code review is free
//! to discuss design instead of line length.
//!
//!   zig build test-tidy
//!
//! Bans are hard and each names its replacement. The long-line budget is a
//! ratchet: banksia starts at zero debt and stays there.

const std = @import("std");

/// Directories walked, relative to the project root.
const source_roots = [_][]const u8{ "src", "emu", "wombat", "lyrebird", "golden" };

const Ban = struct {
    /// Matched as a plain substring, comments included.
    pattern: []const u8,
    replacement: []const u8,
    /// Files that are allowed to contain it anyway.
    exempt: []const []const u8 = &.{},
};

const bans = [_]Ban{
    // Zig 0.16 std drift, inherited from bottlebrush's scar tissue.
    .{ .pattern = "posix.getenv(", .replacement = "init.environ_map (removed in Zig 0.16)" },
    .{ .pattern = "GeneralPurposeAllocator", .replacement = "std.heap.DebugAllocator" },
    .{ .pattern = "refAllDeclsRecursive", .replacement = "explicit `_ = @import(\"x.zig\");`" },
    .{ .pattern = "ArrayListUnmanaged", .replacement = "std.ArrayList (unmanaged in 0.16)" },
    .{ .pattern = "trimRight(", .replacement = "std.mem.trimEnd" },
    .{ .pattern = "trimLeft(", .replacement = "std.mem.trimStart" },
    .{ .pattern = "std.time.Timer", .replacement = "std.Io.Clock.now(.awake, io)" },
    .{ .pattern = "usingnamespace", .replacement = "explicit re-exports" },

    // banksia rules.
    .{ .pattern = "Self = @This()", .replacement = "the type's real name" },
    // Determinism doctrine: no std PRNG anywhere near the engine or the
    // test substrate; hand-rolled integer generators only (plan.md).
    .{ .pattern = "std.Random", .replacement = "a seeded SplitMix64 (determinism)" },
    // Libraries are silent; only entry points (the CLI and the harness
    // runners) report to a human.
    .{
        .pattern = "std.debug.print(",
        .replacement = "returning errors (libraries are silent)",
        .exempt = &.{ "src/main.zig", "golden/runner.zig", "wombat/sim.zig" },
    },
    // wombat owns every byte on disk (plan.md invariant 3). Everything
    // else writes through the vfs seam or wombat.vfs.user_file_write.
    .{
        .pattern = "createFile(",
        .replacement = "wombat.vfs (wombat owns every byte on disk)",
        .exempt = &.{"wombat/vfs.zig"},
    },
};

/// Allowed while iterating, never on main.
const reminders = [_][]const u8{ "FIXME", "TODO(now)", "// DEBUG" };

/// Lines over 100 columns, per file. Unlisted files must have none, and
/// banksia starts with an empty table: zero debt, kept at zero.
const long_line_budget = [_]struct { []const u8, u32 }{};

const max_columns = 100;
const max_file_bytes = std.Io.Limit.limited(4 * 1024 * 1024);

fn budget_for(path: []const u8) u32 {
    for (long_line_budget) |entry| {
        if (std.mem.eql(u8, entry[0], path)) return entry[1];
    }
    return 0;
}

fn is_exempt(ban: Ban, path: []const u8) bool {
    for (ban.exempt) |e| {
        if (std.mem.eql(u8, e, path)) return true;
    }
    return false;
}

/// A long line that is nothing but a URL cannot be wrapped.
fn is_unwrappable_link(line: []const u8) bool {
    const trimmed = std.mem.trim(u8, line, " \t");
    if (std.mem.indexOf(u8, trimmed, "http://") == null and
        std.mem.indexOf(u8, trimmed, "https://") == null) return false;
    return std.mem.indexOfScalar(u8, trimmed, ' ') == null or
        std.mem.startsWith(u8, trimmed, "//") or std.mem.startsWith(u8, trimmed, "///");
}

test "tidy" {
    const gpa = std.testing.allocator;

    var threaded = std.Io.Threaded.init_single_threaded;
    const io = threaded.io();

    var failures: usize = 0;

    for (source_roots) |root| {
        var dir = try std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true });
        defer dir.close(io);

        var walker = try dir.walk(gpa);
        defer walker.deinit();

        while (try walker.next(io)) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.basename, ".zig")) continue;

            const path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ root, entry.path });
            defer gpa.free(path);
            // tidy names every banned construct; do not ban ourselves.
            if (std.mem.eql(u8, path, "src/tidy.zig")) continue;

            const text = try dir.readFileAlloc(io, entry.path, gpa, max_file_bytes);
            defer gpa.free(text);

            failures += check_bans(path, text);
            failures += check_lines(path, text);
        }
    }

    if (failures > 0) {
        std.debug.print("\ntidy: {d} finding(s)\n", .{failures});
        return error.TidyFailed;
    }
}

fn check_bans(path: []const u8, text: []const u8) usize {
    var failures: usize = 0;
    for (bans) |ban| {
        if (is_exempt(ban, path)) continue;
        if (std.mem.indexOf(u8, text, ban.pattern) != null) {
            std.debug.print(
                "{s}: '{s}' is banned, use {s}\n",
                .{ path, ban.pattern, ban.replacement },
            );
            failures += 1;
        }
    }
    for (reminders) |reminder| {
        if (std.mem.indexOf(u8, text, reminder) != null) {
            std.debug.print("{s}: '{s}' must be resolved before merging\n", .{ path, reminder });
            failures += 1;
        }
    }
    return failures;
}

fn check_lines(path: []const u8, text: []const u8) usize {
    var failures: usize = 0;
    var long: u32 = 0;
    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        line_no += 1;
        if (std.mem.endsWith(u8, line, " ") or std.mem.endsWith(u8, line, "\t")) {
            std.debug.print("{s}:{d}: trailing whitespace\n", .{ path, line_no });
            failures += 1;
        }
        if (std.mem.indexOfScalar(u8, line, '\t') != null) {
            std.debug.print("{s}:{d}: tab (indent with 4 spaces)\n", .{ path, line_no });
            failures += 1;
        }
        if (std.mem.indexOfScalar(u8, line, '\r') != null) {
            std.debug.print("{s}:{d}: carriage return\n", .{ path, line_no });
            failures += 1;
        }
        if (line.len > max_columns and !is_unwrappable_link(line)) long += 1;
    }

    const budget = budget_for(path);
    if (long > budget) {
        std.debug.print(
            "{s}: {d} lines over {d} columns, budget is {d}. New code must fit.\n",
            .{ path, long, max_columns, budget },
        );
        failures += 1;
    }
    return failures;
}
