# Phase 6 — performance + the export engine

> **Objective:** Speed where it's felt: GPU processing, native decoders
> for the big three, and Capture One-style process recipes for batch
> export.
>
> **Definition of done:** Slider-drag re-render at preview resolution
> under 16ms on Apple Silicon for the common op subset; a 500-photo shoot
> exports to two simultaneous output recipes saturating all cores; top-3
> native decoders pass the golden corpus without libraw.

**Status: not started.** Requires Phases 3 (cache) and 5 (the ops worth
accelerating). Napkin math first, per the skill: a 24MP frame is ~288MB
as three f32 planes — count full-image traversals before optimizing
anything.

## 1. The tiled fusion planner (CPU, before any GPU)

- [ ] Pipeline planner fuses adjacent per-pixel ops into one pass per
      tile (exposure + tone curve + colour editor are all pointwise);
      convolution ops (clarity, denoise, demosaic) set tile overlap; the
      planner computes overlap once.
- [ ] Thread pool over tiles (`std.Thread.Pool`); determinism contract
      extends: **output is bit-identical across thread counts and tile
      sizes** — the Phase 0 test finally gets its full form; goldens
      unchanged.
- [ ] Measure and record: full-image traversal count before/after fusion
      for the default stack (target: demosaic pass + one fused pointwise
      pass + encode).

## 2. Metal compute path

- [ ] The CPU path is the reference; the GPU path is an optimization of
      it, tested against it within the golden threshold (byte-exactness
      is not promised across CPU/GPU — perceptual threshold + a documented
      determinism boundary: GPU renders are deterministic per-device).
- [ ] Pointwise fused kernel + demosaic in Metal first (the two biggest
      traversals); f16 intermediates where ΔE shows no cost.
- [ ] Preview path stays on GPU end to end (texture out, no readback for
      display); export path reads back.
- [ ] `bk_render` gains a backend hint (auto/cpu/gpu); auto = GPU when
      available, CPU otherwise — same recipe, same cache keys.

## 3. Process recipes (batch export)

- [ ] Named output configurations: format (PNG now, JPEG when a zero-dep
      encoder lands or is vendored deliberately), long-edge size, colour
      space, output sharpening amount. Canonical JSON, content-addressed,
      like everything.
- [ ] `banksia export --recipe web --recipe print <selection>`: one
      develop render per photo fans out to N outputs; shared op-stack
      prefixes come from the render cache.
- [ ] Parallel queue: per-photo across the pool; progress + summary;
      cancellation safe (wombat's write discipline means a killed export
      never leaves a torn file).

## 4. Native decoders (the libraw fallback closes)

- [ ] Lossless-JPEG (LJ92) if it didn't land in Phase 5 — it unblocks
      real-world DNG breadth.
- [ ] CR3 (ISO BMFF container), NEF, ARW — one at a time, each validated
      against libraw output on the corpus (libraw becomes a *test oracle
      dependency only*, resolving Phase 0's deferred item), then against
      committed baselines so libraw isn't needed in CI.
- [ ] Fuzz each container parser (seeded, swarm over field mutations);
      untrusted-input discipline as in Phase 0: errors, never asserts.

## 5. At-scale profiling

- [ ] 500k-asset synthetic catalog: import throughput, filter latency,
      WAL replay time; fix what the profile shows, record before/after.
- [ ] Cache warming: background full-res render after preview lands
      (priority queue, drop-on-supersede).

## Tests

- Thread/tile determinism property (the contract test, now meaningful).
- GPU-vs-CPU golden threshold suite per kernel.
- Export: N-output fan-out correctness (each output matches a direct
  render at that config); kill-mid-export leaves no partial files
  (crash-sim reuse).
- Decoder fuzz corpora + libraw-oracle comparison harness.
- Bench gates: preview re-render ms, export throughput photos/min —
  recorded in baselines, regression fails.

## Exit criteria

- [ ] < 16ms preview re-render for the fused pointwise stack on Apple
      Silicon (record: ___ ms on ___).
- [ ] 500-photo, 2-recipe export saturates cores; photos/min recorded.
- [ ] CR3 + NEF + ARW corpus green without libraw at runtime.

## Learnings

*(recorded as the phase runs)*
