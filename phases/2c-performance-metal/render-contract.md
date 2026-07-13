# Phase 2C render contract

This contract is the boundary between user intent, Banksia's strict CPU oracle,
and the Metal candidate. It begins in the macOS inspection shell and will move
down to the shared engine boundary as GPU surfaces become real outputs.

## Image domains

Pixels belong to exactly one named domain:

1. `sensorCFA`: one filtered sensor sample per photosite, before demosaic;
2. `cameraRGB`: demosaiced linear values in the camera's native primaries;
3. `linearWorkingRGB`: linear values transformed into Banksia's working space;
4. `developedLinearRGB`: working values after scene-referred develop operations;
5. `displayEncodedRGB`: clipped and transfer-encoded display output.

Code must not infer a domain from dimensions, channel count, texture format, or
backend. A future texture descriptor carries this domain explicitly.

## Immutable request

Every visible request snapshots:

- a monotonically increasing generation;
- canonical recipe JSON;
- requested longest output edge;
- render intent (interactive, settled, baseline, thumbnail, compatibility);
- renderer implementation ID, engine version, backend, and precision policy;
- requested CPU or platform-GPU output kind.

The strict develop implementation is `banksia.cpu.strict-f32.v2`, producing a
copied RGBA8 sRGB CPU image. The normal macOS viewer also requests an explicitly
typed RGBA32F linear-Rec.2020 preview, uploads it into a retained Metal texture,
and applies the late exposure/contrast slice on the GPU. That candidate has a
separate execution/output identity; presenting the strict CPU image through
Metal does not relabel the CPU artifact as Metal-developed.

## Ownership and lifetime

- The `Renderer` actor exclusively owns one C engine handle and serializes all
  calls that can invalidate its internal render buffer.
- The existing CPU result copies the engine-owned RGBA buffer into `Data` before
  constructing a `CGImage`; the published image never aliases the next render.
- The additive `bk_render_linear` result is a distinct engine-owned RGBA32F
  linear-Rec.2020 buffer. Its lifetime ends only at the next linear render on
  that handle or engine destruction; it does not invalidate `bk_render` output.
  Swift copies it once into an explicitly identified linear-working CPU result.
- A request is immutable and `Sendable`. Its completed image and timing remain
  owned by the result until the main actor either publishes or discards them.
- The Metal coordinator owns the RGBA32F texture. It replaces it only when the
  published linear-preview generation changes and
  retains them across late exposure/contrast edits. Early white-balance changes
  invalidate and rebuild only the linear base.
- The engine buffer is top-row-first. Texture ingestion applies exactly one
  vertical origin conversion in the fullscreen MSL texture coordinates; a
  two-row direct-texture GPU regression
  test guards against upside-down presentation.
- Each submitted command buffer retains the source and drawable through GPU
  completion. Completion releases the drawable promptly; at most two viewer
  frames are in flight, and a saturated renderer remembers only the newest
  retry request.
- A Metal result must not disguise GPU ownership as a CPU pointer.
- Metal is the default presentation route. If device, queue, compiled library,
  texture allocation, command encoding, repeated drawable acquisition, or GPU
  command execution fails, the controller requests a strict CPU display artifact
  and SwiftUI presents that `CGImage` without requiring Metal. The explicit
  `BANKSIA_INJECT_METAL_FAILURE=<stage>` test hook makes this path reproducible
  without changing normal routing. Stages are `initialization`, `allocation`,
  `shader`, `commandBuffer`, `drawable`, and `completion`; the legacy value `1`
  aliases initialization.
- `bk_render` and its pointer lifetime remain unchanged for existing callers.

## Supersession and publication

Issuing a visible request advances the publication generation. Opening another
asset advances it as well, immediately invalidating outstanding results. The
main actor publishes a completed frame, its timings, dimensions, and histogram
generation only when the completed generation equals the newest issued value.
Errors from obsolete requests are discarded by the same rule.

The CPU kernel remains synchronous, but the admitted linear call now carries a
borrowed cancellation callback and checks it between expensive safe stages.
Supersession guarantees visual correctness while cancellation bounds obsolete
work. At most one main-view CPU render is
executing and one immutable main-view request is retained for coalescing.
Opening another file cancels the prior load task, and actor entry points reject
cancelled work before touching the engine. The baseline lane admits one task.
The thumbnail lane has one worker and at most 12 pending visible-cell requests;
offscreen pending work is removed. The viewer admits two Metal command buffers
and coalesces saturation into one newest-frame retry.

Before the linear call allocates pipeline memory, it computes a conservative
combined estimate covering retained CFA data, preview CFA, f32 mosaic and CPU
planes, transformed/downsampled planes, Swift-owned RGBA32F, the Metal texture,
two display drawables, and scratch. The inspection shell admits that estimate
against an exclusive budget capped at 1.5 GiB while preserving 1 GiB of physical
headroom. An undersized budget fails before allocation.

Inactive scenes cancel current linear work and retain only the newest request
for resume. The Metal view also refuses drawable work while its window is
occluded or the app is inactive. Thumbnail admission pauses whenever interactive
main-view work is active, so background analysis cannot get ahead of editing.

## Cache and reproducibility

An artifact key must include the renderer implementation ID, engine version,
precision, output kind, canonical recipe identity, source identity, and output
geometry. CPU and Metal artifacts cannot share keys unless a later proof records
exact equality and deliberately unifies their execution contracts.

`RenderArtifactKey` enforces that contract in code. Its hash includes source
and recipe identities, requested and actual geometry, plus the complete
execution contract. Tests prove otherwise-identical strict-display,
strict-linear, and Metal-developed artifacts occupy three distinct keys.
