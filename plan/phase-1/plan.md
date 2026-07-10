# Phase 1 — the C ABI and the SwiftUI inspection shell

> **Objective:** Move visual inspection from "render a PNG and `open` it"
> to live sliders. Prove the Zig↔Swift boundary before any storage work.
>
> **Definition of done:** A macOS app with EV/temp-ish/contrast sliders
> re-renders a loaded RAW live (sub-second at preview resolution); the C
> ABI surface is ≤ 8 functions, documented in `include/banksia.h`, and
> smoke-tested from C in CI.

**Status: in progress.**

## 1. Preview rendering (emu)

The shell needs `max_edge` before the ABI exists.

- [x] `emu/pipeline.zig`: `render` gains a `edge_px_max_out: u32` option
      (0 = full resolution). v1 implementation: render full-res, then box
      downsample — correct and deterministic first; the subsampled-demosaic
      fast path is a Phase 6 optimization with a golden test against this
      reference. *(carried as a `RenderOptions` struct so later options
      don't churn the signature; downsampling happens on the linear planes,
      before sRGB encode, so averaging is done in light)*
- [x] Downsample kernel: standalone, `@Vector`, integer box bins (no
      resampling filters yet); golden cases extended with one downsampled
      variant so the kernel is baselined. *(vertical accumulation is the
      vector loop; horizontal binning is scalar — bins vary in width. A
      `preview` variant at edge 24 baselines all 5 scenes: 10 → 15 golden
      cases, original 10 hashes unchanged)*
- [x] Determinism test covers the downsampled path.

## 2. The C ABI (`src/capi.zig` + `include/banksia.h`)

- [x] `Engine` handle: owns allocator, loaded `SensorData`, parsed recipe,
      last rendered buffer, and a fixed `last_error` message buffer. One
      handle = one thread; no internal locking (the Swift actor is the
      serialization point). *(debug builds give each engine its own
      `DebugAllocator` so destroy can audit every byte — that is the leak
      gate's mechanism)*
- [x] Surface (7 functions, `bk_` prefix, snake_case):
      `bk_engine_create`, `bk_engine_destroy`, `bk_load_raw(path)`,
      `bk_set_recipe_json(json)`, `bk_render(edge_px_max, *w, *h) → ?[*]u8`,
      `bk_last_error() → [*:0]const u8`, `bk_version() → u32`.
- [x] Error convention: functions return `i32` codes (0 ok, negative
      errno-style set), message via `bk_last_error`; **no Zig error unions,
      no panics cross the boundary** — every `catch` sets last_error.
- [x] Buffer contract documented per function in the header: the engine
      owns returned pixels; valid until the next `bk_render` or destroy.
- [x] `include/banksia.h` hand-written; ABI change and header change land
      in the same commit. *(deviation: the sync assertion lives in a
      `capi.zig` unit test, not the C smoke test — Zig reads the header and
      counts `bk_*(` declarations against the reflected export list, which
      also catches unreferenced header declarations the C compiler would
      not)*
- [x] `zig build lib`: `b.addLibrary(.{ .linkage = .dynamic })` →
      `libbanksia.dylib` + header install step.

## 3. C smoke test (CI gate)

- [ ] `tests/abi_smoke.c`: create → synth a DNG via the CLI (or embed a
      tiny fixture) → load → set recipe → render preview and full →
      assert dims and non-null → error paths (missing file, garbage JSON,
      render before load each return codes and a message) → destroy.
- [ ] Built and run with `zig build test-abi` (compiles the C file against
      the dylib with `zig cc` — no Xcode needed); wired into CI on the
      macOS runner.
- [ ] Leak gate: the smoke test runs the engine under the debug allocator
      build and fails on leak report.

## 4. The SwiftUI shell (`macos/`)

- [ ] Xcode project (SwiftPM app target is acceptable if simpler):
      `CBanksia` module map over `banksia.h`, links the dylib via rpath.
- [ ] `RendererActor`: owns the engine handle; all `bk_*` calls funnel
      through it; renders on the actor, never the main thread.
- [ ] `DevelopModel` (@Observable): ev, contrast, wb gains; slider changes
      → rebuild recipe JSON (mirror of the canonical form) → debounced
      render.
- [ ] Preview-while-dragging: `edge_px_max = 1024` during drag, full-res
      render on release.
- [ ] Pixels: copy out of the engine buffer (`Data(bytes:count:)`) →
      `CGImage` → SwiftUI `Image`. Never alias the engine buffer.
- [ ] File open: `.fileImporter` for a `.dng`; `banksia synth` output is
      the day-one test file.
- [ ] `Makefile`: `make` = `zig build lib && xcodebuild -scheme Banksia
      build`; `make run` opens the app.

## 5. CI

- [ ] macOS job extends: `zig build lib`, `zig build test-abi`.
- [ ] `xcodebuild` app build in CI *if* the runner's Xcode is compatible;
      otherwise the smoke test is the gate and the app builds locally
      (record which in learnings).

## Tests

- ABI smoke (C, in CI) — the phase's hard gate.
- Downsample golden cases + determinism.
- Error-path table test in `capi.zig` unit tests (each failure sets a
  message and returns its code; success clears it).

## Exit criteria

- [ ] Sliders re-render a 24MP-class synthetic DNG in < 1s at preview
      resolution on Apple Silicon (measure and record the number here).
- [ ] ABI ≤ 8 functions, header documented, C smoke green in CI.
- [ ] Zero leaks across create/load/render/destroy cycles.

## Learnings

*(recorded as the phase runs)*
