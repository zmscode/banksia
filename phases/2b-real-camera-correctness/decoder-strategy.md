# Phase 2B decoder strategy

## Decision

Banksia uses two sensor-data backends behind `emu.raw`:

1. **Native DNG first** — deterministic reference implementation and required
   conformance path.
2. **LibRaw fallback** — proprietary containers explicitly recognized by the
   native parser, currently Canon CR2 and CR3.

LibRaw is required before private alpha because the initial real-camera corpus
is entirely CR2/CR3. macOS ImageIO remains a developed-RGB visual oracle; it is
not used as Banksia's sensor or colour pipeline.

## Integration boundary

The wrapper calls `libraw_open_buffer` and `libraw_unpack`, then copies the
visible CFA mosaic and metadata into Banksia-owned `DecodedRaw` structures. It
does **not** call LibRaw demosaic, auto-brightness, colour conversion, gamma, or
output encoding. Banksia remains responsible for black subtraction, white
balance, demosaic, colour transforms, tone, geometry, and rendering.

The wrapper preserves LibRaw's 2×2 per-site `cblack` corrections. The existing
scalar DNG path remains unchanged; engine-v1 golden output is therefore stable.

## Version and build

- Validated LibRaw: **0.22.1**.
- macOS development install: `brew install libraw`.
- Default prefix: `/opt/homebrew/opt/libraw`.
- Override: `zig build -Dlibraw-prefix=/other/prefix`.
- Linked library: `libraw_r`, the thread-safe build. A fresh LibRaw context is
  created per decode, so future import/decode jobs may run in parallel without
  sharing decoder state.

Homebrew's installation is approximately 6.4 MB for LibRaw itself. The dynamic
library is approximately 1.0 MB and depends on jpeg-turbo, libtiff, little-cms2,
libomp, and their transitive image libraries.

## Licensing and distribution

LibRaw 0.22.1 is offered under **LGPL-2.1-only OR CDDL-1.0**. Banksia currently
links dynamically. Static redistribution, app-bundle embedding, notices,
source-offer obligations, and replacement-library requirements need a release
licensing review before distribution. No LibRaw source is copied into this
repository.

## Evidence

- Native and LibRaw backends agree on a 512×384 synthetic DNG's dimensions,
  Bayer layout, sensor samples, black level, and white level.
- All 9 Canon EOS-1D X Mark II CR2 files unpack to 5496×3670 Bayer mosaics.
- All 9 Canon EOS R3 CR3 files unpack to 6032×4032 Bayer mosaics.
- The local 18-file hash + LibRaw mosaic + ImageIO preview gate completes in
  approximately 21.28 seconds.
- ReleaseFast C ABI render, Canon EOS-1D X Mark II: 120.4 ms edge-1024 preview,
  684.6 ms full sensor render.
- ReleaseFast C ABI render, Canon EOS R3: 166.2 ms edge-1024 preview,
  654.7 ms full sensor render.

The LibRaw sensor dimensions exceed ImageIO's developed output dimensions
(5472×3648 and 6000×4000 respectively). Phase 2B geometry must resolve the
camera-recommended crop before those developed dimensions are treated as an
oracle.
