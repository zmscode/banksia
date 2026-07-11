# Phase 2A — stabilization and storage baseline closure

**Status:** next/current  
**Objective:** finish the catalog as a trustworthy persistence primitive and
restore a fully green baseline before adding sessions or importing user shoots.

## User outcome

This phase adds little UI. It establishes that catalog mutations, vault objects,
and compaction survive restart and simulated power loss with clear acknowledgement
semantics.

## Dependencies

- Foundation Phase 0 engine.
- Foundation Phase 1 ABI and shell.
- Existing `wombat/vfs.zig`, `wombat/vault.zig`, `wombat/chunker.zig`, and
  in-progress `wombat/catalog.zig`.

## Work items

### 2A.1 Restore a green worktree

- [ ] Replace removed Zig APIs in `wombat/catalog.zig`.
- [ ] Restore the zero-over-100-columns tidy budget.
- [ ] Run catalog tests through `wombat/root.zig` in the normal test graph.
- [ ] Update stale status text that still calls wombat a stub.
- [ ] Update the documented golden count to 20.
- [ ] Ensure `zig build`, `zig build test`, `zig build golden`, and
  `zig build shell` describe and exercise the same supported state.

### 2A.2 Define catalog public invariants

- [ ] Define stable operations for open, close, add asset, resolve by hash,
  read page, set rating, set flags, and filter.
- [ ] Validate ratings as 0–5 at every public boundary.
- [ ] Define a string-length limit representable by the WAL and snapshot.
- [ ] Return named limit errors instead of asserting on user-sized input.
- [ ] Validate all IDs loaded from disk before indexing side tables.
- [ ] Reject duplicate asset hashes unless the provenance model explicitly
  permits another occurrence.
- [ ] Define whether public asset IDs are stable handles or row indices.
- [ ] Keep row positions internal so compaction or future indexing can change.

### 2A.3 Make mutation acknowledgement failure-atomic

- [ ] Document the exact point at which each operation is acknowledged.
- [ ] Reserve all memory required for an asset mutation before writing its WAL
  record, or provide an equivalent rollback/reopen protocol.
- [ ] Ensure a failed call cannot later appear as a successful mutation after
  reopen.
- [ ] Ensure an acknowledged mutation is visible after reopen.
- [ ] Define and test mutation grouping for multi-field updates.
- [ ] Keep WAL append and in-memory application order consistent for every
  operation type.

### 2A.4 Harden WAL behavior

- [ ] Make initial WAL creation name-durable.
- [ ] Validate record length, checksum, generation, tag, asset ID, and payload.
- [ ] Distinguish a genuinely torn final record from corruption in the middle.
- [ ] Truncate only a proven torn tail.
- [ ] Report interior corruption without deleting later bytes automatically.
- [ ] Reject unknown record tags cleanly.
- [ ] Add records for all mutations required by the culling MVP.
- [ ] Ensure replay is idempotent for the current generation.

### 2A.5 Harden snapshot and compaction

- [ ] Add explicit snapshot magic and format version.
- [ ] Validate exact section lengths and reject trailing or missing data.
- [ ] Validate hash handles, string IDs, ratings, flags, and row counts.
- [ ] Write a temporary snapshot, fsync it, rename it, and fsync the parent
  directory before acknowledging the new generation.
- [ ] Clear or rotate the old WAL only after the new snapshot is durable.
- [ ] Define recovery for every crash boundary in compaction.
- [ ] Preserve damaged files for inspection; no automatic destructive repair.

### 2A.6 Reconcile vault durability with the filesystem model

- [ ] Make creation of `vault/`, `objects/`, `tmp/`, and shard directories
  durable according to the stated POSIX model.
- [ ] Extend the simulator so newly created directories have the same durability
  semantics as real directory entries.
- [ ] Verify existing-object dedup does not trust a corrupt object merely because
  its path exists.
- [ ] Decide whether `put` verifies an existing object immediately or defers to
  verify-on-read mode.
- [ ] Add real temporary-directory durability smoke tests in addition to the
  simulated model.

### 2A.7 Extend simulation to catalog state

- [ ] Generate random asset additions, ratings, flags, compactions, closes,
  reopens, and crashes.
- [ ] Maintain an independent acknowledged-state oracle.
- [ ] After reboot, compare every catalog field against the oracle.
- [ ] Verify every catalog asset points to a readable, valid vault object.
- [ ] Print seed, operation index, and a replay command on failure.
- [ ] Add shrinking or a compact failing trace when practical.

### 2A.8 Add storage benchmarks

- [ ] Add `zig build bench` in ReleaseFast.
- [ ] Generate a deterministic 100,000-asset catalog outside the timed section.
- [ ] Measure rating-plus-lens filter, rejected filter, page fetch, snapshot
  serialization, reopen, and WAL replay.
- [ ] Record baseline numbers in this document at phase close.
- [ ] Fail on more than 2× baseline regression in addition to hard ceilings.

## Tests

- [ ] Snapshot → reopen identity.
- [ ] Random WAL sequence → in-memory oracle identity.
- [ ] Empty, valid, truncated-header, truncated-payload, bad-length, bad-CRC,
  unknown-tag, and stale-generation WAL cases.
- [ ] Single-bit snapshot corruption.
- [ ] Invalid string and hash IDs.
- [ ] Allocation-failure injection around every acknowledged mutation.
- [ ] Compaction crash at every filesystem operation.
- [ ] Combined vault/catalog crash simulation.
- [ ] Real-filesystem create, mutate, compact, close, and reopen.
- [ ] Debug allocator leak checks.

## Exit criteria

- [ ] `zig build test` passes with no tidy findings.
- [ ] `zig build golden` remains 20/20.
- [ ] Vault simulator: 10,000 runs, zero acknowledged blob loss.
- [ ] Catalog simulator: 10,000 workloads, zero acknowledged mutation loss or
  partial application.
- [ ] Every catalog asset references a readable hash-valid object.
- [ ] 100,000-asset rating-plus-lens filter is under 10 ms on the CI runner.
- [ ] 100,000-asset snapshot reopen is under 500 ms on the CI runner.
- [ ] Interior WAL corruption is reported and never silently discarded.
- [ ] Phase close-out records actual numbers and deviations.

## Risks

- The simulator may still approximate APFS or POSIX behavior imperfectly.
- Per-mutation fsync may later limit interactive rating throughput.
- Freezing the format too early creates migration burden.
- Removable and network volumes may have weaker guarantees than local APFS.

## Non-goals

- Sessions and card import.
- Thumbnail generation.
- Real-camera colour work.
- Catalog query language or speculative indexes.
- Multi-process writers.
- NAS, cloud, or remote tiers.
- Recipe commits or history UI.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
