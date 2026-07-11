# Phase 2B — real-camera correctness and baseline colour

**Status:** current
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

See [support-profile.md](support-profile.md). Specific camera models remain
unclaimed until licensed fixtures and expected metadata are committed.

### 2B.2 Build a licensed real-camera corpus

- [ ] Collect approximately 6–12 required CI DNGs across the support profile.
- [ ] Include daylight, tungsten, mixed light, high contrast, skin, saturated
  colour, fine detail, high ISO, and portrait orientation.
- [ ] Include strips/tiles and uncompressed/lossless-JPEG where available.
- [ ] Record provenance, licence, SHA-256, camera, lens, ISO, expected geometry,
  and relevant DNG features.
- [ ] Keep a small required CI corpus and a larger optional compatibility corpus.
- [ ] Add controlled grey-card and ColorChecker captures when possible.
- [ ] Produce oracle outputs with exact, committed settings.

The local corpus is recorded in [corpus.md](corpus.md) and
[corpus.sha256](corpus.sha256). `zig build corpus` verifies all 27 hashes,
decodes 18 CR2/CR3 mosaics, checks 9 Apple LinearRaw DNGs fail by their expected
unsupported name, and ImageIO-decodes every file. Originals remain untracked
pending licence review and distributable Bayer DNG conversion.

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
- [ ] Report unsupported geometry opcodes rather than guessing.
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

See [color-policy.md](color-policy.md).

### 2B.6 Build a two-layer conformance harness

- [x] Preserve byte-exact synthetic v1 cases.
- [x] Add byte-exact synthetic v2 cases for matrices, adaptation, geometry, and
  clipping policy.
- [ ] Add real-camera perceptual reporting.
- [ ] Measure neutral-patch ΔE00, ColorChecker median/p95 ΔE00 where available,
  SSIM/perceptual difference, and render time.
- [x] Record expected unsupported files rather than treating them as passes.
- [ ] Require explicit review before blessing a new perceptual baseline.
- [ ] Add a compatibility table that only regresses through a recorded decision.

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

- [ ] Measure metadata parse, decode, edge-1024 preview, and full render
  separately.
- [ ] Mutate and truncate real corpus files through a seeded parser swarm.
- [ ] Ensure accepted colour transforms always produce finite planes.
- [ ] Bound tag counts, matrix counts, dimensions, and segment allocation.
- [ ] Add independent externally generated big-endian and lossless-JPEG fixtures.

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
- [ ] Truncation and mutated-tag negative tests.
- [x] Engine-v1 freeze and engine-v2 determinism.
- [ ] C ABI and shell smoke using a real image.

## Exit criteria

- [ ] Every file in the declared supported corpus renders successfully.
- [x] Proprietary CR2/CR3 corpus files fail the native DNG path with documented
  `UnsupportedCr2`/`UnsupportedCr3` reasons.
- [ ] Orientation and default crop match the corpus manifest 100%.
- [ ] Controlled neutral patches achieve ΔE00 ≤ 3.
- [ ] Controlled ColorChecker captures achieve median ΔE00 ≤ 5 and p95 ≤ 10
  under the documented neutral pipeline.
- [ ] No supported render contains NaN or infinity.
- [ ] All engine-v1 hashes remain unchanged.
- [ ] Representative 24MP warm edge-1024 baseline-colour preview remains under
  250 ms (current v1 CR2 120.4 ms; CR3 166.2 ms).
- [ ] Representative full-resolution baseline-colour render remains under 1 s
  (current v1 CR2 684.6 ms; CR3 654.7 ms).
- [x] Decoder strategy decision is recorded with evidence.

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

---

[Back to the roadmap](../../plan.md) · [Shared phase rules](../README.md)
