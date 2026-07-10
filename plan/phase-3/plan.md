# Phase 3 — versioning: recipes as commits, engines as versions

> **Objective:** The git layer. Every edit is a commit; virtual copies are
> branches; history is scrubbable; commits render identically forever.
> This is the feature no competitor has (Capture One's process-engine
> versioning is the closest, and it has no history/branches).
>
> **Definition of done:** `banksia log <photo>` shows edit history;
> `banksia branch <photo> alt-crop` forks a recipe; checking out any
> historical version re-renders via cache in under 100ms at preview size;
> a commit made under engine v1 renders bit-identically after the pipeline
> gains new ops; the version store for a 10k-photo library stays under
> 50MB.

**Status: not started.** Requires Phase 2 (wombat).

## 1. The engine version registry (do this first — it shapes everything)

- [ ] `emu/registry.zig`: op implementations are looked up through a
      version table, not called directly. v1 = today's ops, frozen. A new
      demosaic/curve lands as v2 entries; v1 entries never change.
- [ ] The golden corpus becomes version-pinned: every existing baseline
      hash is an engine-v1 case *forever*. Adding v2 adds new cases; v1
      cases keep passing — this is the mechanical enforcement of
      "improving an op never changes old renders."
- [ ] `bk_render`/CLI accept the recipe's engine_version (they already
      carry it); render dispatches through the registry.
- [ ] Test: a deliberately divergent v2 of tone_curve renders differently
      under v2 and byte-identically under v1 (both asserted).

## 2. Commit model (on wombat's CAS)

- [ ] Recipe blobs: canonical bytes (already defined) content-addressed
      into the vault.
- [ ] Commit object: canonical bytes of {parent commit hash, recipe hash,
      engine_version, wall time, message} — content-addressed; a Merkle
      chain per asset. Wall time is recorded history, not an input to
      rendering (determinism is unaffected).
- [ ] Refs: named branch heads per asset (`main`, user branches) in the
      catalog's WAL domain; `recipe_head` column points at the current
      commit's handle.
- [ ] Library-level snapshots: catalog state commits (Phase 2's snapshot
      mechanism gains a parent pointer) so "what did the library look like
      last month" is answerable.

## 3. Render cache

- [ ] Key: (blob hash, recipe hash, engine_version, edge) → rendered
      bytes in the CAS; per-stage caching (keyed through stage index over
      the op stack prefix) so editing a late op reuses the demosaic.
- [ ] Correctness test (pair assertion): cache hit bytes == recompute
      bytes, fuzzed over random recipes (seeded swarm: random op subsets,
      skewed params).
- [ ] Eviction: LRU by file mtime under a size budget, behind
      `banksia cache trim`; never evicts mid-render.

## 4. CLI verbs

- [ ] `banksia log <photo>`: hash, engine version, time, message per line.
- [ ] `banksia commit <photo> -m <msg>`: current recipe → new commit on
      the current branch.
- [ ] `banksia branch <photo> <name>` / `banksia checkout <photo> <ref>`.
- [ ] `banksia diff <photo> <ref-a> <ref-b>`: structural op-stack diff
      (JSON-aware: op added/removed/param changed), not text diff.
- [ ] `banksia upgrade <photo>`: re-pin to engine_version_current as a new
      commit (explicit, never automatic).
- [ ] Merge: op-stack merge, last-writer-wins per op for v1 policy;
      conflicts reported, never silently blended.

## 5. Shell support (the demo)

- [ ] History scrubber slider in the SwiftUI app: drag across commits,
      preview renders from cache. This is the phase's showpiece — record
      the scrub latency.
- [ ] C ABI grows: `bk_history_count`, `bk_history_checkout(index)` (stay
      ≤ 12 functions total; revisit surface if exceeded).

## Tests

- Engine-version freeze test (v1 bit-identical under a divergent v2).
- Commit chain: property test — random edit/branch/checkout sequences,
  then every historical checkout renders byte-identically to the render
  recorded when that commit was made (seeded, in CI).
- Cache == recompute fuzz (the render-cache pair assertion).
- Store-size gate: 10k assets × 20 commits each, synthetic → assert vault
  overhead < 50MB (recipes and commits are kilobytes; measure, record).
- Structural diff golden cases (snapshot tests on diff output).

## Exit criteria

- [ ] Historical checkout at preview size < 100ms warm (record: ___).
- [ ] Engine-v1 golden cases green after a v2 op exists.
- [ ] 10k-photo version store < 50MB (record: ___).
- [ ] Scrubber demo works end to end in the shell.

## Learnings

*(recorded as the phase runs)*
