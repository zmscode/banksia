# Phase 8 — immutable edit history, named variants, and reproducibility

**Objective:** make edits durable and inspectable without exposing raw Git
complexity or conflating history with render caches.

## User outcome

A photo can have named variants, undo/redo across immutable revisions,
side-by-side comparison, explicit renderer upgrades, and verifiable canonical
renders.

## Dependencies

- Public-beta storage and migration contracts.
- Stable recipe and renderer identities.
- Working develop/export pipeline.

## Work items

### 8.1 Define immutable revisions

- [ ] Store complete canonical recipe snapshots first; defer delta compression.
- [ ] Define revision object with source ID, recipe ID, renderer manifest ID,
  optional parent, timestamp, message, and provenance.
- [ ] Exclude non-rendering metadata from render identity.
- [ ] Verify every referenced dependency before acknowledging a revision.
- [ ] Atomically create revision and move a named ref.
- [ ] Add reachability-aware GC with a recovery grace period.
- [ ] Keep disposable cache artifacts outside history reachability.

### 8.2 Define edit transactions

- [ ] Do not create a permanent revision for every slider event.
- [ ] Begin from a revision.
- [ ] Render transient preview recipes during gestures.
- [ ] Commit one revision when accepted.
- [ ] Cancel without moving the ref.
- [ ] Coalesce keyboard and numeric edits by documented rules.
- [ ] Preserve crash-recoverable drafts separately.
- [ ] Implement undo/redo as ref movement.
- [ ] Starting a new edit after undo preserves the old path.
- [ ] Reject stale background commits.

### 8.3 Add named variants

- [ ] Default variant on import.
- [ ] Create, rename, duplicate/fork, switch, compare, and delete.
- [ ] Reflog or retention window for deleted variants.
- [ ] Normalize names consistently.
- [ ] Separate active draft from named ref.
- [ ] Allow two variants to share a revision.
- [ ] Show clean, draft, old-renderer, and unavailable-renderer states.
- [ ] Add structural recipe diff.
- [ ] Use “variant” in UI; reserve branch terminology for technical APIs.

### 8.4 Finalize renderer manifests

- [ ] Pin recipe schema, decoder, operation implementations, pixel/colour domain,
  profiles/LUTs/lens data, numeric policy, and canonical encoder.
- [ ] Separate human engine release number from content-addressed manifest.
- [ ] Retain frozen historical implementations.
- [ ] Record build/toolchain provenance for canonical renders.
- [ ] Add explicit renderer migration that creates a new revision.
- [ ] Report `RendererUnavailable` and `DependencyUnavailable` without fallback.
- [ ] Evaluate sandboxing for obsolete retained renderers.

### 8.5 Implement correct render caching

- [ ] Chained computation keys for decode and stages.
- [ ] Cache metadata maps computation key to artifact content ID.
- [ ] Verify artifact hash on read in tests and optional integrity mode.
- [ ] Transactional cache index.
- [ ] Explicit size budget and trim.
- [ ] Prevent eviction while actively read.
- [ ] Prove shared-prefix reuse for late edits.
- [ ] Invalidate at the first changed profile/dependency stage.
- [ ] Separate strict CPU and approximate GPU namespaces.

### 8.6 Add canonical render proofs

- [ ] Define canonical render intents.
- [ ] Record artifact ID for selected revisions.
- [ ] Recompute without final-cache reuse for verification.
- [ ] Report exact match, perceptual match, mismatch, renderer unavailable, or
  dependency unavailable.
- [ ] Never auto-bless a mismatch.
- [ ] Allow archival derivative retention for important variants.

## Tests

- [ ] Canonical-format snapshots and property tests.
- [ ] Hash-domain framing tests.
- [ ] Random edit/undo/redo/fork/switch sequences.
- [ ] Ref crash simulation: old or new ref, never partial.
- [ ] Float edge cases and rejected non-finite values.
- [ ] Every pixel-affecting dependency changes identity.
- [ ] Cache hit equals uncached recomputation.
- [ ] Late edit preserves upstream keys.
- [ ] Thread/tile invariance for strict CPU path.
- [ ] Historical goldens under at least two manifests.
- [ ] Missing renderer/dependency behavior.
- [ ] GC reachability including deleted-variant recovery.

## Exit criteria

- [ ] 10,000 crash workloads lose zero acknowledged revisions or ref moves.
- [ ] Canonical strict corpus reproduces 100% exactly on declared CI target.
- [ ] Strict CPU output is invariant across tested thread counts and tile sizes.
- [ ] Late edits reuse all unaffected upstream stages.
- [ ] Warm variant checkout and 1600px preview is under 100 ms p95.
- [ ] Ref/history operations are under 10 ms p95 at 10,000 assets.
- [ ] 10,000 assets × 20 revisions stays below 64 MiB excluding sources,
  exports, and cache.
- [ ] Renderer migration always preserves the original revision and proof.
- [ ] Documentation does not claim unconditional bit identity forever.

## Risks

- Retaining old implementations increases maintenance and security surface.
- Toolchain/OS changes can make obsolete renderers unavailable.
- Poor manifest boundaries can invalidate too much or too little cache.
- Bad transaction boundaries can create excessive history.
- Canonical format mistakes become durable commitments.

## Non-goals

- Multi-user collaboration.
- Automatic semantic merge of edit stacks.
- Versioning every catalog action as a render revision.
- Treating cache as archival storage.
- Cross-device CPU/GPU identity without proof.
- Full Git command vocabulary in the main UI.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
