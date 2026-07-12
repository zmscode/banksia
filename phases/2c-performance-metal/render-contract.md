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

The current implementation is `banksia.cpu.strict-f32.v2` producing copied
RGBA8 sRGB CPU output. A Metal candidate receives a different implementation ID
and output identity even when it consumes the same recipe.

## Ownership and lifetime

- The `Renderer` actor exclusively owns one C engine handle and serializes all
  calls that can invalidate its internal render buffer.
- The existing CPU result copies the engine-owned RGBA buffer into `Data` before
  constructing a `CGImage`; the published image never aliases the next render.
- A request is immutable and `Sendable`. Its completed image and timing remain
  owned by the result until the main actor either publishes or discards them.
- The future Metal result must retain a texture or surface through command-buffer
  completion and presentation, then release drawable references promptly. It
  must not disguise GPU ownership as a CPU pointer.
- `bk_render` and its pointer lifetime remain unchanged for existing callers.

## Supersession and publication

Issuing a visible request advances the publication generation. Opening another
asset advances it as well, immediately invalidating outstanding results. The
main actor publishes a completed frame, its timings, dimensions, and histogram
generation only when the completed generation equals the newest issued value.
Errors from obsolete requests are discarded by the same rule.

The CPU kernel is still synchronous and cannot yet stop safely mid-stage.
Supersession therefore guarantees visual correctness now; cooperative stage or
tile cancellation remains separate work. At most one main-view CPU render is
executing and one immutable main-view request is retained for coalescing. The
baseline and thumbnail lanes still need explicit admission and priority policy.

## Cache and reproducibility

An artifact key must include the renderer implementation ID, engine version,
precision, output kind, canonical recipe identity, source identity, and output
geometry. CPU and Metal artifacts cannot share keys unless a later proof records
exact equality and deliberately unifies their execution contracts.
