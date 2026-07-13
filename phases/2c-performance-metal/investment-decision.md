# Phase 2C investment decision

Recorded 2026-07-13 on the reference 8 GB MacBook Air M3 running macOS
26.5.1. Phase 2C is complete as an architecture and product decision: keep the
GPU-resident viewer as Banksia's normal path, retain strict CPU as the oracle
and failure path, and move further presentation-latency work to Branch C.

## Compared paths

| Path | Relevant p95 | Result |
|---|---:|---|
| Optimized strict CPU core, CR2/CR3 edge 1024 | 35.547 / 98.225 ms | This excludes buffer copy, `CGImage` construction, and presentation, so it is a lower bound for CPU-to-visible. |
| Strict CPU-to-`CGImage` | Above the CPU-core lower bound | Correct fallback and oracle; every late edit repeats the CPU render and image construction. |
| Hybrid Core Image on Metal | 47.589 ms input-to-visible | Re-tested for this decision. It no longer reproduces the early ~31 ms runs and exposes no useful command-buffer GPU duration (`0.000 ms`). |
| Direct compiled MSL, GPU-resident | 47.758 ms input-to-visible | Statistically tied with the hybrid path; selected because its one-pass work, GPU duration, shader identity, precision, and conformance are explicit. |

The direct MSL path does **not** meet the original 33 ms p95 gate and has not
shown a 2× p95 win over every CPU case. It remains the default by an explicit
project decision, not by claiming those gates passed: it avoids routine
GPU-to-CPU readback, isolates cached edits from RAW reprocessing, keeps the
viewer architecture aligned with future GPU work, and already has complete
failure fallback. This deviation is visible in the phase exit checklist.

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

The measured bottleneck is drawable scheduling/presentation, not the late-image
kernel. Branch C should test a different presentation driver and frame-pacing
contract before adding image kernels. GPU demosaic, detail, export, f16 adoption,
heaps, untracked hazards, extra queues, and tile shaders remain parked until a
separate workload profile identifies them as dominant.
