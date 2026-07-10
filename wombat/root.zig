//! wombat — storage: content-addressed blob vault, content-defined chunking,
//! the columnar catalog, sessions, persistence. The burrow: everything on
//! disk. Lands in Phase 2; this stub pins the module layout and test wiring.

const std = @import("std");

pub const phase = 2;

test "wombat stub" {
    try std.testing.expectEqual(@as(u32, 2), phase);
}
