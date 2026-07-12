# Phase 2B — real-camera correctness and baseline colour

**Status:** complete with provisional photographer-permitted corpus; controlled
chart gates deferred to the standardized follow-up set
**Objective:** turn “this DNG decodes” into “supported DNG files render upright,
with the intended crop, plausible white balance, and technically correct baseline
colour.”

This phase establishes correctness, not a Capture One-style look.

## User outcome

A supported real DNG opens with:

- correct dimensions and orientation;
- correct active area and default crop;
- usable as-shot white balance;
- measured baseline colour;
- an actionable error for unsupported features.

## Dependencies

- Phase 2A green baseline.
- Existing DNG and lossless-JPEG decoder.
- Existing synthetic golden harness.
- Existing SwiftUI inspection shell.

## Work items

### 2B.1 Define the support profile

- [x] Choose the initial DNG-producing workflows.
- [x] Write a compatibility statement describing supported compression, CFA,
  bit depth, geometry tags, and colour tags.
- [x] Decide whether Adobe DNG Converter is an accepted temporary workflow.
- [x] Identify the initial locally available camera corpus: Canon EOS-1D X
  Mark II and Canon EOS R3.
- [x] Record unsupported but valid features separately from malformed input.

See [support-profile.md](support-profile.md). The two initial Canon models now
meet the promotion rule through committed permission-covered DNG derivatives.

### 2B.2 Build a licensed real-camera corpus

- [x] Collect approximately 6–12 required CI DNGs across the support profile.
- [x] Include the available daylight, backlight, high-contrast, skin, saturated
  colour, fine-detail, high-ISO, and portrait coverage; explicitly defer
  controlled tungsten and mixed-light scenes to the standardized follow-up set.
- [x] Include strips/tiles and uncompressed/lossless-JPEG where available.
- [x] Record provenance, licence, SHA-256, camera, lens, ISO, expected geometry,
  and relevant DNG features.
- [x] Keep a small required CI corpus and a larger optional compatibility corpus.
- [x] Add controlled grey-card and ColorChecker captures when possible.
- [x] Produce oracle outputs with exact, committed settings.

The local corpus is recorded in [corpus.md](corpus.md), the machine-readable
[corpus.tsv](corpus.tsv), and [corpus.sha256](corpus.sha256). `zig build corpus`
verifies all 27 hashes, checks the 18 supported metadata/geometry records,
completes full v2 CR2/CR3 renders, checks 9 Apple LinearRaw DNGs fail by their
expected unsupported name, and ImageIO-decodes every file. The committed
`tests/corpus/phase2b` subset adds eight permission-covered full-resolution DNGs,
exact metadata and render hashes, four storage shapes, and mandatory CI renders.

Provisional deviation accepted by the repository owner on 2026-07-12: the
available photographs cover daylight, warm/strong backlight, high contrast,
skin, saturated/neutral colour, fine detail, high ISO, and portrait orientation,
but not a controlled tungsten, mixed-light, grey-card, or ColorChecker setup.
Those standardized captures replace or extend this set later; they do not block
using the photographer-permitted corpus now.

### 2B.3 Expand decoded metadata

- [x] Introduce a richer decoded-RAW structure rather than continually widening
  unrelated fields on `SensorData`.
- [x] Parse camera make, model, unique model, lens, ISO, capture time, and
  subsecond capture time.
- [x] Parse `Orientation`, `ActiveArea`, `DefaultCropOrigin`, and
  `DefaultCropSize`.
- [x] Preserve the 2×2 per-site black/white levels needed by the Canon corpus.
- [x] Parse `ColorMatrix1/2`, `CalibrationIlluminant1/2`,
  `CameraCalibration1/2`, `AnalogBalance`, and `AsShotNeutral`.
- [x] Add metadata-only parsing for import without full pixel decode.
- [x] Verify metadata-only and full-decode results agree.

### 2B.4 Correct geometry

- [x] Separate sensor coordinates from oriented output coordinates.
- [x] Apply active-area and default-crop semantics deterministically.
- [x] Implement all eight TIFF orientation values.
- [x] Ensure preview and full-resolution geometry agree.
- [x] Report unsupported geometry opcodes rather than guessing.
- [x] Add coordinate-transform helpers for later crop and mask work.

### 2B.5 Add engine v2 baseline colour

- [x] Freeze existing engine-v1 outputs and all 20 golden hashes.
- [x] Add minimal renderer-version dispatch without implementing user history.
- [x] Select/interpolate DNG matrices for the as-shot white point.
- [x] Apply camera calibration and analog balance in the correct convention.
- [x] Implement a tested chromatic adaptation transform.
- [x] Define a linear working space, initially linear Rec.2020 or XYZ D50.
- [x] Transform from working space to linear sRGB for display.
- [x] Use the existing sRGB transfer only at output encoding.
- [x] Define behavior for negative, out-of-gamut, and above-white values.
- [x] Reject or sanitize non-finite values before output.
- [x] Ensure the `CGImage` colour-space declaration matches produced bytes.
- [x] Freeze the LibRaw XYZ-to-camera direction and `[camera][XYZ]` layout in a
  backend-boundary regression test, and visually verify representative CR2/CR3
  output before freezing corpus hashes.
- [x] Keep neutral v2 tone mapping identity in the working space and suppress
  false chroma from sensor-clipped native DNG and proprietary RAW highlights,
  requiring two near-white channels so saturated single-channel colour remains.

See [color-policy.md](color-policy.md).

### 2B.6 Build a two-layer conformance harness

- [x] Preserve byte-exact synthetic v1 cases.
- [x] Add byte-exact synthetic v2 cases for matrices, adaptation, geometry, and
  clipping policy.
- [x] Add real-camera perceptual reporting.
- [x] Measure neutral-patch ΔE00, ColorChecker median/p95 ΔE00 where available,
  SSIM/perceptual difference, and render time.
- [x] Record expected unsupported files rather than treating them as passes.
- [x] Require explicit review before blessing a new perceptual baseline.
- [x] Add a compatibility table that only regresses through a recorded decision.

See [conformance.md](conformance.md),
[perceptual-baseline.json](perceptual-baseline.json), and
[compatibility.tsv](compatibility.tsv). Controlled-patch metrics are explicitly
unavailable until a standardized chart capture exists; ImageIO comparison is
not misrepresented as a neutral chart oracle.

### 2B.7 Validate decoder strategy

- [x] Create a LibRaw integration behind the unified `emu.raw` interface.
- [x] Compare native DNG sensor output and metadata against LibRaw for an
  overlapping synthetic DNG.
- [x] Record packaging, licensing, binary-size, and deployment implications.
- [x] Require LibRaw before private alpha for the initial CR2/CR3 corpus.
- [x] Keep native DNG as the deterministic reference path regardless.

See [decoder-strategy.md](decoder-strategy.md). Banksia links `libraw_r`
dynamically and stops at the sensor-mosaic boundary.

### 2B.8 Harden performance and fuzzing

- [x] Measure metadata parse, decode, edge-1024 preview, and full render
  separately.
- [x] Mutate and truncate real corpus files through a seeded parser swarm.
- [x] Ensure accepted colour transforms always produce finite planes.
- [x] Bound tag counts, matrix counts, dimensions, and segment allocation.
- [x] Add independent externally generated big-endian and lossless-JPEG fixtures.

See [hardening.md](hardening.md). `zig build raw-swarm` is the replayable
ReleaseSafe parser workload and `zig build raw-bench -- FILE...` is the
ReleaseFast four-stage timing harness.

## Tests

- [x] Known-vector matrix and chromatic-adaptation tests.
- [x] Synthetic known-transform roundtrip.
- [x] One- and two-illuminant interpolation.
- [x] All eight orientation values.
- [x] Active-area and default-crop coordinate tests.
- [x] Per-site black-level and per-channel white-level tests.
- [x] Metadata-only versus full-decode metadata identity.
- [x] Optional-local real corpus decode gate plus representative CR2/CR3 C ABI
  renders.
- [x] Truncation and mutated-tag negative tests.
- [x] Engine-v1 freeze and engine-v2 determinism.
- [x] C ABI and shell smoke using a real image.

## Exit criteria

- [x] Every file in the declared supported corpus renders successfully.
- [x] Proprietary CR2/CR3 corpus files fail the native DNG path with documented
  `UnsupportedCr2`/`UnsupportedCr3` reasons.
- [x] Orientation and default crop match the corpus manifest 100%.
- [ ] Controlled neutral patches achieve ΔE00 ≤ 3.
- [ ] Controlled ColorChecker captures achieve median ΔE00 ≤ 5 and p95 ≤ 10
  under the documented neutral pipeline.
- [x] No supported render contains NaN or infinity.
- [x] All engine-v1 hashes remain unchanged.
- [x] Representative 24MP warm edge-1024 baseline-colour preview remains under
  250 ms (measured v2 CR2 26.7 ms; CR3 36.9 ms).
- [x] Representative full-resolution baseline-colour render remains under 1 s
  (measured v2 CR2 438.4 ms; CR3 795.7 ms).
- [x] Decoder strategy decision is recorded with evidence.

The two controlled-chart thresholds above are explicitly deferred, not passed:
the provisional photographs contain no measured chart patches. All executable
Phase 2B gates pass; standardized chart capture is a recorded follow-up.

## Risks

- DNG matrix direction and white-point conventions are easy to misuse.
- Oracle tools may hide tone curves or profiles.
- DNG variation exceeds the initial corpus.
- Corpus licensing and CI distribution may be difficult.
- Correct neutral colour may look less pleasing than a commercial camera profile.

## Non-goals

- Native proprietary RAW formats.
- X-Trans.
- Tuned 3D-LUT camera looks.
- Advanced demosaic.
- Lens correction, denoise, sharpening, or local contrast.
- Monitor soft proofing.
- Layers or masks.
- Changing engine-v1 behavior.

## Phase close-out

- Status: complete with provisional photographer-permitted corpus.
- Date: 2026-07-12.
- Commit: pending current worktree commit.
- Reference machine and OS: MacBook Air `Mac15,12`, Apple M3, 8 GB; macOS
  26.5.1 (`25F80`).
- Corpus revision: eight committed DNG hashes in
  `tests/corpus/phase2b/corpus.sha256`; 27-file optional corpus pinned by
  `corpus.sha256`.
- Commands run: `zig build test`, `zig build -Doptimize=ReleaseFast test`,
  `zig build golden`, `zig build test-ci-corpus`, `zig build raw-swarm`,
  `zig build raw-bench`, `zig build -Doptimize=ReleaseFast corpus`, and
  `zig build shell`.
- Test counts: 25/25 golden cases; 8/8 mandatory full native-DNG renders;
  18/18 optional Canon full renders; 9/9 named LinearRaw rejections; 10,000
  seeded synthetic mutation/truncation cases without crash or leak.
- Exit criteria passed: geometry, metadata, finite colour, deterministic v1/v2,
  full corpus render, compatibility, decoder strategy, preview latency, and full
  render latency.
- Exit criteria waived: controlled neutral-patch and ColorChecker ΔE00, because
  the available permission-covered photographs contain no chart. The repository
  owner accepted standardized controlled capture as a later corpus replacement.
- Deviations: tungsten and mixed-light controlled scenes are deferred; current
  warm/strong backlight is not labelled as a substitute.
- Compatibility changes: engine-v2 bounded previews use deterministic
  CFA-preserving sensor reduction; the LibRaw XYZ-to-camera boundary was fixed
  before the pending Phase 2B commit; false-colour clipping in the initial
  backlit visual checks added bounded highlight blending; the provisional
  DNG/hash/perceptual set was regenerated; engine v1 and its 20 hashes remain
  unchanged.
- Follow-up tasks: capture or adopt a standardized public tungsten/mixed-light,
  grey-card, and ColorChecker set; obtain human visual approval before changing
  the provisional perceptual baseline to approved.

---

[Back to the roadmap](../../plan.md) · [Shared phase rules](../README.md)
