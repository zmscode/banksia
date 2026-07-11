# banksia

[![CI](https://github.com/zmscode/banksia/actions/workflows/ci.yml/badge.svg)](https://github.com/zmscode/banksia/actions/workflows/ci.yml)

A RAW photo editor in Zig: a headless, deterministic develop engine with
non-destructive edits, content-addressed storage, and git-like versioning,
driven by a golden-render conformance harness from day one. CI runs on
macOS — the platform the shell, the C ABI, and eventually Metal target.

See [plan.md](plan.md) for the architecture and roadmap, and
[phases/](phases/) for granular phase plans, exit criteria, and close-outs.

## Status: Phase 2A — storage baseline complete

The develop engine (**emu**) decodes DNG, runs a deterministic linear
scene-referred pipeline, and renders PNGs from the CLI. The golden harness
holds 20 synthetic cases byte-stable in CI.

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

## Commands

```sh
zig build              # build the CLI
zig build test         # unit tests + tidy lint
zig build render -- <raw.dng> <recipe.json> <out.png>
zig build golden       # 20-case golden-render conformance harness
zig build bench        # ReleaseFast catalog/storage latency gates
zig build sim          # 10k seeded vault/catalog crash workloads
zig-out/bin/banksia synth demo.dng   # write a synthetic demo DNG
```
