# banksia

[![CI](https://github.com/zmscode/banksia/actions/workflows/ci.yml/badge.svg)](https://github.com/zmscode/banksia/actions/workflows/ci.yml)

A RAW photo editor in Zig: a headless, deterministic develop engine with
non-destructive edits, content-addressed storage, and git-like versioning,
driven by a golden-render conformance harness from day one. CI runs on
macOS — the platform the shell, the C ABI, and eventually Metal target.

See [plan.md](plan.md) for the architecture and roadmap, and
[phases/](phases/) for granular phase plans, exit criteria, and close-outs.

## Status: Phase 2B — real-camera correctness

The develop engine (**emu**) decodes DNG natively and CR2/CR3 through LibRaw's
sensor-mosaic API, then runs Banksia's deterministic linear scene-referred
pipeline. Engine v2 now applies DNG active-area, default-crop, and all eight
TIFF orientations plus a linear-Rec.2020 neutral colour transform. The golden
harness holds 20 engine-v1 and 5 engine-v2 cases byte-stable.

The storage layer (**wombat**) now provides a content-addressed vault and a
columnar snapshot-plus-WAL catalog. Mutation acknowledgement, compaction, and
directory durability are exercised through a deterministic crash simulator;
the Phase 2A close-out records the 10,000-workload gate and storage latency
baselines.

The libraries, per the house naming scheme (Australian flora for projects,
fauna for the libraries inside):

- **emu** (`emu/`) — the develop engine: decode, colour, pipeline, render
  cache, thumbnails.
- **wombat** (`wombat/`) — storage: content-addressed blob vault, chunking,
  and the durable columnar catalog. Sessions follow in Phase 2C.
- **lyrebird** (`lyrebird/`) — similarity: perceptual hashing, burst
  grouping, sharpness scoring. *(Phase 4 — stub.)*

## Requirements

- Zig **0.16.0**
- LibRaw **0.22.x** (`brew install libraw` on macOS)

Banksia links the thread-safe `libraw_r` dynamically. Homebrew on Apple Silicon
is the default; use `-Dlibraw-prefix=/path` for another installation prefix.

## Commands

```sh
zig build              # build the CLI
zig build test         # unit tests + tidy lint
zig build render -- <raw.dng> <recipe.json> <out.png>
zig-out/bin/banksia inspect <raw> [--decode]  # metadata or full mosaic probe
zig build golden       # 25-case v1/v2 golden-render conformance harness
zig build bench        # ReleaseFast catalog/storage latency gates
zig build sim          # 10k seeded vault/catalog crash workloads
zig build corpus       # verify/decode optional local CR2/CR3 corpus
zig-out/bin/banksia synth demo.dng   # write a synthetic demo DNG
```
