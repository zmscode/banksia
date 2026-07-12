# Phase 2B hardening evidence

## Reference environment

- Machine: MacBook Air `Mac15,12`, Apple M3, 8 cores, 8 GB RAM.
- OS: macOS 26.5.1 (`25F80`).
- Zig: 0.16.0.
- LibRaw: 0.22.1 via Homebrew `libraw_r`.
- Build mode: ReleaseFast for timing, ReleaseSafe for the parser swarm.
- Corpus identity: `corpus.sha256` and `corpus.tsv` as committed with this file.

## Split timing

Command:

```sh
zig build raw-bench -- --iterations 3 \
  assets/CR2/AM4I0028.CR2 \
  'assets/CR3/S1-NU26643BlackStrip-25992-Nude Lucy-0101.CR3'
```

Warm p50 results (three runs; with three samples p95 selects the same middle
sample under the harness's deterministic nearest-rank policy):

| File | Metadata | Decode | edge-1024 v2 | Full v2 |
|---|---:|---:|---:|---:|
| EOS-1D X Mark II CR2, 20.2 MP sensor | 239.0 ms | 240.3 ms | 26.7 ms | 438.4 ms |
| EOS R3 CR3, 24.3 MP sensor | 51.4 ms | 53.7 ms | 36.9 ms | 795.7 ms |

The preview path now performs deterministic CFA-site reduction before engine-v2
processing when the requested edge is at least 2× smaller. The factor is even,
so Bayer phase is preserved. Full rendering and all engine-v1 behavior remain
unchanged. Preview geometry continues through the same scaled active-area,
default-crop, orientation, and final longest-edge transform.

## Seeded parser swarm

Synthetic full-decode/render command:

```sh
zig build raw-swarm -- --runs 10000
```

The swarm truncates every fourth candidate and applies one to eight deterministic
byte mutations to the rest. Accepted synthetic candidates continue through full
decode, colour-transform validation, and an engine-v2 render. The seed is printed
for replay. Seed `0x9e05d48` over 10,000 synthetic candidates produced 6,599
metadata accepts, 375 full decodes, 355 full renders, 3,401 clean rejections,
and zero crashes or leaks.

The local real-DNG run used seed `0x9e05d48`, 100 mutations per Apple DNG plus
100 synthetic cases: 1,000 candidates, 71 metadata accepts, 5 full decodes and
renders, 929 clean named rejections, and zero crashes or leaks.

## Bounds and finite values

- IFD visits: 8; entries per IFD: 512.
- Segment count: 65,536; decoded samples per segment: 67,108,864.
- Image edge: 65,535; total sensor pixels: 67,108,864 (64 MiPixels).
- Text/signature counts: 128 bytes; colour matrices: exactly 9 values;
  analog balance and as-shot neutral: exactly 3 values.
- Dimensions, crop rectangles, offsets, byte counts, rational denominators,
  black/white levels, and matrix elements are validated before allocation or
  pixel kernels.
- Colour matrices reject non-finite inputs; matrix application sanitizes any
  non-finite result. The swarm verifies every accepted transform is finite.

## Independent fixtures

`emu/fixtures` contains TinyDNG-generated big-endian/uncompressed and
lossless-JPEG DNGs. Their generator, upstream revision, MIT licence, hashes, and
exact reproduction commands are committed alongside them. Unit tests embed the
files and compare all 48 decoded samples.

## Integration smokes

- ReleaseFast C ABI against `AM4I0028.CR2`: 5496×3670 sensor, edge-1024
  134.7 ms, full engine-v1 654.0 ms, all API/error/leak checks passed.
- `zig build shell` completed and the SwiftUI executable launched with the same
  real CR2 path and remained live through the render interval. The remote session
  did not yield a self-capture, so this is a build/launch smoke rather than a
  recorded visual approval.
- The expanded corpus gate completed 18 full engine-v2 renders and 27 ImageIO
  decodes with all hashes, metadata records, geometry, and expected unsupported
  names intact.
