# banksia

A RAW photo editor in Zig: a headless, deterministic develop engine with
non-destructive edits, content-addressed storage, and git-like versioning,
driven by a golden-render conformance harness from day one.

See [plan.md](plan.md) for the architecture and the phased implementation
plan.

## Status: Phase 0 — emu bootstrap (core complete)

The develop engine (**emu**) decodes uncompressed DNG (pure Zig: bounded
TIFF/IFD walk, both byte orders, strips), runs a linear scene-referred f32
pipeline (black point → white balance → bilinear demosaic, comptime-
specialized per CFA → exposure → tone curve → sRGB), and renders to PNG from
the CLI. Renders are deterministic — two runs are byte-identical, held by a
test. The golden harness renders 10 synthetic-scene cases through the whole
engine (container write → decode → render) and compares SHA-256es against
`golden/baseline.json` in CI; any drift fails the build.

Deferred within Phase 0: the libraw fallback backend and lossless-JPEG DNG
(see plan.md for the deviation notes).

The libraries, per the house naming scheme (Australian flora for projects,
fauna for the libraries inside):

- **emu** (`emu/`) — the develop engine: decode, colour, pipeline, render
  cache, thumbnails.
- **wombat** (`wombat/`) — storage: content-addressed blob vault, chunking,
  the columnar catalog, sessions. *(Phase 2 — stub.)*
- **lyrebird** (`lyrebird/`) — similarity: perceptual hashing, burst
  grouping, sharpness scoring. *(Phase 4 — stub.)*

## Requirements

- Zig **0.16.0**

## Commands

```sh
zig build              # build the CLI
zig build test         # unit tests + tidy lint
zig build render -- <raw.dng> <recipe.json> <out.png>
zig build golden       # golden-render conformance harness
zig-out/bin/banksia synth demo.dng   # write a synthetic demo DNG
```
