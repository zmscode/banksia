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
