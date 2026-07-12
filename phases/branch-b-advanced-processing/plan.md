# Branch B — advanced image processing

### Hypothesis

Banksia can finish more demanding shoots for a narrow supported camera set
without attempting broad Capture One parity.

### Discover

- [ ] Identify controls that beta users actually require.
- [ ] Expand the corpus with dual-illuminant charts, skin, saturated colours,
  deep shadows, highlights, fine detail, moiré, and high ISO.
- [ ] Separate objective accuracy from subjective preference.
- [ ] Establish blind A/B tooling.

### Prove in independent increments

#### B1. Camera profiles

- [ ] Immutable matrix + optional curves + optional LUT format.
- [ ] Keep camera colour profile and camera tone curve independently selectable.
- [ ] Add camera/ISO calibration records with stable IDs and provenance.
- [ ] Profile provenance and supported illuminants.
- [ ] ColorChecker solver.
- [ ] Dual-illuminant interpolation.
- [ ] Bare-matrix fallback clearly labelled.
- [ ] New profile IDs rather than in-place mutation.

#### B2. Advanced colour

- [ ] Targeted hue/saturation/lightness ranges.
- [ ] Continuous hue wrap at 0°/360°.
- [ ] Skin-tone range preset based on measured need.
- [ ] Versioned gamut and tone mapping.
- [ ] Blind preference evaluation.

#### B3. Local adjustments

- [ ] Versioned layered recipe schema.
- [ ] Elliptical and linear-gradient masks first.
- [ ] Luma and colour range only after basic geometry works.
- [ ] Immutable/content-addressed mask data.
- [ ] Stable coordinates through orientation/crop.
- [ ] Cached mask rasterization by geometry and renderer identity.
- [ ] Brushes only after gradients prove the layer model.

#### B4. Detail processing

- [ ] Lens correction expansion over focal length, aperture, and available focus
  distance, with distortion, lateral CA, falloff, and detail models independent.
- [ ] Improved sharpening.
- [ ] Profiled denoise.
- [ ] Clarity/structure.
- [ ] Healing only as a separate project with its own UX and cache design.

### Tests and metrics

- [ ] Per-camera/illuminant ΔE00.
- [ ] Neutral-axis and gamut-boundary cases.
- [ ] Frozen historical renderer goldens.
- [ ] Profile solver known-transform roundtrip.
- [ ] LUT continuity.
- [ ] Hue-range seam tests.
- [ ] Mask coordinate/cache tests.
- [ ] Median ColorChecker ΔE00 target ≤ 3 and p95 ≤ 8 for supported profiled
  cameras.
- [ ] Proposed default preferred over bare matrix in ≥ 60% of at least 100
  randomized comparisons with confidence interval reported.
- [ ] Three demanding shoots completed without another RAW developer.

The [Capture One calibration adoption audit](../../research/capture-one-adoption-audit.md)
records the evidence behind this split. Capture One extraction artifacts guide
architecture and comparison only; Banksia profiles require distributable
provenance.

### Invest gate

Ship global profile-backed improvements before requiring layers. Add each advanced
subsystem only when it removes a measured workflow blocker.

### Non-goals

- Every camera.
- Photoshop compositing.
- Generative editing.
- Treating darktable similarity as the sole quality definition.
- Replacing historical renderers in place.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
