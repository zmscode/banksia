//! wombat — storage: content-addressed blob vault, content-defined chunking,
//! the columnar catalog, sessions, persistence. The burrow: everything on
//! disk — nothing outside wombat opens a file for writing (tidy-enforced).
//!
//! Every byte goes through the `vfs` seam, so the whole layer runs under
//! the crash simulator with seed-reproducible fault injection.

pub const vfs = @import("vfs.zig");
pub const vault = @import("vault.zig");

test {
    _ = vfs;
    _ = vault;
}
