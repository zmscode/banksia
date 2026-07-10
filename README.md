# banksia

A RAW photo editor in Zig: a headless, deterministic develop engine with
non-destructive edits, content-addressed storage, and git-like versioning,
driven by a golden-render conformance harness from day one.

See [plan.md](plan.md) for the architecture and the phased implementation
plan.

## Status: Phase 0 — emu bootstrap (in progress)

The develop engine (**emu**) decodes uncompressed DNG, runs a linear
scene-referred f32 pipeline (black point → white balance → bilinear demosaic
→ exposure → tone curve → sRGB), and renders to PNG from the CLI. The golden
harness scores rendered output against committed baselines in CI; the number
only goes up.

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
```
