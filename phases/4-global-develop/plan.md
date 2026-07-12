# Phase 4 — baseline global develop

**Objective:** make supported images finishable with dependable global controls,
correct geometry, persistent recipes, and a focused develop view.

## User outcome

The user can correct white balance, exposure, tonal balance, global colour,
crop, and straighten; compare before/after; copy adjustments; and reopen the
session without losing edits.

## Dependencies

- Phase 3 culling workflow.
- Phase 2B engine-v2 baseline colour.
- Persistent session and recipe storage.

## Work items

### 4.1 Finalize recipe and renderer evolution

- [ ] Separate recipe schema version from renderer manifest identity.
- [ ] Validate every parameter during parsing.
- [ ] Preserve engine-v1 rendering.
- [ ] Define explicit recipe migration APIs.
- [ ] Never silently upgrade a stored recipe.
- [ ] Add canonical serialization for every new operation.
- [ ] Define operation order independent of UI panel order.
- [ ] Give every operation an exact neutral state.

### 4.2 Improve baseline demosaic and highlight handling

- [ ] Add one measured edge-aware Bayer demosaic, such as RCD, behind a new
  implementation ID.
- [ ] Review algorithm licensing before implementation or adoption.
- [ ] Keep bilinear for v1 and diagnostic comparison.
- [ ] Add zipper, maze, diagonal, false-colour, fine-grid, odd-size, and border
  fixtures.
- [ ] Add clipped-channel highlight reconstruction or compression suitable for
  the supported DNG corpus.
  Phase 2B supplies a conservative neutral blend near sensor white; this item
  remains open for reconstruction of recoverable detail and user-adjustable
  highlight behavior.
- [ ] Ensure highlight handling is monotonic and finite.
- [ ] Record objective and visual improvement before making the new demosaic the
  default.

### 4.3 Add essential global controls

- [ ] Temperature and tint UI mapped to canonical engine parameters.
- [ ] Exposure compensation over a documented bounded range.
- [ ] Whites and blacks.
- [ ] Highlights and shadows.
- [ ] Contrast with neutral zero.
- [ ] Editable levels or a basic curve.
- [ ] Global saturation.
- [ ] Vibrance only if it can be bounded and tested without becoming a targeted
  colour tool.
- [ ] Optional monochrome only if it does not delay the critical controls.
- [ ] Reject NaN, infinity, and out-of-range values before rendering.
- [ ] Verify neutral controls do not alter prior-stage output.

### 4.4 Add geometry as recipe data

- [ ] Apply camera orientation by default.
- [ ] Nondestructive crop.
- [ ] 90-degree rotate and flips.
- [ ] Bounded free-angle straighten.
- [ ] Orientation-independent normalized crop coordinates.
- [ ] Common aspect-ratio presets.
- [ ] Reset crop and reset geometry.
- [ ] Define orientation → straighten → crop → resize order.
- [ ] Prevent zero-area and out-of-bounds crop.
- [ ] Preserve crop intent across preview and full resolution.

### 4.5 Build the develop UI

- [ ] Single-image develop view connected to canonical recipes.
- [ ] Histogram based on the displayed preview.
- [ ] Shadow and highlight clipping indicators.
- [ ] Press-and-hold before/after.
- [ ] Fit, fill, 100% zoom, and pan.
- [ ] Crop overlay and straighten interaction.
- [ ] Debounced slider previews.
- [ ] Drop superseded render jobs.
- [ ] Full-quality preview after interaction ends.
- [ ] Visible renderer/profile/error status.
- [ ] Predictable keyboard focus.

### 4.6 Persist and batch global edits

- [ ] Store canonical recipes in the CAS.
- [ ] Atomically update each asset's current recipe reference.
- [ ] Autosave after a short debounce.
- [ ] Preserve the previous recipe on interrupted write.
- [ ] Reset to import defaults.
- [ ] Copy and paste adjustments.
- [ ] Select paste categories: white balance, tone, colour, geometry.
- [ ] Exclude geometry from batch paste by default.
- [ ] Apply to selection as one undoable transaction.
- [ ] Add session default adjustments for newly imported images.

### 4.7 Add pragmatic lens and detail minimums

These are included only if representative shoots cannot be completed without
them.

- [ ] Basic chromatic-aberration correction.
- [ ] Basic distortion and vignetting from a small, versioned lens-data source.
- [ ] Decode stable lens identity, focal length, aperture, and focus distance;
  never select or interpolate a lens profile from display-name text alone.
- [ ] Keep distortion, lateral CA, falloff, and detail correction as independent
  bounded models with the profile ID included in renderer/cache identity.
- [ ] Conservative input sharpening with a true off state.
- [ ] Conservative global denoise with a true off state.
- [ ] Record the evidence that each is required before adding it.

See the [Capture One calibration adoption audit](../../research/capture-one-adoption-audit.md)
for the initial Canon camera/lens evidence and the rights-cleared implementation
boundary.

## Tests

- [ ] Engine-v1 byte-exact freeze.
- [ ] Recipe canonical roundtrip.
- [ ] Invalid/non-finite parameter rejection.
- [ ] Neutral-state identity for every operation.
- [ ] Crop transform preview/full-resolution roundtrip.
- [ ] All orientation semantics.
- [ ] Extreme tonal input remains finite.
- [ ] Neutral grey remains channel-balanced.
- [ ] New demosaic artefact fixtures.
- [ ] Synthetic v2 goldens for each control.
- [ ] Real-camera perceptual report.
- [ ] Import → edit → autosave → close → reopen → render.
- [ ] Batch apply leaves excluded geometry unchanged.
- [ ] Crash during recipe update leaves old or complete new recipe.

## Exit criteria

- [ ] At least two supported camera models have usable baseline colour and
  correct geometry.
- [ ] A 50-image session can be imported, culled, edited, closed, and reopened
  without data loss.
- [ ] Every selected frame in the acceptance shoot can be made technically
  usable with global controls.
- [ ] Warm 1440px global-control update is p50 ≤ 150 ms and p95 ≤ 300 ms on the
  CPU reference path.
- [ ] Full-resolution 24MP render is p50 ≤ 2 seconds.
- [ ] Peak memory for one 24MP render is ≤ 1 GiB.
- [ ] No recipe, geometry, or tonal operation produces non-finite output.
- [ ] Existing durability and compatibility gates remain green.

## Risks

- Global controls can expand into an unbounded colour project.
- New demosaic work may consume time without changing user outcomes.
- Geometry can invalidate caches incorrectly.
- Full-frame f32 work can consume excessive memory.
- UI work can obscure engine correctness.

## Non-goals

- Targeted hue ranges and skin-tone tools.
- 3D-LUT camera looks.
- Adjustment layers and local masks.
- Brushes, gradients, or subject masks.
- Clarity, structure, or dehaze unless required by the acceptance shoot.
- Profiled denoise.
- Metal.
- Native proprietary decoders.
- Full Git branch/merge semantics.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
