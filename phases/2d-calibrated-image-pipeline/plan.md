# Phase 2D — calibrated image pipeline foundation

**Status:** in progress
**Objective:** replace Banksia's provisional camera rendering with a versioned,
camera-, ISO-, and lens-aware pipeline bootstrapped from the extracted Capture
One 16.7.3 calibration corpus, while preserving strict historical renderers and
the Phase 2C performance architecture.

## User outcome

A supported RAW opens with a strong camera-specific default: neutral fine fabric
does not develop false colour, skin and saturated colours remain plausible,
highlights roll off deliberately, noise/detail defaults follow the camera and
ISO, and supported lenses receive measured optical correction. The photographer
can still select a neutral matrix/linear rendering and every dependency remains
visible and reproducible.

## Agreed calibration policy

- The initial calibration source is the local Capture One 16.7.3 extraction in
  `reverse-engineering/capture-one-extracted/`.
- Bootstrap values are imported into a Banksia-owned, immutable format with
  explicit source build, extraction revision, and profile IDs.
- Camera colour profile, film curve, ISO/detail calibration, and lens profile
  remain separate dependencies even when Capture One selects them together.
- Later Banksia tuning creates new profile versions. It never mutates a bootstrap
  profile or silently changes an existing recipe/render manifest.
- Capture One renders produced by the existing automation tools are the initial
  behavioral oracle. They are comparison targets, not the runtime engine.
- Engine v1 remains byte-frozen. Existing engine-v2 artifacts remain addressable
  by their original renderer manifest.

## Initial supported calibration set

| Camera | Input profile | Film curve | Base gain | Sensor-range gain |
|---|---|---|---:|---:|
| Canon EOS-1D X Mark II | `CanonEOS1DX2-ProStandard.icm` | `CanonEOS1DX2-Auto.fcrv` | 1.00 | 1.15 |
| Canon EOS R3 | `CanonEOSR3-ProStandard.icm` | `CanonEOSR3-Auto.fcrv` | 1.07 | 1.00 |

| Lens | Geometry/CA nodes | Falloff records |
|---|---:|---:|
| Canon EF 24–105mm f/4L IS II USM | 12 | 192 |
| Canon EF 24–70mm f/2.8L II USM | 5 | 95 |
| Canon EF 70–200mm f/4L IS USM | 4 | 77 |

Apple LinearRaw continues through its explicit three-channel engine-v2 path and
uses a clearly identified generic/matrix fallback until a matching extracted
or Banksia-tuned calibration is added.

## Dependencies

- Phase 2B capture facts, corpus, strict matrix path, and LinearRaw domain.
- Phase 2C render domains, manifests, cancellation, memory admission, Metal
  surface, telemetry, and CPU fallback.
- Extracted `calibration.sqlite`, camera defaults, film curves, lens database,
  focused Ghidra reports, and Capture One oracle-render scripts.

## Target processing graph

```text
decode + immutable capture facts
→ resolve camera / ISO / lens calibration
→ per-site black and white normalization
→ defect, row/column, and green-equalization cleanup
→ RAW-domain white balance and channel headroom
→ edge-aware demosaic + calibrated anti-colour-aliasing
→ highlight reconstruction
→ camera/ISO-aware chroma then luminance denoise
→ nonlinear camera input profile into linear Rec.2020
→ lens CA / distortion / falloff correction
→ independently selected camera film curve and base gain
→ global develop operations
→ capture sharpening
→ display/output transform, proofing, and output sharpening
```

Preview, full-resolution, CPU, and Metal implementations must share these
semantic stages even when they fuse kernels or use different execution plans.

## Work items

### 2D.1 Freeze calibration inputs and identities

- [x] Record SHA-256, Capture One build, extraction-tool revision, schema
  version, and row counts for every bootstrap artifact.
- [x] Add a read-only audit command that reports the selected camera, ISO,
  colour, curve, detail, and lens records for a RAW without rendering it.
- [x] Define stable IDs for calibration bundle, camera record, ISO record, input
  profile, film curve, lens profile, and processing graph.
- [x] Include every selected dependency ID in the renderer manifest and first
  affected stage/cache key.
- [x] Reject missing, ambiguous, non-finite, malformed, or unsupported records
  with an explicit fallback reason.
- [x] Preserve the current neutral matrix renderer as a selectable fallback.

### 2D.2 Define Banksia calibration formats and resolution rules

- [x] Convert the SQLite/XML extraction into compact canonical runtime records;
  runtime code must not query the Capture One installation.
- [x] Match cameras by normalized stable identity, not display-name substring.
- [x] Extend capture facts with numeric lens identity, focal length, aperture,
  focus distance when present, sensor mode, and effective ISO/gain mode.
- [x] Resolve exact ISO nodes first; interpolate only fields whose extracted
  domain is continuous and preserve dual-gain/discontinuous boundaries.
- [x] Define explicit generic fallback, partial-match, and correction-off states.
- [x] Add a diagnostic explanation for every resolved or skipped calibration.

### 2D.3 Make the pipeline graph explicit and versioned

- [x] Separate recipe schema, semantic graph version, operation implementation
  IDs, calibration dependencies, and CPU/GPU execution identity.
- [x] Make stage input/output domains explicit: CFA, camera RGB, profiled
  working RGB, developed linear RGB, and display/output RGB.
- [x] Define neutral states and legal ordering for every technical and creative
  operation.
- [x] Keep camera defaults outside the user's adjustment recipe; a resolved
  default set is an immutable dependency that the recipe may override.
- [x] Require explicit migration when a variant adopts a newer graph or tuned
  profile.
- [x] Add a pipeline inspection dump showing stages, fusion, precision, and
  dependency IDs for a render request.
- [x] Scope mutable adjustment recipes to canonical asset identity within the
  active session, restore them before rendering a new selection, and prove
  switching assets cannot turn a local edit into an implicit batch edit.

### 2D.4 Replace provisional Bayer reconstruction

- [x] Preserve the last valid retained preview while early white-balance work
  coalesces, and publish only the newest completed generation without replacing
  the image with a loading surface.
- [x] Separate full-resolution source geometry from retained-preview geometry;
  progressively request 1440, 2880, and bounded 4096-edge linear textures from
  drawable density instead of enlarging one 1440-edge texture indefinitely.
- [x] Implement a rights-unconstrained, maintainable edge-aware Bayer reference,
  initially RCD unless corpus evidence favors another method.
- [x] Preserve bilinear and the current chroma safety filter as diagnostic
  implementations with distinct IDs.
- [x] Add green equalization, hot/flagged-pixel cleanup, and bounded row/column
  correction before demosaic where calibration supplies parameters.
- [x] Make anti-colour-alias strength camera/ISO-aware using the extracted
  defaults rather than one global constant.
- [x] Add recoverable clipped-channel reconstruction using per-channel white
  levels and calibrated headroom.
- [x] Cover neutral fine fabric, diagonal lines, zippering, maze detail, colour
  edges, clipped highlights, borders, odd dimensions, and preview reduction.
- [x] Select the new reconstruction only after objective and visual corpus gates
  pass; never replace a historical implementation ID in place.

### 2D.5 Implement nonlinear camera colour profiles

- [ ] Import ICC input shapers, 33×33×33 `mft2` CLUTs, and output tables into a
  canonical Banksia profile record.
- [ ] Implement a strict CPU tetrahedral or trilinear CLUT reference with
  documented Lab/PCS conversion and boundary behavior.
- [ ] Keep the technical DNG/LibRaw matrix path independently selectable.
- [ ] Apply the nonlinear camera profile before creative tone and colour tools.
- [ ] Validate neutral-axis continuity, saturated colours, skin, gradients, LUT
  boundaries, and finite out-of-gamut handling.
- [ ] Add provisional ProStandard profiles for EOS-1D X Mark II and EOS R3.

### 2D.6 Implement camera film curves and baseline defaults

- [ ] Import the separate main, CCD/pre-, and contrast curve components with
  exact fixed-point control points and flags.
- [ ] Implement deterministic monotonic interpolation matching recovered curve
  semantics closely enough for the oracle corpus.
- [ ] Apply camera base gain and sensor-range gain as named, inspectable
  technical defaults.
- [ ] Provide `Linear`, `Capture One Auto bootstrap`, and future Banksia curve
  selections without changing the camera colour profile.
- [ ] Define highlight rolloff, negative-input, above-one, and clipping behavior.
- [ ] Ensure exposure and user tone controls remain separate recipe operations.

### 2D.7 Add a coherent camera/ISO detail model

- [ ] Import read/floor and Poisson/shot-noise coefficients with sensor-mode
  discontinuities intact.
- [ ] Scale effective noise by white-balance/channel gains.
- [ ] Implement isolated-pixel cleanup and conservative chroma noise reduction
  before luminance noise reduction.
- [ ] Add luminance denoise with an explicit off state and measurable detail
  retention; defer exact Capture One kernel replication.
- [ ] Resolve capture-sharpen amount, radius, threshold, halo control, fine grain,
  and anti-alias defaults from the same camera/ISO record.
- [ ] Reduce sharpening as calibrated noise rises and keep capture, creative,
  and output sharpening as separate operations.

### 2D.8 Add measured lens correction

- [ ] Import independent distortion, red/blue lateral CA, falloff, radial detail,
  and transverse detail records.
- [ ] Interpolate only over available focal-length, aperture, and focus-distance
  nodes; never synthesize a missing dimension silently.
- [ ] Apply lateral CA before or during reconstruction, geometry before user
  crop, falloff in linear light, and detail correction after the noise model.
- [ ] Keep every correction independently switchable and bounded.
- [ ] Include lens-profile and interpolation-node identities in cache keys.
- [ ] Validate the three initial Canon lenses across available focal/aperture
  nodes using straight lines, corners, neutral edges, and flat-field falloff.

### 2D.9 Map the calibrated graph onto Metal

- [ ] Keep strict CPU implementations as the semantic reference.
- [ ] Port regular measured kernels first: normalization, matrices, LUTs, film
  curves, lens warp/falloff, denoise, sharpening, and display conversion.
- [ ] Port demosaic only after the CPU reference and artefact suite are stable.
- [ ] Fuse stages only when telemetry proves fewer passes/transfers and the
  fused implementation retains its own stable ID.
- [ ] Preserve on-demand rendering, two-frame admission, cancellation,
  occlusion pause, and failure-only CPU fallback.
- [ ] Report CPU/GPU perceptual differences and input-to-visible percentiles for
  every default supported-camera path.

### 2D.10 Build Capture One comparison and Banksia tuning loops

- [ ] Freeze Capture One 16.7.3 oracle JPEG/TIFF renders with exact process
  settings for the existing Canon corpus.
- [ ] Produce named stage comparisons: neutral matrix, profile only, profile +
  film curve, detail stack, lens stack, and final default.
- [ ] Record ΔE00 where a neutral reference exists, plus SSIM, edge/moire
  artefact metrics, noise/detail measures, clipping, and finite-output status.
- [ ] Add side-by-side and blind randomized preference review tooling.
- [ ] Create Banksia-tuned profiles as new immutable versions, initially by
  adjusting bootstrap calibration rather than changing runtime code.
- [ ] Record why each tuned version differs and require explicit variant
  migration.

## Tests

- [x] Engine-v1 exact hashes remain unchanged.
- [x] Historical engine-v2 manifests remain reproducible.
- [x] Calibration import is deterministic and canonical.
- [x] Camera/ISO/lens selection and fallback tables are exhaustive.
- [ ] Extracted ICC shaper/CLUT known vectors match the source profile evaluator.
- [ ] Film-curve control points and interpolation known vectors match extraction.
- [x] Noise interpolation preserves recorded discontinuities.
- [ ] Lens-node interpolation hits exact stored nodes and remains bounded between
  them.
- [x] RAW artefact fixtures cover false colour, moiré, zippering, diagonals,
  highlights, defects, deep shadows, and saturated edges.
- [x] Full 27-file local corpus and committed CI corpus remain green.
- [ ] CPU/Metal conformance covers every default stage and failure fallback.
- [ ] Repeated open/edit/close, memory pressure, cancellation, and resize soak.
- [x] Per-asset recipe isolation covers canonical URL aliases and repeated
  two-RAW selection with different early and late adjustments.

## Exit criteria

- [x] EOS-1D X Mark II and EOS R3 automatically resolve the intended bootstrap
  colour profile, curve, ISO/detail record, and supported lens profile.
- [x] The CR3 black/white fine-fabric case remains neutral without broad visible
  chroma smearing at fit and 100% views.
- [ ] Initial supported-camera defaults are preferred over the bare matrix in at
  least 60% of 100 randomized blind comparisons, with confidence reported.
- [ ] ColorChecker median ΔE00 is ≤3 and p95 ≤8 once controlled captures exist;
  until then the unavailable chart gate is reported, never fabricated.
- [ ] Gradients, neutral axes, highlights, and LUT boundaries have no visible
  discontinuity or non-finite output.
- [ ] Warm edge-1440 default preview is ≤100 ms p95 after decode on the reference
  M3, with each stage and transfer reported.
- [ ] Cached late adjustments remain ≤33 ms p95 input-to-visible.
- [ ] Full-resolution 24MP default render is ≤2 seconds p95 and admitted peak
  combined memory remains ≤1.5 GiB with 1 GiB system headroom.
- [ ] Static GPU work returns to idle; no obsolete frame is published.
- [x] Every artifact records graph, calibration, renderer, precision, backend,
  source, recipe, and output identities.

## Risks

- Calibration interactions can produce a plausible image while hiding a wrong
  stage order or double-applied gain.
- A camera-specific default may improve preference while reducing objective
  colour accuracy; both results must be reported separately.
- Large 3D LUTs, lens tables, and denoise scratch can inflate memory and cache
  identity if loaded or copied per frame.
- Preview-only reconstruction shortcuts can reintroduce moiré or false colour.
- Matching one Capture One version too tightly can make later Banksia tuning
  unnecessarily difficult unless dependencies remain separate.

## Non-goals

- Pixel-identical reproduction of Capture One internals.
- Supporting every extracted camera or lens in the first calibration set.
- Local masks, brushes, healing, subject selection, or compositing.
- Silently updating old variants to newer profiles or graph versions.
- Making the Capture One installation a runtime dependency.
- Moving storage, catalog, import, or session durability work into the renderer.

## Phase close-out evidence

- Calibration bundle revision and selected profile IDs.
- `pipeline-audit` reports active and target graph IDs, domains, implementation
  IDs, neutral behavior, precision, fusion, resolution states, and every selected
  dependency for a RAW without rendering it.
- The C ABI and Swift render contract snapshot the same bounded pipeline manifest;
  dependency changes invalidate the first affected stage and final artifact key.
- ISO resolver tests cover exact nodes, continuous interpolation, lower-node
  inheritance, effective-ISO precedence, and refusal to interpolate across a
  gain discontinuity.
- Golden conformance passes all 25 historical cases. The full local 27-file RAW
  corpus and committed eight-file native-DNG corpus pass in Debug, and the
  committed gate also passes in ReleaseFast.
- Early temperature/tint edits retain the currently presented Metal texture
  until the accepted replacement is ready. Source dimensions now cross the C
  ABI separately, zoom refinement is display-scale aware and debounced, active
  early drags cap at the 2880 detail tier, and automatic nearest-neighbour
  enlargement of undersized previews is removed.
- Adjustment recipes are keyed by canonical asset URL for the active session;
  two-RAW integration coverage proves early and late edits restore only for the
  selected image. Session/catalog durability remains explicitly deferred.
- The whole-frame RCD reference preserves measured CFA samples, reduces mean
  false chroma versus bilinear on an odd-sized neutral fine-weave fixture, and
  is finite and deterministic on tiny/odd borders. Objective RGB fixtures now
  cover diagonals, maze detail, colour edges, and clipped highlights. Engine v3
  selects the candidate only with an explicit resolved calibration snapshot;
  engine v2 remains frozen. Calibrated green equalization, CFA-local isolated
  hot-pixel cleanup, and camera/ISO anti-colour-alias strength have exact off
  states and bounded tests. No extracted row/column coefficient exists for the
  two bootstrap cameras, so that conditional correction is an explicit no-op
  rather than an invented value. Zipper edges, deep shadows, saturated edges,
  CFA-local defects, and a calibrated preview reduction path complete the
  synthetic artifact set. Clipped-channel recovery consumes the already
  normalized per-CFA white levels and the recovered 0.9659363 clip safety point,
  with engine-v2's historical 0.8 trigger unchanged. Whole-frame v3 admission
  counts its bounded cleanup/RCD scratch planes, and those planes now use scoped
  lifetimes instead of accumulating in the frame arena.
- The reproducible `compare-2d4` tool rendered all eight committed Canon corpus
  files as legacy-v2/candidate-v3 pairs at edge 1440. Fit and original-resolution
  review selected v3: the EOS R3 neutral fine fabric no longer has the broad
  green/magenta cast, emerald fabric retains its intended colour, the 1D X Mark
  II detail/skin/warm cases remain plausible, and ISO 12800 retains colour under
  a conservative pre-2D.7 anti-alias cap. The app now requests engine v3 and
  publishes `graph.banksia.reconstruction.v3` with
  `banksia.cpu.strict-f32.v3`; engine v2 hashes and implementation IDs remain
  unchanged and selectable as historical artifacts.
- Reference machine, OS, build modes, and Capture One oracle version.
- Corpus and oracle hashes.
- CPU/GPU conformance report.
- Quality and preference reports.
- p50/p95/p99 stage, visible-latency, and memory results.
- Explicit renderer/profile migrations and retained historical manifests.

---

[Back to the roadmap](../../plan.md) · [Shared phase rules](../README.md)
