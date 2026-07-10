# Phase 7 — studio: tethered capture

> **Objective:** The workflow Capture One owns and nothing open-source
> does well: camera → cable → instant render. Sessions (Phase 2) were
> built for this.
>
> **Definition of done:** A supported camera shoots tethered into a live
> session: frame lands, imports, renders with the session's default
> recipe, and appears in the grid in under 2 seconds, hands-free.

**Status: not started.** Requires Phase 2 (sessions, import path); the
shell pieces assume Phase 4's grid. Independent of Phases 5–6 — can pull
forward for a studio-first strategy.

## 1. PTP transport

- [ ] PTP/USB via IOKit (macOS) behind a comptime transport interface;
      one camera family first — whichever the developer owns (decide and
      record here).
- [ ] PTP protocol core: session open/close, event channel, object-added
      events, GetObject transfer. Bounded buffers throughout; the
      transport is untrusted input (errors, never asserts — same
      discipline as the decoders).
- [ ] PTP/IP second (same protocol core, socket transport) — it also
      gives the simulator a clean seam.

## 2. The simulated camera (test substrate first)

- [ ] `tether/sim_camera.zig`: emits object-added events and serves
      synthetic DNGs through the same transport interface; seeded timing
      jitter, disconnects, mid-transfer drops via `Ratio` probabilities.
- [ ] The flaky-transport suite is the phase's crash-sim: no event loss
      without detection, no torn file ever reaches the vault (wombat's
      write discipline already guarantees the second half — assert the
      pair anyway).

## 3. Live ingest path

- [ ] Capture event → GetObject → wombat import (hash, dedup, blob) →
      emu preview render → catalog append → grid update, as one streaming
      path with backpressure (a burst of 20 frames must not balloon
      memory; bounded queue, oldest-preview-first eviction).
- [ ] Session default recipe: new frames inherit the shoot's develop
      settings; changing it re-renders previews for prior frames in the
      background (cache makes this cheap).
- [ ] Latency instrumentation: shutter-event → grid-visible, printed per
      frame in a debug HUD; the exit criterion is measured, not vibes.

## 4. Studio shell features

- [ ] Live view pane: newest frame full-screen, grid rail alongside.
- [ ] Overlay/compare: pin a reference frame (or imported comp image),
      blend/onion-skin the live frame against it — the layout-matching
      use case.
- [ ] Tether status UI: connected camera, frames this session, last
      transfer ms; disconnect/reconnect without losing the session.

## Tests

- PTP protocol unit tests against recorded transcripts (golden
  request/response bytes per camera family).
- Sim-camera flaky-transport suite (seeded, in CI) — the hard gate.
- Ingest backpressure property: 100-frame synthetic burst, bounded peak
  memory asserted.
- End-to-end latency measured against the sim camera in CI (generous
  bound; the real-camera number is recorded here manually).

## Exit criteria

- [ ] Sim camera: event → grid in < 500ms in CI (record: ___).
- [ ] Real camera: shutter → grid in < 2s hands-free (record camera and
      number: ___).
- [ ] Disconnect mid-transfer: session recovers, no partial file, no
      lost prior frames — proven by the flaky suite.

## Learnings

*(recorded as the phase runs)*
