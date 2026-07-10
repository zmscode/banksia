# Phase 4 — lyrebird + the culling workflow

> **Objective:** Perceptual similarity, sharpness scoring, and the first
> *product* surface: a keyboard-driven culling grid with burst stacks and
> a Capture One-style focus mask.
>
> **Definition of done:** Import a 1000-shot shoot; bursts are
> auto-grouped; the grid navigates/rates/rejects entirely from the
> keyboard at 60fps; the focus overlay separates sharp from soft frames
> without zooming; lyrebird's precision/recall on a labelled corpus is
> scored in CI.

**Status: not started.** Requires Phase 0 (previews) + Phase 2 (catalog);
does not require Phase 3.

## 1. Perceptual hashing (lyrebird core)

- [ ] Luma extraction from emu preview renders (edge 64 is plenty);
      dHash-64: 9x8 box-downsampled grid, horizontal gradient sign bits.
      Integer-only end to end — deterministic forever, like everything
      else in the engine.
- [ ] Hamming distance: start with SIMD linear scan over packed u64s
      (100k × 8 bytes = 800KB — likely faster than any tree; **measure
      before building a BK-tree**, record the number, only then decide).
- [ ] `pHash` (DCT) behind the same interface *only if* the labelled
      corpus shows dHash recall is insufficient (decide on data, not
      vibes; record the numbers either way).

## 2. Burst grouping

- [ ] Group = connected component under (perceptual distance ≤ D) AND
      (capture-time gap ≤ T seconds); union-find over the time-sorted
      asset column (bounded, no recursion).
- [ ] Writes `burst_group` catalog column; stable group ids (min asset
      handle in group).
- [ ] Tunables D and T are recipe-like data with defaults, not constants
      (they'll need per-camera tuning).

## 3. The labelled corpus + CI scoring (lyrebird's speedometer)

- [ ] Synthetic corpus generator: base scenes through emu with
      perturbations that *should* group (±0.3EV exposure shifts, small
      WB drift, noise reseed = same burst) and scenes that *should not*
      (different scene generators). Labels are by construction — no hand
      labelling needed to start.
- [ ] Precision/recall computed in CI; `lyrebird/baseline.json` records
      the blessed numbers; regression fails the build (the ratchet,
      again).
- [ ] A small hand-labelled real-photo set joins when a real corpus is
      vendored (same JSON format; keep the loader format-agnostic).

## 4. Focus mask / sharpness

- [ ] Per-tile (16x16 on the preview luma) Laplacian variance →
      normalized per-image sharpness score → `sharpness` f16 column
      (sortable: "show me the soft ones").
- [ ] Focus overlay: per-tile scores → heatmap alpha texture the shell
      draws over the image (data crosses the C ABI as a compact u8 grid).
- [ ] Scored against synthetic ground truth: same scene rendered sharp
      vs gaussian-blurred — blurred must rank strictly softer at every
      blur radius (property test).

## 5. Culling UI (growing the shell into a product)

- [ ] Virtualized thumbnail grid: shell requests pages of (thumb, rating,
      flags, group) through the C ABI; thumbnails come from the Phase 2
      cache. Target 60fps scroll on a 10k-asset session.
- [ ] Keyboard: J/K or arrows navigate, 1–5 rate, X reject, F focus
      overlay, up/down within a burst stack, space toggles stack collapse
      (stack shows the pick — highest rating, then sharpest).
- [ ] Every action is a catalog WAL record (Phase 2), so undo is free
      when Phase 3's history lands on top.
- [ ] `banksia dedupe`: near-duplicate report across the library (CLI
      table: groups, sizes, byte savings if archived).

## Tests

- dHash: known-vector tests; invariance (same bytes = same hash) and
  sensitivity (inverted image ≠ same hash) properties.
- Grouping: property tests on synthetic corpora (transitivity of the
  component build; time-window boundaries exact).
- Precision/recall CI gate against `lyrebird/baseline.json`.
- Sharpness monotonicity vs blur radius (property, seeded).
- Grid paging: unit tests on the pagination ABI; scroll perf measured in
  the shell and recorded here.

## Exit criteria

- [ ] 1000-shot synthetic shoot: import + hash + group in < 30s cold
      (record: ___); bursts grouped with P/R ≥ blessed baseline.
- [ ] Grid at 60fps on a 10k-asset session (record measured fps: ___).
- [ ] Sharpness column separates blurred from sharp at 100% in the
      synthetic set; overlay renders in the shell.

## Learnings

*(recorded as the phase runs)*
