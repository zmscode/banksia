# Phase 2C — performance architecture and Metal proof

**Status:** in progress — exit gates remain open
**Objective:** establish a measured, backend-independent render architecture and
prove whether a GPU-resident Metal preview materially improves Banksia's
input-to-visible latency without weakening colour correctness, bounded memory,
fallback behavior, or reproducibility.

## User outcome

Opening and editing a supported RAW feels immediate. Interactive adjustments
replace the visible frame promptly, obsolete work never flashes onscreen, and a
static image consumes no continuous render work. The strict CPU renderer remains
available for canonical verification and fallback.

## Dependencies

- Phase 2B real-camera correctness and engine-v2 corpus.
- Existing synchronous CPU renderer and additive nine-function C ABI.
- Existing Swift actor and SwiftUI inspection shell.
- Shared identity, cache, measurement, and reproducibility contracts.

## Decisions already made

- Performance is the product contract; Metal is a candidate implementation.
- The strict f32 CPU backend remains the canonical historical renderer.
- GPU artifacts use a distinct execution-contract identity unless byte equality
  is proven.
- RAW container parsing, LibRaw/native DNG decode, storage, hashing, and catalog
  durability remain CPU work.
- The first proof accelerates late interactive develop and presentation, not
  RAW decoding or a new demosaic.
- The viewer uses an on-demand Metal surface. It must not run a permanent 60 fps
  loop while a still image is unchanged.
- Start with one command queue, tracked resources, precompiled pipelines, and at
  most two in-flight viewer frames. Heaps, untracked hazards, multiple queues,
  and tile shaders require separate profiling evidence.
- `rgba16Float` is an experiment with a quality gate, not the default precision
  policy.

## Work items

### 2C.1 Freeze the performance contract and current baseline

- [x] Instrument load/decode, recipe update, core render, output packing,
  engine-buffer copy, image/surface construction, histogram/overlay work, and
  input-to-visible presentation separately.
- [x] Emit Instruments-compatible signposts for the shell intervals; benchmark
  the engine-internal output pack separately without perturbing normal renders.
- [x] Record p50/p95/p99 rather than one warm sample.
- [ ] Name hardware, OS, build mode, corpus revision, dimensions, cache state,
  peak memory, and thermal test duration.
- [ ] Benchmark CR2 and CR3 cold open, edge-220/1024/1440 preview, full render,
  late-slider release, CPU-fallback loupe, and cached/uncached thumbnails.
- [x] Count full-frame traversals and CPU copies per workload.
- [x] Add a repeatable shell benchmark or trace-capture command.

Implementation started 2026-07-12. The inspection shell now separates RAW
load/decode, recipe update, core render, engine-buffer copy, and `CGImage`
construction, with matching Instruments points-of-interest signposts. The
ReleaseFast `raw-bench` harness now reports nearest-rank p50/p95/p99 and accepts
up to 101 samples. See [the seed baseline](baseline.md); presentation,
histogram/overlay, packing, memory, thermal, and longer workload captures remain.

The first ownership slice is also implemented in the shell: immutable requests
carry an explicit renderer/execution identity, CPU and Metal identities cannot
collide, and monotonic publication generations discard obsolete frames and
obsolete errors. See [the render contract](render-contract.md). Original CPU ABI
behavior remains frozen while the additive admitted-linear entry point, typed
surface ownership, and shared request contracts complete 2C.2.

### 2C.2 Define backend-independent render domains and ownership

- [x] Separate sensor CFA, camera RGB, linear working image, developed image,
  and display output as explicit domains.
- [x] Define immutable render request, renderer manifest, execution contract,
  render intent, precision policy, and output-surface identity.
- [x] Represent output explicitly as CPU pixels or a platform GPU surface;
  never hide texture ownership behind the current `bk_render` pointer.
- [x] Document buffer/texture lifetime, thread ownership, cancellation, and
  publication rules across Zig, C, and Swift.
- [x] Keep existing `bk_render` behavior frozen for CPU callers.
- [x] Key CPU and GPU cache artifacts separately unless exact equality is
  demonstrated.
- [x] Ensure headless CLI and CI builds do not require Metal.

### 2C.3 Add cancellation, supersession, and memory admission

- [x] Give every visible render request a monotonically increasing generation.
- [x] Prevent an older completed frame from replacing a newer request.
- [x] Add cooperative cancellation at safe stage/tile boundaries.
- [x] Bound queued and in-flight CPU/GPU jobs.
- [x] Reserve memory before admitting a render; include CFA, CPU planes, staging
  buffers, textures, drawable count, scratch, and readback where unavoidable.
- [x] Pause rendering while the app/view is occluded or inactive.
- [x] Keep interactive work ahead of baseline warming, thumbnails, and analysis.

### 2C.4 Build the macOS Metal surface proof

- [x] Create the Metal device and command queue once and cache pipeline states.
- [x] Add an on-demand `MTKView` through `NSViewRepresentable`, using drawable
  pixels rather than point-space bounds.
- [x] Present a test texture directly without `Data`/`CGImage` reconstruction.
- [x] Handle nil devices, nil drawables, resize/backing-scale changes, command
  failure, and device/runtime capability checks with clean CPU fallback.
- [x] Use build-time compiled MSL and stable shader implementation IDs.
- [x] Keep at most two viewer command buffers/drawables in flight initially.
- [x] Avoid blocking waits on the main actor and release drawable references
  promptly.

Metal presentation is now the normal viewer path, with no feature flag. One
cached device and command queue feed an on-demand, two-drawable `MTKView`. The
late-develop path samples the retained RGBA32F linear-Rec.2020 texture directly
through build-time compiled MSL, performs exposure, contrast, working-to-display
matrix conversion, and writes an sRGB drawable without `Data` or `CGImage`
reconstruction. Its stable implementation ID is
`banksia.metal.late-develop-f32.msl1`. Tests execute the compiled pipeline into
a directly allocated texture, cover a known vector and top-row-first orientation,
and verify the implementation ID.

Device/queue/library/allocation/encoding/command failures now activate the
strict CPU renderer for the current file; normal operation remains GPU-first.
Nil drawables retry twice before reporting failure, resize/backing changes request
a fresh drawable-sized frame, and the staged `BANKSIA_INJECT_METAL_FAILURE`
hook keeps every failure boundary reproducible. Its initialization alias (`1`)
exercised an upright real-CR2 CPU fallback in the running app. A
separate `MTL_DEBUG_LAYER=1 MTL_SHADER_VALIDATION=1` launch completed through the
compiled shader with both validation layers enabled and no reported errors.
A five-second Metal System Trace taken after the initial frame contained zero
Banksia command-buffer submissions, confirming that the settled viewer returns
to idle rather than retaining the temporary diagnostic display loop.

The retained-preview engine boundary is now additive and typed end to end.
`bk_render_linear` returns owned RGBA32F linear Rec.2020 pixels after early
sensor/geometry work while preserving `bk_render` byte behavior and lifetime.
Swift identifies that buffer separately from display RGBA8, copies it once into
an owned `Data`, and emits render/copy signposts. Real-RAW smoke measurements
put the edge-1440 base at 75.872 ms p50 for the CR2 reference and 30.484 ms p50
for CR3. The normal viewer now uploads that base once per early-develop
generation to a retained RGBA32F linear-Rec.2020 texture. Exposure and contrast
changes reuse the texture and execute through the compiled Metal pipeline with no
strict-CPU display render on open, during a gesture, or after it settles. Early
white-balance changes invalidate and rebuild only the linear base. The ingestion
boundary performs one tested top-row-first to Core Image origin conversion, so
the Metal drawable is upright.

### 2C.5 Prove a GPU-resident late-develop path

Apple LinearRaw DNG now enters engine-v2 as explicit three-channel linear RGB,
retaining its distinct domain through preview reduction before the shared
linear-Rec.2020 Metal boundary. Bayer CR2/CR3 remains on the sensor-CFA path;
engine-v1 output is unchanged. A selective camera-domain chroma reconstruction
filter suppresses high-frequency false colour before the working-space matrix.

- [x] Upload or share one linear working preview and retain it across late edits.
- [x] Fuse exposure, camera/working matrix where applicable, tone, output colour,
  clipping policy, and display encoding into the fewest measured passes.
- [x] Add GPU scaling and histogram only when they remove an observed CPU pass.
- [x] Keep geometry and crop semantics identical to the strict CPU reference.
- [x] Avoid routine GPU-to-CPU readback for viewer display.
- [x] Measure `rgba32Float` first; evaluate `rgba16Float` only with ΔE, gradient,
  deep-shadow, saturated-colour, and highlight evidence.
- [x] Record upload, encoding, queue, GPU, presentation, and any readback time
  separately from total latency.
- [x] Drive late-develop frames from `CAMetalDisplayLink` rather than an
  asynchronous on-demand `MTKView` draw, while preserving idle behavior and the
  two-drawable bound.

The inspection shell exposes every late-edit interval above and includes a
repeatable 31-presented-frame exposure benchmark. The earlier Core Image proof
recorded 31.505 ms and 30.836 ms p95 input-to-visible, passing the 33 ms gate.
After the compiled-MSL transition, two initial runs recorded 52.5 ms and 52.3 ms
p95 even though shader execution remained only 1.1–1.4 ms p50; synchronized
drawable presentation dominates the tail. This is now an explicit 2C.5
optimization gate, not hidden by the completed 2C.4 architecture proof. See
[the baseline](baseline.md). The compiled path now fuses scaling, exposure,
tone, working-to-output conversion, clipping, and hardware display encoding in
one pass. Histogram stays outside Metal because the GPU viewer has no extra CPU
histogram pass to remove. Precision, adversarial, mandatory-corpus, validation,
and sustained-trace evidence are recorded in
[the conformance report](conformance.md). Presentation remains the open gate.
The late-develop surface now takes its drawable from `CAMetalDisplayLink`, which
removes the main-queue draw hop. It applies drawable-size changes after the
current frame is presented. The 31-frame end-to-visible gate remains unchecked
until it is measured on this presenter.

### 2C.6 Build CPU/GPU conformance and failure coverage

- [x] Compare every mandatory Phase 2B image through CPU and Metal previews.
- [x] Add adversarial gradients, negative/out-of-gamut values, clipped
  highlights, saturated colours, deep shadows, odd dimensions, and borders.
- [x] Report mean, median, p95, and maximum ΔE00 plus SSIM and finite-output
  status.
- [x] Verify CPU fallback after Metal initialization, allocation, shader,
  command-buffer, and drawable failures.
- [x] Verify backend cache separation and stale-frame suppression.
- [x] Stress resize, rapid slider changes, open/close, display changes, memory
  pressure, and repeated render loops without leaks or deadlocks.
- [x] Run a sustained thermal/energy trace rather than a short burst only.

### 2C.7 Make and record the investment decision

- [x] Compare optimized CPU, CPU-to-`CGImage`, hybrid Metal, and GPU-resident
  presentation end to end.
- [x] Apply the default-backend decision against the exit gates; retain direct
  MSL by explicit project decision with the 33 ms and 2× misses recorded.
- [x] Evaluate the CPU-path alternative after the Metal misses; retain it as the
  oracle/failure path because its core-only lower bound reaches
  35.547–98.225 ms p95 before `CGImage` work.
- [x] Move only the measured presentation-driver follow-up into Branch C.
- [x] Record deviations, supported GPU/runtime envelope, and fallback policy in
  [the investment decision](investment-decision.md).

## Tests

- [x] Existing CPU golden, corpus, ABI, CLI, and shell gates remain green.
- [x] Performance telemetry unit tests use deterministic timestamps where
  practical.
- [x] Generation ordering rejects stale completion.
- [x] Queue and memory admission remain bounded under randomized request bursts.
- [x] Metal shader known vectors match the CPU reference.
- [x] Full CPU/Metal perceptual corpus report.
- [x] Nil-device and injected Metal failure fallback.
- [x] Retina/non-Retina resize and display-change behavior.
- [x] No work continues while the on-demand viewer is static or occluded.
- [x] Repeated open/edit/close and memory-pressure leak soak.

## Exit criteria

- [ ] Baseline and final p50/p95/p99 reports cover every named workload.
- [ ] Cached late adjustment is ≤ 33 ms p95 end to visible; ≤ 16.7 ms is the
  stretch target on the M3 reference machine.
- [x] Once RAW decode completes, a developed edge-1440 preview is visible in
  ≤ 100 ms p95.
- [ ] Cached or embedded first-visible culling preview remains ≤ 250 ms p95.
- [ ] The accelerated late-develop slice is at least 2× faster at p95 than the
  equivalent optimized CPU-to-`CGImage` path, including presentation overhead.
- [x] GPU mean ΔE00 is ≤ 0.5 against strict CPU, with p95 and maximum reported;
  no visible gradient, highlight, clipping, or geometry regression is accepted.
- [x] Viewer presentation performs no routine GPU-to-CPU readback.
- [x] Static-view GPU utilization returns to idle and no obsolete frame is
  displayed.
- [ ] Peak combined CPU/GPU memory remains within the recorded 8 GB reference
  machine budget with at least 1 GiB application/system headroom.
- [x] CPU fallback passes all supported files when Metal is unavailable or an
  injected GPU operation fails.
- [x] Strict CPU artifacts and all engine-v1 hashes remain unchanged.

## Risks

- A fast shader can hide slow upload, readback, packing, or UI publication.
- Full-resolution float textures can exhaust an 8 GB machine quickly.
- GPU precision and operation ordering can alter colour or historical output.
- A second backend can double maintenance without improving a user workflow.
- Continuous display loops can waste energy for an otherwise static editor.
- Premature heaps, queues, and synchronization can add complexity and latency.
- Swift/Zig/Metal ownership ambiguity can leak or display stale resources.

## Non-goals

- Metal-only rendering.
- GPU RAW container parsing or storage work.
- Replacing the strict CPU renderer as the historical oracle.
- Porting every current or future operation before profiling.
- GPU demosaic, denoise, sharpening, masks, or export in the first proof.
- Treating shader duration as end-to-visible performance.
- Sessions, import, culling workflow, or user-facing global-develop breadth.

---

[Back to the roadmap](../../plan.md) · [Shared phase rules](../README.md) ·
[Deeper acceleration branch](../branch-c-performance-metal/plan.md)
