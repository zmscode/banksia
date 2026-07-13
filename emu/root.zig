//! emu — the develop engine: decode, colour, the linear-f32 pipeline,
//! render cache, thumbnails. Fast; only runs forward.
//!
//! The engine is a pure function: `(blob, recipe, engine_version) → pixels`.
//! No clock, no RNG, no I/O beyond the input blob, no global state.

pub const image = @import("image.zig");
pub const dng = @import("dng.zig");
pub const dng_write = @import("dng_write.zig");
pub const color = @import("color.zig");
pub const calibration = @import("calibration.zig");
pub const film_curve = @import("film_curve.zig");
pub const icc_profile = @import("icc_profile.zig");
pub const reconstruction = @import("reconstruction.zig");
pub const render_manifest = @import("render_manifest.zig");
pub const geometry = @import("geometry.zig");
pub const libraw = @import("libraw.zig");
pub const raw = @import("raw.zig");
pub const jpeg_lossless = @import("jpeg_lossless.zig");
pub const pipeline = @import("pipeline.zig");
pub const recipe = @import("recipe.zig");
pub const png = @import("png.zig");

test {
    _ = image;
    _ = dng;
    _ = dng_write;
    _ = color;
    _ = calibration;
    _ = film_curve;
    _ = icc_profile;
    _ = reconstruction;
    _ = render_manifest;
    _ = geometry;
    _ = libraw;
    _ = raw;
    _ = jpeg_lossless;
    _ = pipeline;
    _ = recipe;
    _ = png;
}
