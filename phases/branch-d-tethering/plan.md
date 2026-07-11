# Branch D — tethered capture

### Hypothesis

A reliable one-camera tethered ingest workflow provides enough studio value to
justify ongoing hardware-specific support.

This branch depends on Phase 2C sessions and may be explored before Phase 8, but
it must not derail the completed-shoot path.

### Discover

- [ ] Select one physically available camera model.
- [ ] Determine whether standard PTP, vendor extensions, or an SDK are required.
- [ ] Review licence, redistribution, entitlement, and signing constraints.
- [ ] Interview target users about automatic ingest, preview latency, live view,
  camera control, reference overlay, and reconnect behavior.
- [ ] Define the smallest useful slice; object-added ingest may ship without
  remote control.

### Prove

- [ ] Separate PTP protocol from USB, PTP/IP, and simulated transport.
- [ ] Bounded parsing and timeouts.
- [ ] Camera capability model.
- [ ] Recorded protocol transcripts.
- [ ] Simulated camera with duplicate/missing/out-of-order events, disconnects,
  truncation, delay, burst traffic, and renumbering.
- [ ] Reconcile after reconnect by enumerating camera objects.
- [ ] Idempotent transfer by camera identity plus content hash.
- [ ] Temporary spool → verified blob → catalog append.
- [ ] Bounded queue and backpressure.
- [ ] Low-priority preview supersession without source loss.
- [ ] Instrument event, transfer, storage, decode, preview, catalog, and UI times.
- [ ] Snapshot session default recipe into each new asset; changing the default
  affects future captures only.

### UI proof

- [ ] Connection and capability state.
- [ ] Newest frame with thumbnail rail.
- [ ] Transfer and render progress.
- [ ] Reconnect/reconciliation state.
- [ ] Pinned reference with blend/onion skin.
- [ ] Explicit unsupported-control state.

### Tests and metrics

- [ ] Transcript protocol tests and parser fuzzing.
- [ ] 10,000 seeded flaky-transport sequences.
- [ ] Duplicate-event idempotence.
- [ ] Missed-event reconciliation.
- [ ] Disconnect-mid-transfer recovery.
- [ ] No partial source reaches vault/catalog.
- [ ] 100-frame burst stays within queue/memory budgets.
- [ ] Session-default snapshot semantics.
- [ ] Zero undetected source loss in simulation.
- [ ] Real supported camera shutter-to-visible preview under 2 seconds p95.
- [ ] Reconnect recovers all retrievable objects without duplicates.

### Invest gate

Expand beyond one camera only if the proof is reliable during a real shoot, the
protocol/SDK can be distributed sustainably, and target users value it enough to
fund ongoing compatibility work.

### Non-goals

- Immediate cross-vendor support.
- Wireless before wired reliability.
- Live view, remote shutter, and full camera settings in the first ingest slice.
- Exactly-once camera events; Banksia provides idempotence and reconciliation.
- Silent reapplication of changed session defaults to historical frames.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
