# Phase 5 — develop maturity: Capture One-grade processing

> **Objective:** From "proves the pipeline" to "produces keepers": better
> demosaic, real colour management with camera profiles, the colour
> editor, local adjustments as layers, and the develop UI.
>
> **Definition of done:** The golden-corpus perceptual score against
> darktable-cli reference renders crosses an agreed threshold; at least
> two cameras have tuned profiles that beat the bare-matrix render in a
> blind A/B; a real shoot can be culled *and* finished in banksia end to
> end.

**Status: not started.** Requires Phase 3 (everything here ships as
engine v2+ through the registry). Camera profiles and the colour editor
are independent of Phase 4 and can pull forward.

## 0. Prerequisite: the real-camera corpus

This phase is where synthetic stops being enough.

- [ ] Vendor 10–20 real DNGs (own cameras first; raw.pixls.us for breadth
      — check licences per file, record provenance in `golden/corpus.md`).
- [ ] Reference renders: dcraw and darktable-cli outputs committed beside
      each file; the golden harness gains a perceptual mode (mean ΔE in
      Lab + SSIM) with per-case thresholds alongside the byte-exact
      synthetic ratchet. Phase 0's deferred oracle lands here.
- [ ] Lossless-JPEG (LJ92) decode lands here if the corpus demands it
      (most real DNGs are LJ92), else stays in Phase 6.

## 1. Colour management (engine v2)

- [ ] Pipeline becomes colour-managed: camera RGB → (ColorMatrix1/2 +
      CalibrationIlluminant white-point adaptation, Bradford) → XYZ D50 →
      working space (linear Rec.2020) → display transform at encode.
- [ ] Decode grows the colour tags (ColorMatrix1/2, CameraCalibration,
      CalibrationIlluminant) — the Phase 0 deviation note closes.
- [ ] Display transform: filmic-style tone mapping with highlight
      desaturation (parameterized, versioned); plain sRGB stays as v1.
- [ ] Golden: every v2 case lands beside frozen v1 cases; ΔE against
      darktable references recorded per corpus file.

## 2. Camera profiles (the Capture One crown jewel, as data)

- [ ] Profile format: matrix + optional 1D curves + optional 3D LUT
      (small, e.g. 17³), serialized as canonical JSON like recipes;
      content-addressed; referenced by (make, model) with a bare-matrix
      fallback.
- [ ] Profile solver tool (`banksia profile-solve`): given a ColorChecker
      shot + reference Lab values, least-squares the matrix, then the
      LUT residual. A tool, not a library dependency.
- [ ] Ship tuned profiles for the developer's own cameras; blind A/B
      script (randomized pair presentation) to validate "beats bare
      matrix".

## 3. Demosaic v2

- [ ] RCD behind the registry (same comptime-per-CFA shape as bilinear);
      bilinear remains engine v1's demosaic forever.
- [ ] Quality gate: ΔE improvement on the real corpus recorded; zipper/
      maze artefact check on the synthetic checker scene (which exists
      precisely for this).

## 4. Local adjustments: layers + masks

- [ ] Recipe schema v2: ops group into layers; each layer has an optional
      mask; layers compose in order. Canonical serialization extends
      (older engine versions reject v2 recipes cleanly).
- [ ] Masks: parametric (elliptical, linear gradient) + luma range +
      colour range; mask control points in `MultiArrayList`; masks render
      to a plane once per layer, cached like any stage.
- [ ] Colour editor op: hue-wedge selection with smooth falloff,
      HSL deltas within the range; skin-tone preset = a named wedge.
- [ ] Structure/clarity op: guided-filter base/detail split, detail gain.
- [ ] Per-ISO denoise: profiled NLM parameterized by (camera, ISO) from
      dark-frame measurements; profile data rides with camera profiles.
- [ ] Crop/rotate as a geometry op in the recipe (rendered last before
      encode; the cache keys already account for it via recipe hash).

## 5. Develop UI

- [ ] Single-image view: op-stack/layers panel, per-op controls,
      before/after (press-and-hold), 100% loupe.
- [ ] Side-by-side branch comparison (Phase 3's payoff made visual).
- [ ] The C ABI grows deliberately; if the surface passes ~16 functions,
      stop and design a batched command protocol instead of adding more.

## Tests

- Perceptual golden (ΔE/SSIM) on the real corpus vs darktable-cli — the
  phase's headline number, in CI.
- v1 byte-exact cases stay green throughout (the registry freeze test
  from Phase 3 is now guarding real behaviour).
- Mask determinism + cache pair assertions extend to layers.
- Profile solver: synthetic ColorChecker (rendered through a known
  matrix) recovers that matrix within tolerance (round-trip property).
- Colour editor: wedge selection is continuous at the wedge edges
  (no hue seams — property test sweeping hue).

## Exit criteria

- [ ] Mean ΔE vs darktable references below the blessed threshold on the
      corpus (record threshold and score: ___).
- [ ] Two camera profiles beat bare matrix in blind A/B (record: ___).
- [ ] A real shoot: import → cull (Phase 4) → develop → export end to end
      in banksia, no other tool touched.

## Learnings

*(recorded as the phase runs)*
