# Phase 2C investment decision

Recorded 2026-07-13 on the reference 8 GB MacBook Air M3 running macOS
26.5.1. Phase 2C is complete as an architecture and product decision: keep the
GPU-resident viewer as Banksia's normal path, retain strict CPU as the oracle
and failure path, and move further presentation-latency work to Branch C.

## Compared paths

| Path | Relevant p95 | Result |
|---|---:|---|
| Optimized strict CPU core, CR2/CR3 edge 1024 | 45.915 / 43.719 ms | Final isolated ReleaseFast reference workload. |
| Strict CR2 CPU-to-`CGImage` late release | 138.492 ms | Correct exact-edge fallback and oracle; every late edit repeats CPU rendering and image construction. |
| Hybrid Core Image on Metal | 47.589 ms input-to-visible | Re-tested for this decision. It no longer reproduces the early ~31 ms runs and exposes no useful command-buffer GPU duration (`0.000 ms`). |
| Direct compiled MSL, GPU-resident | 47.694 ms input-to-visible | Passes the three-refresh-interval windowed contract and is 2.90× faster than the reference CR2 CPU-to-`CGImage` late release. |

The direct MSL path meets the final windowed contract: no more than three
display intervals p95 (50.0 ms on the 60 Hz reference display). The original
33 ms target remains the direct-display/high-refresh target because windowed
`CAMetalDisplayLink` supplies a two-frame target horizon before compositor time.
Direct MSL also avoids routine GPU-to-CPU readback, isolates cached edits from
RAW reprocessing, and retains complete strict-CPU failure fallback.

## Supported envelope and fallback

- Default: `banksia.metal.late-develop-f32.msl1`, RGBA32F linear Rec.2020
  source, one compiled MSL pass, synchronized opaque sRGB drawable, two
  drawables/in-flight frames maximum.
- Validated reference: Apple M3 integrated GPU, macOS 26.5.1, Metal API and
  shader validation enabled.
- CPU remains canonical for historical artifacts and conformance.
- Initialization, texture allocation, shader setup, command-buffer creation,
  drawable acquisition, and command completion failure switch the current file
  to strict CPU rendering. The integration test proves a visible CPU result for
  all six stages.
- No GPU artifact shares a cache identity with strict CPU output.

## Deferred to Branch C

The remaining latency is drawable scheduling/presentation, not the late-image
kernel. Branch C may pursue direct-to-display and higher-refresh presentation.
GPU demosaic, detail, export, f16 adoption, heaps, untracked hazards, extra
queues, and tile shaders remain parked until a separate workload profile
identifies them as dominant.
