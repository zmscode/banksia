//! Planar image buffers. Pixels are struct-of-arrays: one tightly packed
//! f32 plane per channel rather than interleaved RGB, so every kernel is a
//! clean `@Vector` loop over contiguous memory.

const std = @import("std");
const assert = std.debug.assert;

/// Longest edge the engine will process. A bound, not a target: 65535 keeps
/// `width * height` inside u32 and any byte size inside u64 by construction.
pub const edge_px_max: u32 = 65535;

comptime {
    // The pixel count of the largest image must fit in usize arithmetic on
    // 32-bit targets too; the C ABI packs RGBA8, 4 bytes per pixel.
    assert(@as(u64, edge_px_max) * edge_px_max < (1 << 63) / 4);
}

pub const Planes = struct {
    width: u32,
    height: u32,
    r: []f32,
    g: []f32,
    b: []f32,

    pub fn init(gpa: std.mem.Allocator, width: u32, height: u32) !Planes {
        assert(width > 0);
        assert(height > 0);
        assert(width <= edge_px_max);
        assert(height <= edge_px_max);
        const count = @as(usize, width) * @as(usize, height);
        const r = try gpa.alloc(f32, count);
        errdefer gpa.free(r);
        const g = try gpa.alloc(f32, count);
        errdefer gpa.free(g);
        const b = try gpa.alloc(f32, count);
        return .{ .width = width, .height = height, .r = r, .g = g, .b = b };
    }

    pub fn deinit(self: *Planes, gpa: std.mem.Allocator) void {
        assert(self.r.len == self.g.len);
        assert(self.g.len == self.b.len);
        gpa.free(self.r);
        gpa.free(self.g);
        gpa.free(self.b);
        self.* = undefined;
    }

    pub fn pixel_count(self: *const Planes) usize {
        const count = @as(usize, self.width) * @as(usize, self.height);
        assert(count == self.r.len);
        return count;
    }
};

test "planes are allocated per channel and sized exactly" {
    const gpa = std.testing.allocator;
    var planes = try Planes.init(gpa, 7, 3);
    defer planes.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 21), planes.pixel_count());
    try std.testing.expectEqual(@as(usize, 21), planes.r.len);
}
