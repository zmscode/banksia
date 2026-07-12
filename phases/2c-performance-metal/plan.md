# Phase 2C — performance architecture and Metal proof

**Status:** current
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
- Existing synchronous CPU renderer and seven-function C ABI.
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

- [ ] Instrument cold load/decode, recipe update, core render, output packing,
  engine-buffer copy, image/surface construction, histogram/overlay work, and
  input-to-visible presentation separately.
- [ ] Emit Instruments-compatible signposts for the same intervals.
- [ ] Record p50/p95/p99 rather than one warm sample.
- [ ] Name hardware, OS, build mode, corpus revision, dimensions, cache state,
  peak memory, and thermal test duration.
- [ ] Benchmark CR2 and CR3 cold open, edge-1024/1440 preview, full render, late
  slider edit, slider release, loupe, and cached/uncached thumbnail workloads.
- [ ] Count full-frame traversals and CPU copies per workload.
- [x] Add a repeatable shell benchmark or trace-capture command.

Implementation started 2026-07-12. The inspection shell now separates RAW
load/decode, recipe update, core render, engine-buffer copy, and `CGImage`
construction, with matching Instruments points-of-interest signposts. The
ReleaseFast `raw-bench` harness now reports nearest-rank p50/p95/p99 and accepts
up to 101 samples. See [the seed baseline](baseline.md); presentation,
histogram/overlay, packing, memory, thermal, and longer workload captures remain.

### 2C.2 Define backend-independent render domains and ownership

- [ ] Separate sensor CFA, camera RGB, linear working image, developed image,
  and display output as explicit domains.
- [ ] Define immutable render request, renderer manifest, execution contract,
  render intent, precision policy, and output-surface identity.
- [ ] Represent output explicitly as CPU pixels or a platform GPU surface;
  never hide texture ownership behind the current `bk_render` pointer.
- [ ] Document buffer/texture lifetime, thread ownership, cancellation, and
  publication rules across Zig, C, and Swift.
- [ ] Keep existing `bk_render` behavior frozen for CPU callers.
- [ ] Key CPU and GPU cache artifacts separately unless exact equality is
  demonstrated.
- [ ] Ensure headless CLI and CI builds do not require Metal.

### 2C.3 Add cancellation, supersession, and memory admission

- [ ] Give every visible render request a monotonically increasing generation.
- [ ] Prevent an older completed frame from replacing a newer request.
- [ ] Add cooperative cancellation at safe stage/tile boundaries.
- [ ] Bound queued and in-flight CPU/GPU jobs.
- [ ] Reserve memory before admitting a render; include CFA, CPU planes, staging
  buffers, textures, drawable count, scratch, and readback where unavoidable.
- [ ] Pause rendering while the app/view is occluded or inactive.
- [ ] Keep interactive work ahead of baseline warming, thumbnails, and analysis.

### 2C.4 Build the macOS Metal surface proof

- [ ] Create the Metal device and command queue once and cache pipeline states.
- [ ] Add an on-demand `MTKView` through `NSViewRepresentable`, using drawable
  pixels rather than point-space bounds.
- [ ] Present a test texture directly without `Data`/`CGImage` reconstruction.
- [ ] Handle nil devices, nil drawables, resize/backing-scale changes, command
  failure, and device/runtime capability checks with clean CPU fallback.
- [ ] Use build-time compiled MSL and stable shader implementation IDs.
- [ ] Keep at most two viewer command buffers/drawables in flight initially.
- [ ] Avoid blocking waits on the main actor and release drawable references
  promptly.

### 2C.5 Prove a GPU-resident late-develop path

- [ ] Upload or share one linear working preview and retain it across late edits.
- [ ] Fuse exposure, camera/working matrix where applicable, tone, output colour,
  clipping policy, and display encoding into the fewest measured passes.
- [ ] Add GPU scaling and histogram only when they remove an observed CPU pass.
- [ ] Keep geometry and crop semantics identical to the strict CPU reference.
- [ ] Avoid routine GPU-to-CPU readback for viewer display.
- [ ] Measure `rgba32Float` first; evaluate `rgba16Float` only with ΔE, gradient,
  deep-shadow, saturated-colour, and highlight evidence.
- [ ] Record upload, encoding, queue, GPU, presentation, and any readback time
  separately from total latency.

### 2C.6 Build CPU/GPU conformance and failure coverage

- [ ] Compare every mandatory Phase 2B image through CPU and Metal previews.
- [ ] Add adversarial gradients, negative/out-of-gamut values, clipped
  highlights, saturated colours, deep shadows, odd dimensions, and borders.
- [ ] Report mean, median, p95, and maximum ΔE00 plus SSIM and finite-output
  status.
- [ ] Verify CPU fallback after Metal initialization, allocation, shader,
  command-buffer, and drawable failures.
- [ ] Verify backend cache separation and stale-frame suppression.
- [ ] Stress resize, rapid slider changes, open/close, display changes, memory
  pressure, and repeated render loops without leaks or deadlocks.
- [ ] Run a sustained thermal/energy trace rather than a short burst only.

### 2C.7 Make and record the investment decision

- [ ] Compare optimized CPU, CPU-to-`CGImage`, hybrid Metal, and GPU-resident
  presentation end to end.
- [ ] Make the Metal viewer default only if the exit gates pass.
- [ ] If Metal misses the gates, retain the backend contract and ship the fastest
  measured CPU path rather than preserving GPU code for its own sake.
- [ ] Move only measured follow-up kernels into Branch C.
- [ ] Record deviations, supported GPU/runtime envelope, and fallback policy.

## Tests

- [ ] Existing CPU golden, corpus, ABI, CLI, and shell gates remain green.
- [ ] Performance telemetry unit tests use a deterministic fake clock where
  practical.
- [ ] Generation ordering rejects stale completion.
- [ ] Queue and memory admission remain bounded under randomized request bursts.
- [ ] Metal shader known vectors match the CPU reference.
- [ ] Full CPU/Metal perceptual corpus report.
- [ ] Nil-device and injected Metal failure fallback.
- [ ] Retina/non-Retina resize and display-change behavior.
- [ ] No work continues while the on-demand viewer is static or occluded.
- [ ] Repeated open/edit/close and memory-pressure leak soak.

## Exit criteria

- [ ] Baseline and final p50/p95/p99 reports cover every named workload.
- [ ] Cached late adjustment is ≤ 33 ms p95 end to visible; ≤ 16.7 ms is the
  stretch target on the M3 reference machine.
- [ ] Once RAW decode completes, a developed edge-1440 preview is visible in
  ≤ 100 ms p95.
- [ ] Cached or embedded first-visible culling preview remains ≤ 250 ms p95.
- [ ] The accelerated late-develop slice is at least 2× faster at p95 than the
  equivalent optimized CPU-to-`CGImage` path, including presentation overhead.
- [ ] GPU mean ΔE00 is ≤ 0.5 against strict CPU, with p95 and maximum reported;
  no visible gradient, highlight, clipping, or geometry regression is accepted.
- [ ] Viewer presentation performs no routine GPU-to-CPU readback.
- [ ] Static-view GPU utilization returns to idle and no obsolete frame is
  displayed.
- [ ] Peak combined CPU/GPU memory remains within the recorded 8 GB reference
  machine budget with at least 1 GiB application/system headroom.
- [ ] CPU fallback passes all supported files when Metal is unavailable or an
  injected GPU operation fails.
- [ ] Strict CPU artifacts and all engine-v1 hashes remain unchanged.

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
