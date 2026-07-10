//! lyrebird — similarity: perceptual hashing, near-duplicate detection,
//! burst grouping, sharpness scoring. The great mimic finds the copies.
//! Lands in Phase 4; this stub pins the module layout and test wiring.

const std = @import("std");

pub const phase = 4;

test "lyrebird stub" {
    try std.testing.expectEqual(@as(u32, 4), phase);
}
