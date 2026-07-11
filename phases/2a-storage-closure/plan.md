# Phase 2A — stabilization and storage baseline closure

**Status:** complete (2026-07-11)
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

- [x] Replace removed Zig APIs in `wombat/catalog.zig`.
- [x] Restore the zero-over-100-columns tidy budget.
- [x] Run catalog tests through `wombat/root.zig` in the normal test graph.
- [x] Update stale status text that still calls wombat a stub.
- [x] Update the documented golden count to 20.
- [x] Ensure `zig build`, `zig build test`, `zig build golden`, and
  `zig build shell` describe and exercise the same supported state.

### 2A.2 Define catalog public invariants

- [x] Define stable operations for open, close, add asset, resolve by hash,
  read page, set rating, set flags, and filter.
- [x] Validate ratings as 0–5 at every public boundary.
- [x] Define a string-length limit representable by the WAL and snapshot.
- [x] Return named limit errors instead of asserting on user-sized input.
- [x] Validate all IDs loaded from disk before indexing side tables.
- [x] Reject duplicate asset hashes unless the provenance model explicitly
  permits another occurrence.
- [x] Define whether public asset IDs are stable handles or row indices.
- [x] Keep row positions behind the public `AssetView`/page API.

Decision: `AssetId` is a durable append-order handle in the no-delete Phase 2A
format. Its current `u32` representation must be treated as opaque by callers;
compaction and reopen preserve it.

### 2A.3 Make mutation acknowledgement failure-atomic

- [x] Document the exact point at which each operation is acknowledged.
- [x] Reserve all memory required for an asset mutation before writing its WAL
  record, or provide an equivalent rollback/reopen protocol.
- [x] Ensure a failed call cannot later appear as a successful mutation after
  reopen.
- [x] Ensure an acknowledged mutation is visible after reopen.
- [x] Define and test mutation grouping for multi-field updates.
- [x] Keep WAL append and in-memory application order consistent for every
  operation type.

`asset_add` groups all initial fields in one record; rating and flags are
single-field records. A mutation is acknowledged only after its frame is
appended and the WAL file is fsynced.

### 2A.4 Harden WAL behavior

- [x] Make initial WAL creation name-durable.
- [x] Validate record length, checksum, generation, tag, asset ID, and payload.
- [x] Distinguish a genuinely torn final record from corruption in the middle.
- [x] Truncate only a proven torn tail.
- [x] Report interior corruption without deleting later bytes automatically.
- [x] Reject unknown record tags cleanly.
- [x] Add records for all mutations required by the culling MVP.
- [x] Ensure replay applies only the snapshot's current generation.

### 2A.5 Harden snapshot and compaction

- [x] Add explicit snapshot magic and format version.
- [x] Validate exact section lengths and reject trailing or missing data.
- [x] Validate hash handles, string IDs, ratings, flags, and row counts.
- [x] Write a temporary snapshot, fsync it, rename it, and fsync the parent
  directory before acknowledging the new generation.
- [x] Clear or rotate the old WAL only after the new snapshot is durable.
- [x] Define recovery for every crash boundary in compaction.
- [x] Preserve damaged files for inspection; no automatic destructive repair.

### 2A.6 Reconcile vault durability with the filesystem model

- [x] Make creation of `vault/`, `objects/`, `tmp/`, and shard directories
  durable according to the stated POSIX model.
- [x] Extend the simulator so newly created directories have the same durability
  semantics as real directory entries.
- [x] Verify existing-object dedup does not trust a corrupt object merely because
  its path exists.
- [x] Decide whether `put` verifies an existing object immediately or defers to
  verify-on-read mode.
- [x] Add real temporary-directory durability smoke tests in addition to the
  simulated model.

Decision: when `verify_on_read` is enabled, an existing object is re-read and
hashed before `put` accepts it as a dedup hit. Trusted-volume mode may defer that
cost.

### 2A.7 Extend simulation to catalog state

- [x] Generate random asset additions, ratings, flags, compactions, closes,
  reopens, and crashes.
- [x] Maintain an independent acknowledged-state oracle.
- [x] After reboot, compare every catalog field against the oracle.
- [x] Verify every catalog asset points to a readable, valid vault object.
- [x] Print seed, operation index, and a replay command on failure.
- [x] Emit a compact failing operation trace.

A catalog failure prints the seed/run replay command, failing operation index,
and the bounded operation trace for that workload. Automatic delta-debugging is
not required for this phase.

### 2A.8 Add storage benchmarks

- [x] Add `zig build bench` in ReleaseFast.
- [x] Generate a deterministic 100,000-asset catalog outside the timed section.
- [x] Measure rating-plus-lens filter, rejected filter, page fetch, snapshot
  serialization, reopen, and WAL replay.
- [x] Record baseline numbers in this document at phase close.
- [x] Fail on more than 2× the rounded baseline in addition to hard ceilings.

## Tests

- [x] Snapshot → reopen identity.
- [x] Random WAL sequence → in-memory oracle identity.
- [x] Table-driven empty, valid, truncated-header, truncated-payload, bad-length,
  bad-CRC, unknown-tag, and stale-generation WAL cases.
- [x] Single-bit snapshot corruption.
- [x] Invalid string and hash IDs.
- [x] Allocation-failure injection around every allocating acknowledged mutation.
- [x] Compaction crash before every filesystem operation, with both rename
  persistence outcomes.
- [x] Combined vault/catalog crash simulation.
- [x] Real-filesystem create, mutate, compact, close, and reopen.
- [x] Debug allocator leak checks.

## Exit criteria

- [x] `zig build test` passes with no tidy findings.
- [x] `zig build golden` remains 20/20.
- [x] Vault simulator: 10,000 runs, zero acknowledged blob loss.
- [x] Catalog simulator: 10,000 workloads, zero acknowledged mutation loss or
  partial application.
- [x] Every catalog asset references a readable hash-valid object.
- [x] 100,000-asset rating-plus-lens filter is under 10 ms.
- [x] 100,000-asset snapshot reopen is under 500 ms.
- [x] Interior WAL corruption is reported and never silently discarded.
- [x] Phase close-out records actual numbers and deviations.

## Close-out

Validated on macOS with Zig 0.16.0 on 2026-07-11:

- `zig build sim -Dsim-runs=10000 -Dsim-seed=1`: 10,000 vault plus
  10,000 catalog workloads, 234,600 injected crashes, 480,491 acknowledged
  blobs, 308,742 acknowledged catalog mutations, zero loss.
- 100,000-asset rating + lens scan: **0.140 ms** (10 ms hard ceiling).
- 100,000-asset rejected-only scan: **0.029 ms**.
- 256-row public page fetch: **0.001 ms**.
- 100,000-asset snapshot serialization/compaction: **5.513 ms**.
- 100,000-asset snapshot reopen: **12.405 ms** (500 ms hard ceiling).
- 1,000-record WAL replay: **0.285 ms**. The smaller WAL fixture avoids the
  simulated filesystem's intentionally simple whole-buffer append cost; the
  product-scale reopen gate is the 100,000-row snapshot measurement.

Rounded regression baselines in `wombat/bench.zig` are deliberately above the
single-machine observations and fail at 2× baseline, capped by the hard product
ceilings. The randomized gate is backed by a table-driven WAL matrix and
crash-before-each-operation compaction tests for both rename outcomes. The work
also produced three focused VFS regressions: durable append prefix, durable
truncation prefix, and overwrite-rename undo.

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

[Back to the roadmap](../../plan.md) · [Shared phase rules](../README.md)
