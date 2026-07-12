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

Still missing: engine output packing as its own interval, histogram and overlay
work, actual drawable presentation, peak memory, CPU-copy counts, and GPU timing.
