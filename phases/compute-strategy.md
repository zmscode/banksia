# Compute strategy — SIMD, concurrency, multithreading, and Metal

> Banksia should use parallelism aggressively where work is independent, but it
> should not make every subsystem concurrent. The governing constraints are
> interaction latency, memory bandwidth, peak memory, cancellation, durability,
> and reproducibility—not raw thread count.

[Back to the roadmap](../plan-v2.md) · [Shared phase rules](README.md)

---

## Recommendation in one page

Use a layered strategy:

1. **SIMD inside deterministic kernels.** Continue using `@Vector` for black
   level, gains, curves, transforms, packing, resize, and analysis kernels where
   profiling supports it.
2. **Bounded parallelism across assets.** Use independent jobs for thumbnails,
   metadata extraction, hashing, verification, analysis, and export.
3. **A single-writer catalog path.** Prepare work concurrently, but serialize
   WAL/catalog commits so acknowledgement order and recovery stay simple.
4. **Tiled multithreading inside one image only when required.** Add it after the
   real-camera CPU reference path is stable and prove invariance across thread
   counts and tile sizes.
5. **One global scheduler, no nested pools.** The scheduler decides whether to
   spend concurrency on several photos or several tiles of one photo.
6. **Memory-aware admission.** A 24MP RGB f32 image is roughly 288 MiB before
   scratch and output. Concurrency must consume memory tokens, not merely CPU
   slots.
7. **Priority and cancellation are product features.** Visible preview work must
   supersede off-screen thumbnails, cache warming, verification, and export.
8. **Strict CPU is canonical.** Historical verification and golden rendering use
   the strict CPU backend.
9. **Metal is evidence-gated.** Add it only after preview-resolution processing,
   CPU fusion, cache reuse, and cancellation still miss a measured objective.
10. **Separate CPU/GPU identities unless exactness is proven.** Perceptually
    equivalent output is useful, but it is not bit-identical output.

This gives Banksia useful parallelism early without making storage recovery,
render determinism, or memory behavior unmanageable.

---

## Why this shape fits a RAW editor

Banksia has two different kinds of parallel work:

### Across photos

Examples:

- metadata extraction;
- content hashing and copying;
- embedded-preview extraction;
- thumbnail generation;
- burst/focus analysis;
- session verification;
- batch export.

These jobs are largely independent and naturally cancellable. Asset-level
parallelism should be the first broad concurrency layer.

### Within one photo

Examples:

- demosaic tiles;
- colour transforms;
- convolution/local contrast;
- resize;
- denoise;
- output packing.

This improves the latency of the currently visible photo, but increases
coordination, scratch memory, halo handling, and determinism requirements. Add it
only after the scalar/SIMD reference is correct.

A global scheduler must choose between these layers. Running eight photos with
eight tile workers each is oversubscription, not performance.

---

## Proposed ownership model

### Orchestration layer owns concurrency

`banksia` should own the process-wide scheduler and priorities.

`emu` should expose deterministic render operations that can execute:

- synchronously on the caller thread;
- as a planned set of tiles through a provided executor;
- with an explicit cancellation token;
- with caller-provided memory/scratch budgets.

`wombat` should keep disk state transitions explicit and should not create hidden
worker pools.

`lyrebird` should expose analysis jobs over immutable preview data and should use
the same process scheduler.

### Do not make the existing engine handle globally thread-safe

The current C ABI contract—one engine handle owned by one actor—is appropriate
for the inspection shell.

For the product application:

- use immutable decoded inputs, recipes, and profiles;
- create independent render contexts or jobs;
- serialize each individual handle/context;
- let the scheduler run multiple contexts;
- avoid adding a large lock around one shared engine, which would preserve the
  bottleneck while making ownership less clear.

### Single scheduler sketch

A future scheduler can conceptually expose:

```zig
const Priority = enum {
    interactive_preview,
    visible_thumbnail,
    loupe,
    near_viewport_thumbnail,
    user_export,
    import_preview,
    background_analysis,
    cache_warm,
    verification,
};

const JobBudget = struct {
    cpu_slots: u16,
    memory_bytes: u64,
    io_weight: u8,
    gpu_bytes: u64,
};

const CancellationToken = struct {
    // Monotonic generation or atomic cancelled flag.
};
```

This is a design direction, not a request to add a generic framework now.
Introduce only the pieces required by the current phase.

---

## Scheduling rules

### Priority order

Recommended default order:

1. currently dragged interactive preview;
2. selected-image loupe or full-quality preview;
3. visible thumbnails;
4. next/previous prefetch and near-viewport thumbnails;
5. user-started export;
6. import previews;
7. background analysis;
8. cache warming;
9. full verification.

User-started export should make steady progress, but it should not make culling or
slider input unresponsive.

### Supersession

- A new slider state cancels or supersedes the previous preview job.
- Scrolling cancels thumbnails outside the prefetch window.
- A new selected image cancels the old loupe render.
- Closing a session cancels all derived jobs before releasing session state.
- Cancellation does not interrupt a durability transition halfway through its
  critical section.

### Backpressure

Every queue is bounded.

- Thumbnail requests are deduplicated by render key.
- Repeated requests attach waiters to one job.
- Import may pause source discovery when write/hash queues are full.
- Tethering may drop obsolete preview jobs but never source transfers.
- Export worker count decreases when measured per-render memory rises.

### Fairness

- Interactive work preempts background admission, not necessarily a filesystem
  fsync already in progress.
- Long exports receive bounded slices so they cannot starve indefinitely.
- Verification yields to interactive and import work.
- Background cache warming stops under memory pressure or battery policy.

---

## Memory-aware parallelism

CPU count alone is the wrong admission metric.

A 24MP RGB f32 frame is about 288 MiB. The current pipeline also allocates a
mosaic, output, downsample buffers, and allocator metadata. Advanced operations
may require halo or multiple planes.

### Required measurements

For every render class, record:

- source dimensions;
- decoded sensor bytes;
- live plane bytes;
- scratch bytes;
- output bytes;
- cache-read/write buffers;
- peak resident memory;
- bytes read/written per stage.

### Memory tokens

Each admitted job reserves an estimated memory budget before starting.

Examples:

- embedded-preview extraction: small token;
- metadata parse: small token;
- preview demosaic: medium token;
- full-resolution develop: large token;
- denoise or local contrast: very large token;
- export encoder: output-dependent token.

If two full renders exceed the configured budget, run one even when many CPU
cores are idle. Predictable responsiveness is preferable to swap pressure.

### Default policy

- Keep a configurable process memory ceiling.
- Reserve headroom for SwiftUI, encoded thumbnails, catalog data, and macOS.
- Size export concurrency from measured peak memory, not `cpu_count`.
- Prefer preview-resolution jobs when the user is interacting.
- Drop cache warming first under pressure.

---

## SIMD guidance

SIMD is already appropriate and should continue before broad threading.

### Good SIMD targets

- black-level subtraction and normalization;
- white-balance and exposure gain;
- matrix colour transforms;
- tone and transfer curves;
- gamut/clipping policy;
- luma extraction;
- resize accumulation where bins permit it;
- image packing and format conversion;
- Hamming/popcount scans for perceptual hashes;
- simple convolution rows after correctness is established.

### Less straightforward targets

- edge-aware demosaic with irregular neighbourhood decisions;
- variable-size horizontal resize bins;
- entropy decoders;
- TIFF/metadata parsing;
- WAL and catalog mutation.

Do not contort control-heavy code into SIMD without a measured benefit. Preserve
scalar tails and odd-dimension tests.

---

## CPU multithreading by phase

### Phase 2A — storage closure

Keep catalog mutation and compaction orchestration serial.

Useful parallelism:

- CI may shard independent simulator seeds across processes;
- benchmark fixture generation may be parallel outside timed sections.

Do not parallelize WAL application or mutation acknowledgement before the
single-threaded durability model is proven.

### Phase 2B — real-camera correctness

Keep one render synchronous as the reference.

Useful work:

- SIMD colour transforms;
- parallel corpus cases at the test-runner level;
- fuzz workers as separate seeded processes.

Do not add a tile thread pool merely to improve a headline number while colour
and geometry semantics are changing.

### Phase 2C — sessions and import

Use a bounded pipeline:

```text
source discovery
→ read/hash/copy workers
→ metadata workers
→ single ordered catalog commit
→ low-priority preview queue
```

Recommendations:

- one source-discovery producer;
- a small number of I/O/hash workers, measured per storage medium;
- metadata extraction across independent files;
- one catalog/WAL writer;
- no import acknowledgement until object and catalog ordering is satisfied.

More workers can reduce throughput on one removable card by causing seeks or
queueing. Measure 1, 2, and 4 workers before choosing defaults.

### Phase 3 — culling

This is where scheduler quality first becomes a product feature.

Use:

- bounded thumbnail workers;
- visible/near/background priorities;
- cancellation and stale-result suppression;
- one deduplicated job per thumbnail key;
- multiple independent render contexts rather than one locked handle.

Embedded preview extraction should usually beat multithreaded full RAW rendering
for initial culling latency.

### Phase 4 — global develop

Add intra-image tiling only if the preview/full-render budgets are missed after:

1. preview-resolution decode/demosaic;
2. removing unnecessary full-frame copies;
3. op fusion;
4. cache prefix reuse;
5. buffer-lifetime improvements.

When tiling lands:

- define halo and border policy per operation;
- use deterministic tile output regions;
- avoid reductions whose order changes floating-point output;
- test 1, 2, 4, and maximum worker counts;
- test several tile sizes;
- require exact strict-CPU output invariance.

### Phase 5 — export

Parallelize across photos first.

For a batch, use either:

- several photos with one CPU slot each; or
- fewer photos whose individual renders use multiple tiles.

The scheduler chooses based on memory and measured throughput. Do not nest an
N-photo pool over an N-thread render pool.

Reuse one developed result for multiple output recipes when its memory cost is
acceptable. Otherwise reuse cache prefixes and process outputs sequentially.

### Phases 6–8

Use soak tests to tune defaults. Preserve the same scheduler and avoid separate
pools owned by import, export, thumbnails, analysis, and history.

---

## Determinism under threading

The strict CPU backend should produce identical bytes across supported:

- thread counts;
- tile sizes;
- scheduling order;
- cancellation of unrelated jobs.

### How to retain determinism

- Give each tile a disjoint output region.
- Define halo reads without overlapping writes.
- Avoid unordered floating-point reductions.
- If a reduction is required, use a fixed reduction tree/order.
- Keep random or noise generation coordinate-based and seed-explicit.
- Do not use wall time or worker identity as pixel input.
- Make planner and implementation IDs part of renderer semantics where they can
  affect output.

Thread count and tile size should not enter the strict cache key if exact
invariance is proven. If they affect output, the implementation is not yet a
strict canonical backend.

---

## GPU and Metal recommendation

### Use Metal eventually, not immediately

Metal is well suited to:

- pointwise colour and tone transforms;
- matrix/LUT operations;
- demosaic once validated;
- resize;
- convolution/local contrast;
- mask composition;
- GPU-resident interactive previews.

Metal is not useful for:

- TIFF/RAW container parsing;
- catalog/WAL persistence;
- content hashing and filesystem durability;
- most metadata work;
- migration logic;
- correctness of import transactions.

### Entry conditions

Do not begin production Metal work until:

- real-camera CPU output is correct;
- a true preview-resolution path exists;
- render jobs are cancellable;
- cache identity is correct;
- CPU copies/traversals have been profiled;
- CPU fusion/tiling has been evaluated;
- a named p95 interaction target is still missed because of compute.

### Proof strategy

1. Profile representative 24MP preview, loupe, and export workloads.
2. Select the single dominant kernel.
3. Implement only that kernel in Metal.
4. Keep strict CPU as the oracle.
5. Measure end-to-end latency including upload, command submission, readback,
   and SwiftUI presentation.
6. Report ΔE00, SSIM, worst-case error, clipping, and NaN/Inf behavior.
7. Test sustained thermal behavior.
8. Invest only if p95 improves materially, with an initial target of at least
   2× for the accelerated slice.

### GPU-resident preview

The largest Metal win may come from avoiding readback rather than shader speed.
A later product path can keep preview planes/textures on the GPU through display.

That requires a different API from the current RGBA pointer contract. Do not
force this through `bk_render` by adding hidden ownership. Design an explicit
texture/surface interop path when the proof demonstrates value.

### CPU/GPU identity

- Strict CPU artifacts use the canonical execution-contract ID.
- Metal artifacts use a GPU execution-contract ID unless exact bytes are proven.
- Record GPU family, shader implementation, precision, and relevant OS/runtime.
- Never let an approximate GPU preview overwrite a canonical CPU proof artifact.
- A GPU preview can still be deterministic per declared device/runtime envelope.

### f16 policy

Use f16 only where measured quality permits it.

- Keep colour-critical or high-dynamic-range stages f32 by default.
- Test gradients, saturated colours, deep shadows, and highlight roll-off.
- Report worst-case error, not only mean ΔE.
- Store the precision policy in renderer identity.

---

## I/O parallelism

Hashing and copying are constrained by the source and destination devices.

- One SD card often benefits from a small queue, not many readers.
- Source and destination on separate fast SSDs may benefit from deeper
  pipelining.
- Hash while streaming to avoid a second read.
- Keep object publication and catalog acknowledgement ordered.
- Bound outstanding write bytes.
- Do not let background verification compete with interactive import unless the
  user explicitly starts it.

Benchmark worker counts by source class rather than selecting one universal
number.

---

## Catalog and storage concurrency

Recommended initial model:

- many readers over immutable snapshots/columns;
- one writer actor for WAL and in-memory catalog mutations;
- immutable or generation-pinned query views;
- compaction coordinated by the writer;
- no multi-process writer support.

This keeps crash recovery and acknowledgement semantics understandable. If a
future profile proves the writer is a bottleneck, batch adjacent rating/flag
mutations into one fsync while preserving user-visible transaction boundaries.
Do not begin with lock-free catalog mutation.

---

## Export concurrency

The export scheduler should consider:

- per-render peak memory;
- decoder and demosaic cost;
- output codec cost;
- destination throughput;
- number of output recipes;
- thermal state during long runs.

Recommended initial policy:

- parallelize photos up to the memory budget;
- keep each photo render single-threaded or low-thread-count during a broad
  batch;
- increase intra-photo threads for a one-photo export or when batch width is
  small;
- fan one developed image into several output encoders when memory permits;
- keep UI previews at higher priority than export admission.

Success is photos/minute and responsiveness, not 100% CPU utilization by itself.

---

## Analysis concurrency

`lyrebird` jobs are good background tasks:

- luma thumbnail generation;
- dHash/pHash calculation;
- pairwise scans;
- focus tiles;
- burst clustering.

Use CPU SIMD and asset-level parallelism first. Persist algorithm identity with
derived data. Pause or lower priority during interactive work. Smart analysis
must never block source import acknowledgement or manual culling.

---

## Testing the scheduler

Required properties:

- bounded queue lengths;
- bounded memory reservations;
- high-priority work starts within a measured latency;
- cancelled jobs cannot publish stale artifacts;
- duplicate render keys produce one computation;
- session close drains or cancels all owned jobs;
- durability critical sections are not abandoned halfway;
- no deadlocks under random cancellation and failure;
- deterministic strict output under scheduling variation;
- export and background tasks make bounded progress without starving UI work.

Use a deterministic fake executor for unit tests and real-thread stress tests for
race detection and soak behavior.

---

## Recommended implementation order

1. Keep current synchronous CPU render as reference.
2. Add semantic recipe validation before further concurrency.
3. Add a small cancellation token and generation-based stale-result suppression
   for the shell.
4. Add bounded asset jobs for Phase 2C import.
5. Introduce one session-owned scheduler for Phase 3 thumbnails.
6. Add priorities, deduplication, and memory admission as real workloads require.
7. Add preview-resolution decode/demosaic.
8. Profile and fuse CPU passes.
9. Add deterministic tiled CPU execution only if budgets are still missed.
10. Parallelize export through the same scheduler.
11. Run the Metal proof only after the Branch C entry gate passes.

---

## Final advice

Yes, Banksia should use parallel processing and eventually may benefit strongly
from Metal. The mistake would be to treat “multithreaded” or “GPU-first” as an
architecture goal independent of the workflow.

The best near-term return is:

- SIMD within kernels;
- embedded/low-resolution previews;
- bounded jobs across photos;
- cancellation and priority;
- one ordered catalog writer;
- memory-aware export concurrency.

The best later return is:

- fused/tiled CPU rendering for the selected image;
- a GPU-resident preview path for measured hot operations;
- strict separation between canonical CPU artifacts and accelerated GPU
  artifacts.

That approach preserves Banksia's strongest differentiators—determinism,
recovery, and inspectable rendering—while still using modern hardware where it
actually improves the product.
