# Phase 0 — emu bootstrap: decode, minimal pipeline, golden harness

> **Objective:** A CLI that renders a real DNG to a PNG through a linear-f32
> pipeline, scored against reference renders in CI. This phase produces the
> *speedometer* and the engine skeleton every later phase leans on.
>
> **Definition of done:** `zig build render -- shot.dng recipe.json out.png`
> works; `zig build golden` compares the corpus against committed baselines
> and CI fails on regression.

**Status: complete** (with recorded deviations). Scoreboard at close:
`zig build test` 15/15 (unit + tidy), `zig build golden` 10 pass / 0 fail,
CLI end-to-end verified (`synth` → `render` → valid 512x384 PNG).

## 1. Skeleton

- [x] `build.zig` + `build.zig.zon`: steps `render`, `test`, `test-unit`,
      `test-tidy`, `golden`; `emu/`, `wombat/`, `lyrebird/` module dirs with
      the latter two as stubs pinning layout and test wiring.
- [x] `src/tidy.zig` from day one: bans with named replacements (std drift
      inherited from bottlebrush, `std.Random` banned for determinism,
      `std.debug.print` banned inside emu), reminders (`FIXME`, `TODO(now)`)
      rejected on main, 100-column ratchet starting at zero debt.
- [x] CI on macOS: build, tests, golden.

## 2. Decode

- [x] `emu/dng.zig`: `decode(blob) → SensorData` — Bayer plane, 2x2 CFA
      pattern, black/white levels, as-shot neutral. Bounded worklist walk
      of IFD0/SubIFD chain (no recursion, `ifd_visit_max = 8`), both byte
      orders, multi-strip, uncompressed 16-bit CFA only.
- [x] Untrusted input returns `error.Corrupt` / `error.Unsupported`, never
      asserts; the decoder's postconditions are the trust boundary and are
      asserted once, on exit.
- [x] `emu/dng_write.zig`: synthetic little-endian DNG writer for fixtures.
      Write/decode roundtrip is the format's pair assertion; a truncation
      test covers the negative space.
- [ ] libraw fallback backend — **deferred**: not installable in the dev
      environment, and the native decoder landed first, which inverts the
      bilby strategy: libraw is now an optional *validation oracle* to add
      when packaging allows, not the day-one path. Revisit in Phase 6.
- [ ] Lossless-JPEG (LJ92) DNG — **deferred to Phase 6** with the native
      camera decoders; uncompressed DNG (Adobe converter output) covers
      Phase 1–5 development.

## 3. Pipeline

- [x] `emu/image.zig`: planar f32 `Planes` (SoA — one packed array per
      channel), `edge_px_max = 65535` bound asserted at comptime.
- [x] `emu/pipeline.zig`: `Op` tagged union in a `std.MultiArrayList`;
      engine-v1 stack validation scans only the tag column (black_point
      first, one demosaic, srgb_encode last, bayer-domain ops before
      demosaic, rgb-domain after). Arena per render; the returned RGBA8 is
      the only allocation that outlives the call.
- [x] Kernels as standalone functions over primitive slices: black+scale
      (u16→f32 `@Vector`), per-site WB (pattern vector per row), exposure
      gain, smoothstep-blend tone curve (polynomial only — no
      transcendentals in loops), exact sRGB encode at pack time.
- [x] Bilinear demosaic comptime-monomorphized for RGGB/BGGR/GRBG/GBRG;
      clamp-to-edge borders.
- [x] Determinism test: two renders, byte-identical. *(Thread-count/tile
      invariance becomes testable when the thread pool lands — Phase 2.)*
- [x] Flat-field test: a constant grey mosaic renders as constant grey
      (demosaic must not invent structure), value checked against the
      sRGB transfer exactly.

## 4. Recipes and output

- [x] `emu/recipe.zig`: strict `std.json` parse (unknown fields rejected —
      canonical means canonical); hand-written canonical serializer
      (declaration-order fields, `{d}` floats, no whitespace); snapshot
      test on the exact byte form; parse→serialize roundtrip pair test.
      `engine_version` in every recipe from the first commit.
- [x] `emu/png.zig`: zero-dependency PNG (RGBA8, filter 0, stored-deflate
      zlib, std.hash CRC32/Adler32); test reconstructs pixels back out of
      the container.
- [x] `src/main.zig`: `render` + `synth` subcommands; CLI owns all I/O so
      emu stays pure.

## 5. Golden harness

- [x] `golden/runner.zig`: 10 cases — 5 synthetic scenes (gradient,
      patches, noise, checker, highlight; odd dimensions to hit demosaic
      borders and kernel scalar tails; one BGGR scene to hit a second
      demosaic instantiation) × 2 recipes (neutral, pushed). Scenes are
      pure functions of coordinates (SplitMix64 for noise) — no stored
      fixtures. Every case runs container write → decode → render, so the
      decoder is exercised by every golden run.
- [x] SHA-256 per case vs `golden/baseline.json`; stale-baseline detection;
      `--update` blesses and prints; CI fails on any drift.
- [ ] Perceptual oracle (dcraw/darktable-cli references, ΔE/SSIM threshold)
      — **deferred until a real-camera corpus is vendored**; byte-exactness
      is the ratchet until then.

## Exit criteria

- [x] `banksia render <dng> <recipe.json> <out.png>` produces a valid PNG.
- [x] `zig build golden` green in CI; any output drift fails the build.
- [x] Renders deterministic (byte-identical), held by a test.
- [x] Zero leaks under the debug allocator across CLI and golden runs.

## Learnings

- **`std.MultiArrayList` over a tagged union** splits into `items(.tags)`
  and a *bare* (untagged) payload union — `items(.data)[i]` cannot be
  passed where the full union is expected; `list.get(i)` reconstructs it.
  Tag-column scans for validation work exactly as hoped.
- **The pair assertion paid for itself on day one.** The first CFA
  validation rejected RGGB: it asserted the greens must *not* be at
  positions 1,2 — but that's exactly where RGGB puts them. The
  write/decode roundtrip test caught it immediately. Correct invariant:
  no row or column of the 2x2 repeats a colour.
- **The debug allocator is a free leak gate**: `init.gpa` in Debug builds
  reports leaks at exit; it caught the golden runner leaking its case
  names. Keep golden/CLI runs in Debug in CI for exactly this.
- **`std.json` earns its keep for recipes**: strict-by-default unknown-field
  rejection gives canonical-input enforcement for free, and tagged unions
  parse naturally from `{"tag": payload}`. Serialization stays hand-written
  — the canonical byte form is a contract, not an implementation detail.
- **Zig 0.16 idioms** (recorded for anyone touching the tree):
  `pub fn main(init: std.process.Init)`, explicit `std.Io` handles threaded
  through I/O calls, `std.ArrayList` unmanaged by default, and
  `build.zig.zon` requires a `.fingerprint` (the compile error tells you
  the value to paste).
- **Environment**: Zig installs cleanly from PyPI (`uv`/pip package
  `ziglang`) when direct downloads are blocked — useful for CI-less
  sandboxes.
- **Odd image dimensions in the corpus are load-bearing**: they exercise
  the `@Vector` kernels' scalar tails and the demosaic border clamps that
  even-sized test images never touch.
