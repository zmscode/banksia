# Phase 2B — real-camera correctness and baseline colour

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

- [ ] Choose 2–3 initial camera models or DNG-producing workflows.
- [ ] Write a compatibility statement describing supported compression, CFA,
  bit depth, geometry tags, and colour tags.
- [ ] Decide whether Adobe DNG Converter is an accepted temporary workflow.
- [ ] Identify the first camera owned or regularly accessible to the developer.
- [ ] Record unsupported but valid features separately from malformed input.

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

### 2B.3 Expand decoded metadata

- [ ] Introduce a richer decoded-RAW structure rather than continually widening
  unrelated fields on `SensorData`.
- [ ] Parse camera make, model, unique model, lens, ISO, capture time, and
  subsecond capture time.
- [ ] Parse `Orientation`, `ActiveArea`, `DefaultCropOrigin`, and
  `DefaultCropSize`.
- [ ] Parse `BlackLevelRepeatDim`, per-site black levels, and per-channel white
  levels needed by the corpus.
- [ ] Parse `ColorMatrix1/2`, `CalibrationIlluminant1/2`,
  `CameraCalibration1/2`, `AnalogBalance`, and `AsShotNeutral`.
- [ ] Add metadata-only parsing for import without full pixel decode.
- [ ] Verify metadata-only and full-decode results agree.

### 2B.4 Correct geometry

- [ ] Separate sensor coordinates from oriented output coordinates.
- [ ] Apply active-area and default-crop semantics deterministically.
- [ ] Implement all eight TIFF orientation values.
- [ ] Ensure preview and full-resolution geometry agree.
- [ ] Report unsupported geometry opcodes rather than guessing.
- [ ] Add coordinate-transform helpers for later crop and mask work.

### 2B.5 Add engine v2 baseline colour

- [ ] Freeze existing engine-v1 outputs and all 20 golden hashes.
- [ ] Add minimal renderer-version dispatch without implementing user history.
- [ ] Select/interpolate DNG matrices for the as-shot white point.
- [ ] Apply camera calibration and analog balance in the correct convention.
- [ ] Implement a tested chromatic adaptation transform.
- [ ] Define a linear working space, initially linear Rec.2020 or XYZ D50.
- [ ] Transform from working space to linear sRGB for display.
- [ ] Use the existing sRGB transfer only at output encoding.
- [ ] Define behavior for negative, out-of-gamut, and above-white values.
- [ ] Reject or sanitize non-finite values before output.
- [ ] Ensure the `CGImage` colour-space declaration matches produced bytes.

### 2B.6 Build a two-layer conformance harness

- [ ] Preserve byte-exact synthetic v1 cases.
- [ ] Add byte-exact synthetic v2 cases for matrices, adaptation, geometry, and
  clipping policy.
- [ ] Add real-camera perceptual reporting.
- [ ] Measure neutral-patch ΔE00, ColorChecker median/p95 ΔE00 where available,
  SSIM/perceptual difference, and render time.
- [ ] Record expected unsupported files rather than treating them as passes.
- [ ] Require explicit review before blessing a new perceptual baseline.
- [ ] Add a compatibility table that only regresses through a recorded decision.

### 2B.7 Validate decoder strategy

- [ ] Create a small LibRaw integration spike behind the existing decode
  interface.
- [ ] Compare native DNG sensor output and metadata against LibRaw for overlapping
  files.
- [ ] Record packaging, licensing, binary-size, and deployment implications.
- [ ] Decide at phase close whether LibRaw is required before private alpha or
  before public beta.
- [ ] Keep native DNG as the deterministic reference path regardless.

### 2B.8 Harden performance and fuzzing

- [ ] Measure metadata parse, decode, edge-1024 preview, and full render
  separately.
- [ ] Mutate and truncate real corpus files through a seeded parser swarm.
- [ ] Ensure accepted colour transforms always produce finite planes.
- [ ] Bound tag counts, matrix counts, dimensions, and segment allocation.
- [ ] Add independent externally generated big-endian and lossless-JPEG fixtures.

## Tests

- [ ] Known-vector matrix and chromatic-adaptation tests.
- [ ] Synthetic known-transform roundtrip.
- [ ] One- and two-illuminant interpolation.
- [ ] All eight orientation values.
- [ ] Active-area and default-crop coordinate tests.
- [ ] Per-site black-level and per-channel white-level tests.
- [ ] Metadata-only versus full-decode metadata identity.
- [ ] Real corpus decode and render tests.
- [ ] Truncation and mutated-tag negative tests.
- [ ] Engine-v1 freeze and engine-v2 determinism.
- [ ] C ABI and shell smoke using a real image.

## Exit criteria

- [ ] Every file in the declared supported corpus renders successfully.
- [ ] Unsupported corpus files fail with a documented named reason.
- [ ] Orientation and default crop match the corpus manifest 100%.
- [ ] Controlled neutral patches achieve ΔE00 ≤ 3.
- [ ] Controlled ColorChecker captures achieve median ΔE00 ≤ 5 and p95 ≤ 10
  under the documented neutral pipeline.
- [ ] No supported render contains NaN or infinity.
- [ ] All engine-v1 hashes remain unchanged.
- [ ] Representative 24MP warm edge-1024 preview remains under 250 ms on the
  reference Mac.
- [ ] Representative full-resolution baseline-colour render remains under 1 s.
- [ ] Decoder strategy decision is recorded with evidence.

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

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
