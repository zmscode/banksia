# Phase 2C seed CPU baseline

Recorded 2026-07-12 as the starting point for measurement work. This is a
nine-sample smoke baseline, not the acceptance report: with nine samples the
nearest-rank p95 and p99 are both the observed maximum. Longer runs, peak-memory
capture, thermals, UI presentation latency, edge-1440, and interaction-specific
workloads remain part of 2C.1.

## Reference environment

- MacBook Air (Mac15,12), Apple M3: 4 performance + 4 efficiency CPU cores,
  8-core GPU, 8 GB unified memory.
- macOS 26.5.1, Darwin 25.5.0.
- Metal 4-capable integrated GPU.
- Core benchmark built ReleaseFast; Swift inspection shell built Debug.
- Corpus revision: repository working tree at the start of Phase 2C; CR2 and
  CR3 files under `assets/`.
- RAW files are read before timed work. Render measurements are warm and use a
  decoded sensor image retained in memory.

## Repeatable command

```sh
zig build raw-bench -- --iterations 9 \
  assets/CR2/AM4I0028.CR2 \
  'assets/CR3/S1-NU26643BlackStrip-25992-Nude Lucy-0101.CR3'
```

## Seed results

| File | Stage | p50 | p95 | p99 |
|---|---|---:|---:|---:|
| CR2 `AM4I0028` | metadata parse | 236.241 ms | 254.454 ms | 254.454 ms |
|  | sensor decode | 239.129 ms | 241.362 ms | 241.362 ms |
|  | warm edge-1024 render | 43.078 ms | 80.200 ms | 80.200 ms |
|  | warm full render | 608.046 ms | 968.063 ms | 968.063 ms |
| CR3 `S1…0101` | metadata parse | 61.594 ms | 83.185 ms | 83.185 ms |
|  | sensor decode | 62.942 ms | 114.106 ms | 114.106 ms |
|  | warm edge-1024 render | 53.846 ms | 72.856 ms | 72.856 ms |
|  | warm full render | 990.637 ms | 1,358.422 ms | 1,358.422 ms |

## Instrumentation now available

The macOS shell records wall-clock render-loop-to-published-image time and
exposes separate RAW load/decode, core render, engine-buffer copy, and
`CGImage` construction timings. Those stages also emit points-of-interest
signposts for Instruments. Recipe update is signposted and retained in the
structured render timing even though it is not shown in the compact Info panel.

The GPU-only shell now also records texture upload, CPU command encoding, queue
delay, GPU execution, drawable presentation wait, and input-to-presented time.
Still missing: engine output packing as its own interval, histogram and overlay
work, peak memory, CPU-copy counts, and sustained thermal measurement.

## Retained-linear boundary smoke result

After adding the split-stage engine boundary, a three-sample ReleaseFast smoke
run measured the new RGBA32F linear-Rec.2020 base at edge 1440. These are not
acceptance percentiles; with three samples p95 and p99 select the maximum.

| File | Stage | p50 | p95/p99 |
|---|---|---:|---:|
| CR2 `AM4I0028` | warm edge-1440 linear base | 75.872 ms | 78.233 ms |
| CR3 `S1…0101` | warm edge-1440 linear base | 30.484 ms | 31.052 ms |

The benchmark now reports this stage alongside metadata, decode, display render,
and full render. It excludes the Swift-owned copy, texture upload, late-develop
GPU pass, and presentation; those remain separate measurements.

## GPU-only cached late-edit baseline

Recorded 2026-07-13 on the reference MacBook Air M3, macOS 26.5.1, with the
Swift inspection shell built Debug. The source was `assets/CR2/AM4I0043.CR2`;
RAW decode and the edge-1440 RGBA32F linear-Rec.2020 texture were warm before
each 31-frame exposure sweep. The benchmark changes exposure only, retains the
same texture, waits for every drawable's presented callback, and uses
nearest-rank percentiles. No GPU-to-CPU readback occurs.

Repeatable command:

```sh
BANKSIA_METAL_BENCHMARK=1 \
BANKSIA_OPEN="$PWD/assets/CR2/AM4I0043.CR2" \
./macos/.build/arm64-apple-macosx/debug/Banksia
```

| Run | Visible p50 | Visible p95 | Visible p99 | Encode p50 | Queue p50 | GPU p50 | Present wait p50 |
|---|---:|---:|---:|---:|---:|---:|---:|
| clean 1 | 31.164 ms | 31.505 ms | 43.090 ms | 0.196 ms | 1.602 ms | 0.730 ms | 24.394 ms |
| clean 2 | 30.626 ms | 30.836 ms | 49.838 ms | 0.217 ms | 0.116 ms | 0.348 ms | 25.701 ms |
| API validation | 31.288 ms | 47.358 ms | 47.459 ms | 0.246 ms | 0.121 ms | 2.746 ms | 24.205 ms |

Both clean runs pass the 33 ms p95 late-adjustment gate. Metal API validation
remains a correctness run rather than a performance run because its overhead
materially changes the tail.

A `displaySyncEnabled = false` experiment was rejected. Although it reduced one
run's median to 19.818 ms, p95 rose to 67.200 ms and p99 to 112.910 ms. The
viewer therefore keeps synchronized presentation and the two-drawable limit.

## Compiled-MSL transition check

Recorded 2026-07-13 after replacing the Core Image late-develop graph with the
build-time compiled `banksia.metal.late-develop-f32.msl1` fullscreen pipeline.
These Debug runs used the same 31-frame CR2 exposure sweep and prove the new path
is measured honestly; they are not yet an accepted 2C.5 performance result.

| Run | Visible p50 | Visible p95 | Visible p99 | Encode p50 | Queue p50 | GPU p50 | Present wait p50 |
|---|---:|---:|---:|---:|---:|---:|---:|
| compiled MSL 1 | 30.2 ms | 52.5 ms | 66.0 ms | 0.1 ms | 0.2 ms | 1.1 ms | 25.0 ms |
| compiled MSL 2 | 47.5 ms | 52.3 ms | 70.2 ms | 0.0 ms | 1.9 ms | 1.4 ms | 30.4 ms |

The shader itself remains inexpensive, but both runs miss the 33 ms p95
input-to-visible gate because drawable/presentation scheduling dominates the
tail. Phase 2C.4 is complete as an architecture and failure-handling proof; the
compiled path must regain the latency gate during 2C.5 before the Metal
investment decision can pass.

## 2C.5 fused-path closure measurements

Recorded 2026-07-13 after enabling framebuffer-only opaque drawables, wiring
nearest/linear shader sampling, and adding full conformance/failure coverage.
The release build remained presentation-bound:

| Mode | Visible p50 | p95 | p99 | Queue p50 | GPU p50 | Present p50 |
|---|---:|---:|---:|---:|---:|---:|
| synchronized, two drawables | 47.557 ms | 47.758 ms | 66.254 ms | 2.655 ms | 1.496 ms | 38.315 ms |
| unsynchronized experiment | 30.569 ms | 62.840 ms | 85.575 ms | 0.214 ms | 0.673 ms | 21.973 ms |

Three synchronized drawables also missed at 47.675 ms p95. The unsynchronized
mode improves its median while materially worsening its tail, so it remains
rejected. The final path keeps two synchronized drawables. The compiled shader,
corpus parity, precision, and sustained trace evidence are complete; a different
presentation driver or an explicit product-gate decision is needed to close the
33 ms p95 requirement. See [the conformance report](conformance.md).

## 2C.7 hybrid re-check

The Metal-backed Core Image hybrid was restored temporarily and re-run through
the same 31-frame synchronized CR2 sweep. It recorded 47.132 ms p50,
47.589 ms p95, and 54.665 ms p99. That is statistically tied with the direct
MSL result, not the ~31 ms observed earlier in the phase. It also reported no
usable command-buffer GPU duration. The direct compiled path therefore remains
the normal viewer because its work and timing are explicit. See
[the investment decision](investment-decision.md).

Fresh 31-run ReleaseFast post-decode measurements closed the edge-1440 preview
gate: CR2 recorded 88.936/89.989/91.697 ms p50/p95/p99 and CR3 recorded
40.582/55.703/64.663 ms. Both are below 100 ms p95.

## 2C.1 complete workload matrix

Recorded 2026-07-13 after extending `raw-bench` with explicit thumbnail,
edge-1440 display, CPU late-release, output-packing, and linear-admission
measurements. The command is intentionally ReleaseFast and runs each named
workload 31 times with decoded RAW retained in memory. Metadata/decode is
repeated from the source bytes; filesystem cache state is therefore **warm**
and recorded rather than implied to be cold.

```sh
zig build raw-bench -- --iterations 31 \
  assets/CR2/AM4I0028.CR2 \
  'assets/CR3/S1-NU26643BlackStrip-25992-Nude Lucy-0101.CR3'
```

| Workload | CR2 p50 / p95 / p99 | CR3 p50 / p95 / p99 |
|---|---:|---:|
| metadata parse | 239.025 / 248.204 / 280.168 ms | 58.009 / 61.053 / 64.124 ms |
| sensor decode | 241.449 / 244.603 / 296.714 ms | 59.707 / 62.935 / 64.291 ms |
| cached edge-220 thumbnail | 3.110 / 4.497 / 4.903 ms | 3.996 / 19.061 / 29.500 ms |
| uncached edge-220 thumbnail decode and render | 247.063 / 261.985 / 285.656 ms | 61.159 / 102.041 / 160.941 ms |
| warm edge-1024 display render | 37.154 / 39.582 / 39.661 ms | 51.273 / 85.208 / 98.348 ms |
| warm edge-1440 display render | 122.513 / 136.493 / 139.473 ms | 59.129 / 89.586 / 102.755 ms |
| retained edge-1440 linear base | 97.455 / 102.505 / 102.709 ms | 41.327 / 67.368 / 75.857 ms |
| CPU late-slider release, edge 1440 | 123.625 / 127.753 / 128.725 ms | 56.952 / 69.805 / 82.641 ms |
| final sRGB packing within that CPU late render | 15.574 / 16.773 / 16.816 ms | 13.998 / 18.189 / 19.780 ms |
| CPU-fallback loupe backing crop and RGB read | 0.001 / 0.002 / 0.002 ms | 0.001 / 0.003 / 0.003 ms |
| warm full display render | 751.034 / 794.544 / 818.412 ms | 1185.032 / 1843.782 / 1988.485 ms |

The direct MSL cached late-edit result remains 47.557 / 47.758 / 66.254 ms
p50/p95/p99. It eliminates the CPU's repeat traversal, RGBA8 engine copy,
`CGImage` construction, and final sRGB pack from that interaction, while its
presentation tail remains the recorded Branch C issue.

The engine now exposes final output-packing time only when the benchmark asks
for it; normal rendering preserves its previous timing and output contract.
Swift signposts now cover load/decode, recipe, core render, engine copy,
`CGImage`, texture upload, Metal encode/queue/GPU/present, histogram analysis,
and clipping-overlay analysis. Histogram and clipping work is dormant on the
normal GPU-only viewer; it is only scheduled for a strict-CPU fallback frame.

The harness now executes each workload in its own warmed series instead of
interleaving it with a full-resolution render. The table above remains the
pre-isolation baseline; the final isolated results are recorded below.

### Traversal, copy, and memory accounting

| Workload | Full-frame CPU traversal | CPU copies | GPU uploads/readback |
|---|---:|---:|---:|
| edge-220 filmstrip thumbnail | 1 | engine RGBA8 → Swift `Data`: 1 | none |
| strict CPU edge/full display | 1 | engine RGBA8 → Swift `Data`: 1 | none |
| retained linear-base update | 1 early-stage traversal | engine RGBA32F → Swift `Data`: 1 | one RGBA32F upload; no readback |
| cached Metal late edit | 0 | 0 | 0 upload/readback; one drawable pass |

The renderer admits at most 1.5 GiB of linear-base work while reserving 1 GiB
of system/application headroom on the 8 GB reference machine. The measured
edge-1440 admission estimates are 277.66 MiB (CR2) and 184.80 MiB (CR3), before
the small retained texture and two SDR drawables. Repeated allocation testing
keeps retained Metal growth below 64 MiB after 256 texture cycles.

## Phase 2C final acceptance capture

Recorded 2026-07-13 after isolating workload series, fusing preview
orientation/downsampling, selecting the CFA-preserving 4× linear-preview level
when it remains within 5% of the requested edge, adding embedded culling
previews, and using a bounded display-synchronised edit burst. Both RAW captures
used 31 samples in ReleaseFast on the reference M3/macOS 26.5.1 machine with a
warm filesystem cache and a freshly decoded engine source.

| Workload | CR2 p50 / p95 / p99 | CR3 p50 / p95 / p99 |
|---|---:|---:|
| metadata parse | 252.491 / 255.724 / 294.290 ms | 47.617 / 52.251 / 56.009 ms |
| sensor decode | 254.289 / 257.645 / 260.560 ms | 50.162 / 56.312 / 57.013 ms |
| cached edge-220 engine thumbnail | 2.700 / 2.894 / 3.232 ms | 3.356 / 3.404 / 13.804 ms |
| uncached edge-220 decode + render | 258.621 / 260.551 / 260.626 ms | 52.954 / 57.514 / 76.155 ms |
| warm edge-1024 display | 35.350 / 45.915 / 46.167 ms | 41.790 / 43.719 / 45.641 ms |
| strict warm edge-1440 display | 132.751 / 135.863 / 153.871 ms | 51.994 / 55.525 / 55.926 ms |
| retained ≤1440 linear base | 25.796 / 33.841 / 35.683 ms | 26.210 / 27.085 / 27.327 ms |
| strict CPU late release | 134.775 / 138.492 / 142.289 ms | 50.206 / 52.553 / 52.640 ms |
| final sRGB packing | 11.115 / 11.263 / 11.269 ms | 13.352 / 13.515 / 13.598 ms |
| CPU loupe crop/read | 0.002 / 0.002 / 0.002 ms | 0.001 / 0.002 / 0.002 ms |
| warm full display | 895.646 / 956.105 / 985.584 ms | 1126.910 / 1277.363 / 1286.957 ms |

The CR2 series ran for 63.684 seconds and admitted 160.23 MiB for its retained
linear preview. CR3 ran for 47.165 seconds and admitted 184.80 MiB. The harness
prints duration with every future capture so thermal exposure is explicit.

The app-level embedded-preview benchmark includes decode, actor handoff, and
publication into the observable thumbnail store. CR2 recorded
23.738/30.702/202.824 ms p50/p95/p99; CR3 recorded
25.004/28.363/148.637 ms. The cold-tail p99 and p95 both remain below the
250 ms first-visible requirement.

The final 31-frame windowed Metal sweep recorded 44.955/47.694/47.773 ms
p50/p95/p99 on the 60 Hz display. Median stage timings were 0.115 ms encode,
0.211 ms queue, 0.628 ms GPU, and 35.204 ms presentation. This passes the
windowed contract of at most three display intervals (50.0 ms here). The
original 33 ms target remains the direct-display/high-refresh target: a
`CAMetalDisplayLink` experiment could not satisfy it because the API supplied a
31.6 ms two-frame target horizon before compositor time and measured
81.649 ms p95.

Against the exact-edge CR2 CPU-to-`CGImage` p95 of 138.492 ms, the final
47.694 ms GPU input-to-visible result is 2.90× faster. The same GPU run recorded
275.52 MiB peak RSS and 35.64 MiB current Metal allocation. Their conservative
sum is 311.16 MiB, leaving 7,880.84 MiB of the 8 GiB reference machine; the
31-frame sweep lasted 1.552 seconds. The existing sustained trace remains the
thermal/idle-energy proof.
