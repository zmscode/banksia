# Phase 1 — the C ABI and the SwiftUI inspection shell

> **Objective:** Move visual inspection from "render a PNG and `open` it"
> to live sliders. Prove the Zig↔Swift boundary before any storage work.
>
> **Definition of done:** A macOS app with EV/temp-ish/contrast sliders
> re-renders a loaded RAW live (sub-second at preview resolution); the C
> ABI surface is ≤ 8 functions, documented in `include/banksia.h`, and
> smoke-tested from C in CI.

**Status: complete.** Preview at `edge_px_max = 1024` on a 24MP-class
synth DNG: 116 ms warm (ReleaseFast, Apple Silicon); ABI is 7 functions,
smoke-tested from C with the leak gate in CI.

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

- [x] `tests/abi_smoke.c`: create → synth a DNG via the CLI (or embed a
      tiny fixture) → load → set recipe → render preview and full →
      assert dims and non-null → error paths (missing file, garbage JSON,
      render before load each return codes and a message) → destroy.
      *(the fixture is `banksia synth` output routed through the build
      graph — `addOutputFileArg`, no committed blob; the binary also prints
      render timings, which is how the exit-criteria number is measured)*
- [x] Built and run with `zig build test-abi` (compiles the C file against
      the dylib inside the zig build graph — no Xcode needed); wired into
      CI on the macOS runner. `zig build test` includes it.
- [x] Leak gate: the smoke test runs the engine under the debug allocator
      build and fails on leak report. *(mechanism: in debug builds each
      engine owns a `DebugAllocator` and `bk_engine_destroy` asserts a
      clean report, so the default-optimize CI run of test-abi aborts on
      any leak)*

## 4. The SwiftUI shell (`macos/`)

- [x] Xcode project (SwiftPM app target is acceptable if simpler):
      `CBanksia` module map over `banksia.h`, links the dylib via rpath.
      *(SwiftPM: `macos/Package.swift` with a systemLibrary target whose
      module map points at `include/banksia.h`; `Context.packageDirectory`
      derives absolute -L and rpath to `zig-out/lib`, so the debug binary
      runs from anywhere with no dylib copying)*
- [x] `RendererActor`: owns the engine handle; all `bk_*` calls funnel
      through it; renders on the actor, never the main thread. *(named
      `Renderer` in `macos/Sources/Banksia/Renderer.swift`)*
- [x] `DevelopModel` (@Observable): ev, contrast, wb gains; slider changes
      → rebuild recipe JSON (mirror of the canonical form) → debounced
      render. *(temperature/tint ride a second `white_balance` op stacked
      on the as-shot one — gains compose multiplicatively, so zeroed
      sliders keep the camera's neutral)*
- [x] Preview-while-dragging: `edge_px_max = 1024` during drag, full-res
      render on release.
- [x] Pixels: copy out of the engine buffer (`Data(bytes:count:)`) →
      `CGImage` → SwiftUI `Image`. Never alias the engine buffer.
- [x] File open: `.fileImporter` for a `.dng`; `banksia synth` output is
      the day-one test file. *(plus `Banksia <shot.dng>` opens straight
      from argv for the dev loop)*
- [x] `Makefile`: ~~`make` = `zig build lib && xcodebuild`~~ *(deviation:
      no Makefile — tooling stays in Zig. `zig build shell` builds the
      dylib, installs the header, and drives `swift build`; `zig build
      run-shell` launches the app. The ordering is a build-graph edge, not
      a shell line)*

## 5. CI

- [x] macOS job extends: `zig build lib`, `zig build test-abi`.
- [x] `xcodebuild` app build in CI *if* the runner's Xcode is compatible;
      otherwise the smoke test is the gate and the app builds locally
      (record which in learnings). *(`zig build shell` drives `swift
      build`, which the runner's Xcode provides — no xcodeproj exists to
      xcodebuild. Verified locally on Swift 6.3/Xcode 26; if the runner's
      toolchain balks, drop the shell step and the smoke test remains the
      gate)*

## Tests

- ABI smoke (C, in CI) — the phase's hard gate.
- Downsample golden cases + determinism.
- Error-path table test in `capi.zig` unit tests (each failure sets a
  message and returns its code; success clears it).
- Header-sync test: reflected `bk_*` exports counted against
  `include/banksia.h` declarations.

## Exit criteria

- [x] Sliders re-render a 24MP-class synthetic DNG in < 1s at preview
      resolution on Apple Silicon (measure and record the number here).
      **Measured: 6000×4000 synth DNG, ReleaseFast dylib, Apple Silicon —
      preview (`edge_px_max = 1024`) 116 ms warm / 283 ms first call;
      full-res 424 ms** (`abi_smoke` timings, 2026-07-11).
- [x] ABI ≤ 8 functions, header documented, C smoke green in CI.
      **7 functions.**
- [x] Zero leaks across create/load/render/destroy cycles. *(debug builds
      run each engine on its own `DebugAllocator`; destroy asserts a clean
      report and `test-abi` runs two full engine lifecycles under it)*

## Learnings

- **stderr is a signal, not a console.** `zig build`'s run steps echo any
  command that writes to stderr as "failed command" even on success; the
  CLI's status prints moved to stdout and stderr is reserved for failures.
- **`Context.packageDirectory` solves the dylib path problem.** The
  SwiftPM manifest derives absolute `-L` and rpath to `zig-out/lib`, so
  the debug binary runs from anywhere with no copying and no
  `DYLD_LIBRARY_PATH`; the `CBanksia` module map references
  `../../../include/banksia.h` directly, so the header exists in exactly
  one place.
- **Temp/tint without widening the ABI:** engine v1 already allows
  multiple `white_balance` ops before demosaic, and gains compose
  multiplicatively — the shell stacks the user's gains on the as-shot op
  instead of needing a "read the camera neutral" ABI function.
- **Sync tests beat discipline:** the header/export lockstep is a
  reflection test (`pub export` decls vs `bk_*(` declarations in the
  header), so an ABI drift fails `zig build test` before review sees it.
- The dylib is built for the host macOS version while the app targets
  macOS 14+, which ld warns about (harmless); pinning a `-Dtarget`
  baseline is worth doing when distribution matters.
- `has_side_effects = true` is required on the `swift build` step — SwiftPM
  owns its own caching and the zig build graph must not skip it.
