# Phase 2C CPU/Metal conformance evidence

Recorded 2026-07-13 on the Phase 2C reference MacBook Air M3, macOS
26.5.1. The repeatable gate is:

```sh
zig build test-metal
```

The test builds the compiled Metal library, runs the complete Swift suite, and
compares the strict CPU and one-pass Metal previews for every mandatory Phase
2B DNG at edge 512, exposure +0.5 EV, and contrast 0.35. Each image contributes
roughly 175,000 pixels; no sampling is used.

| Image | Mean ΔE00 | Median | p95 | Maximum | SSIM | Finite |
|---|---:|---:|---:|---:|---:|---|
| 1D X II backlight action | 0.0908 | 0.0000 | 0.4421 | 30.1687 | 0.9999686 | yes |
| 1D X II daylight detail | 0.0638 | 0.0000 | 0.5089 | 27.5691 | 0.9999905 | yes |
| 1D X II high contrast | 0.1109 | 0.0000 | 0.6591 | 40.8164 | 0.9999698 | yes |
| 1D X II ISO 12800 | 0.0726 | 0.0000 | 0.4692 | 22.9042 | 0.9999926 | yes |
| 1D X II skin ISO 1000 | 0.0819 | 0.0000 | 0.6490 | 8.6751 | 0.9999975 | yes |
| 1D X II warm backlight | 0.1678 | 0.0000 | 0.7603 | 38.1917 | 0.9999493 | yes |
| R3 black fabric | 0.0391 | 0.0000 | 0.3977 | 19.1648 | 0.9999946 | yes |
| R3 emerald fabric | 0.0404 | 0.0000 | 0.4118 | 24.8983 | 0.9999966 | yes |

All images pass the mean ΔE00 ≤ 0.5 gate and have SSIM ≥ 0.9999493. The
non-zero maxima are retained deliberately. They are sparse pixels at nonlinear
edges where the historical CPU renderer applies tone before preview reduction
and the retained-preview graph applies late tone after reduction. The neutral
median and low p95 show that this is not a broad colour transform error, but the
maximum-difference exit criterion remains open until this ordering difference
is either unified or explicitly accepted as the preview contract.

## Adversarial and precision evidence

The compiled shader is also compared with a direct f32 CPU reference on odd
17×13 images containing negative values, values above one, saturated channels,
deep-shadow gradients, and explicit borders. It stays finite and passes mean
ΔE00 ≤ 0.20, p95 ≤ 0.60, maximum ≤ 1.0, and SSIM ≥ 0.9999.

An RGBA16F source-texture candidate is evaluated against RGBA32F on 1,285
gradient/adversarial pixels:

| Comparison | Mean ΔE00 | Median | p95 | Maximum | SSIM | Finite |
|---|---:|---:|---:|---:|---:|---|
| RGBA16F vs RGBA32F | 0.0002 | 0.0000 | 0.0000 | 0.2507 | 1.0000000 | yes |

This is sufficient evidence to retain float16 as a viable future memory
optimization, but RGBA32F remains the default until a measured viewer-memory or
bandwidth benefit justifies changing the precision manifest.

## Failure, lifecycle, and validation coverage

- Stable backend/output identities keep strict display, strict linear, and
  Metal artifacts in separate cache keys.
- A two-frame admission model survives a 10,000-request burst, admits at most
  two frames, and retains only generation 10,000 for retry.
- Older Metal generations cannot publish timing or state after a newer request.
- A 64-frame odd-dimension resize/scaling loop covers both sampling policies
  without a timeout, command failure, or deadlock.
- Typed injection covers initialization, allocation, shader, command-buffer,
  drawable, and completion failures; every stage selects the strict CPU
  execution contract. The normal environment remains GPU-first.
- The complete suite passes with `MTL_DEBUG_LAYER=1`,
  `MTL_SHADER_VALIDATION=1`, and
  `MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1`, with no API or shader validation
  errors.

## Sustained trace

A release build ran a 2,500-request late-develop sweep under the Metal System
Trace template for 121.310 seconds. Instruments ended the process at the
two-minute limit as configured and produced a valid local 1.1 GB trace whose
TOC includes Metal command-buffer, GPU-state, display, hang-risk, and device
thermal-state streams. The local trace was removed after inspection because it
is not a repository artifact.

The macOS `Power Profiler` template is unavailable (Xcode reports it as
iOS/iPadOS-only), and `powermetrics` requires administrator authentication.
Consequently sustained Metal execution is proven, but numerical package-power
and temperature counters remain an explicit privileged follow-up rather than a
fabricated result.

## Presentation latency still open

The final synchronized, framebuffer-only, two-drawable release run recorded
47.557 ms p50, 47.758 ms p95, and 66.254 ms p99 input-to-presented. Shader work
was 1.496 ms p50; presentation wait was 38.315 ms p50. Three drawables did not
improve p95. Disabling display synchronization reduced the median but worsened
p95 to 62.840 ms and was rejected. The correct synchronized contract therefore
remains in place, while the 33 ms compiled-MSL presentation gate remains open.
