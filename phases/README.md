# Banksia phase plans

This directory contains the executable plans for the roadmap in
[`plan.md`](../plan.md). The original linear Phase 0–7 plan it replaced has
been removed; its history lives in git.

## Mandatory phases

1. [`2a-storage-closure/plan.md`](2a-storage-closure/plan.md)
2. [`2b-real-camera-correctness/plan.md`](2b-real-camera-correctness/plan.md)
3. [`2c-performance-metal/plan.md`](2c-performance-metal/plan.md)
4. [`2d-calibrated-image-pipeline/plan.md`](2d-calibrated-image-pipeline/plan.md)
5. [`2e-sessions-import/plan.md`](2e-sessions-import/plan.md)
6. [`3-culling-mvp/plan.md`](3-culling-mvp/plan.md)
7. [`4-global-develop/plan.md`](4-global-develop/plan.md)
8. [`5-practical-export/plan.md`](5-practical-export/plan.md)
9. [`6-private-alpha/plan.md`](6-private-alpha/plan.md)
10. [`7-interoperability-public-beta/plan.md`](7-interoperability-public-beta/plan.md)
11. [`8-history-variants/plan.md`](8-history-variants/plan.md)

## Evidence-gated branches

- [`branch-a-smart-culling/plan.md`](branch-a-smart-culling/plan.md)
- [`branch-b-advanced-processing/plan.md`](branch-b-advanced-processing/plan.md)
- [`branch-c-performance-metal/plan.md`](branch-c-performance-metal/plan.md)
- [`branch-d-tethering/plan.md`](branch-d-tethering/plan.md)

## Shared technical strategy

- [`compute-strategy.md`](compute-strategy.md) — SIMD, CPU concurrency,
  multithreading, scheduling, cancellation, memory budgets, and Metal.

---

## Shared contracts

### Source safety

- Imported originals are immutable.
- Import never renames, moves, deletes, ejects, or writes metadata to a source.
- Managed copies are addressed by the hash of exact source bytes.
- No cache, migration, or GC operation may delete a source reachable from a live
  asset.
- Referenced files, when supported, retain a content hash and explicit
  missing/changed state.

### Input validation

All file, JSON, C ABI, camera, catalog, and migration inputs are untrusted.

- Validate dimensions, lengths, counts, enums, IDs, and parameter domains before
  entering kernels.
- Reject NaN, infinity, invalid crop rectangles, and out-of-range recipes.
- Do not use assertions for failures reachable from user input.
- Bound parser worklists, allocations, recursion, and record counts.
- Distinguish corrupt, unsupported, permission, out-of-space, and internal
  failures.
- No panic may cross the C ABI.

### Identity model

| Identity | Definition |
|---|---|
| Source blob ID | BLAKE3 of exact imported bytes |
| Dependency ID | Hash of profile, LUT, mask, lens data, or other pixel dependency |
| Recipe ID | Hash of canonical versioned recipe bytes |
| Renderer manifest ID | Hash of decoder, operation implementations, numeric policy, and dependencies |
| Revision ID | Hash of parent, source, recipe, renderer manifest, and history metadata |
| Render request ID | Hash of source, recipe, renderer manifest, render intent, and execution contract |
| Artifact ID | Hash of produced bytes |

A revision ID is not a render-cache key. Revisions with different messages or
parents may render identical pixels and share artifacts.

### Canonical recipes

- Canonical format is versioned independently of Zig formatting behavior.
- Hash inputs use domain tags and length framing.
- Non-finite floats are rejected and negative-zero behavior is defined.
- Duplicate keys and unknown engine fields are rejected.
- Recipe IDs use canonical reserialization, not arbitrary input JSON.
- Schema upgrades create new recipe bytes and revisions.

### Cache identity

A stage key represents the computation, not a whole recipe plus a stage index.

```text
decode_key = H(
    source_blob_id,
    decoder_implementation_id,
    canonical_decode_options,
    decoded_format_id
)

stage_key[n] = H(
    stage_key[n - 1],
    operation_implementation_id,
    canonical_operation_parameters,
    dependency_ids,
    output_domain_id
)

render_key = H(
    final_stage_key,
    render_intent,
    encoder_implementation_id,
    execution_contract_id
)
```

Rules:

- Late edits preserve unaffected upstream keys.
- Changed dependencies invalidate the first affected stage and everything after.
- History messages do not invalidate renders.
- Resolution, ROI, resampling, colour space, bit depth, and sharpening enter the
  key where they first affect pixels.
- CPU and GPU share keys only when byte identity is proven.
- Cache artifacts are disposable and hash-verified.
- Initially cache only embedded previews, demosaiced previews, final previews,
  and explicit exports.

### Reproducibility levels

1. **Recipe reproducibility:** source, recipe, dependencies, and renderer remain
   inspectable.
2. **Semantic rerenderability:** a compatible renderer interprets the recipe
   without substitution.
3. **Verified bit-exact reproduction:** the strict backend reproduces an artifact
   hash inside a declared target/toolchain envelope.
4. **Perceptually equivalent acceleration:** an alternate backend meets named
   quality limits but is not called bit-identical.

### Measurement

Every benchmark records hardware, OS, Zig/dependency versions, build mode,
corpus revision, dimensions, cache state, latency percentiles, and peak memory
where relevant.

---

## Shared scoreboard

| Contract | Metric |
|---|---|
| Engine regression | Exact pass count per frozen renderer manifest |
| Real-camera quality | Neutral and ColorChecker ΔE00, SSIM, unsupported count |
| Source durability | Acknowledged blob loss across seeded workloads |
| Catalog durability | Lost or partially applied acknowledged mutations |
| Import safety | Dangling assets, source-tree changes, resume mismatch |
| Session integrity | Corruption detection and restore success |
| Culling latency | Open, first page, frame time, input acknowledgement |
| Develop latency | Input-to-visible preview and full render time |
| Export | Photos/minute, memory, cancellation, partial outputs |
| Reproducibility | Exact canonical renders and unavailable dependencies |
| Cache | Cache hit equals recompute; unaffected prefixes reused |
| Smart culling | Precision/recall/F1, top-k recall, time reduction |
| Tethering | Fault passes, reconciliation, p95 latency |
| Storage overhead | Bytes per asset, recipe, revision, profile, cache class |

---

## Phase close-out template

```markdown
## Phase close-out

- Status: complete / partial / parked
- Date:
- Commit:
- Reference machine and OS:
- Corpus revision:
- Commands run:
- Test counts:
- Benchmark results:
- Exit criteria passed:
- Exit criteria waived:
- Deviations:
- New risks:
- Learnings:
- Compatibility or format changes:
- Follow-up tasks:
```

## Branch decision template

```markdown
## Decision: Invest / Continue proof / Park

- Hypothesis:
- Users and workloads:
- Corpus and provenance:
- Baseline:
- Measured result:
- Quality result:
- Reliability result:
- Maintenance estimate:
- Risks discovered:
- Decision:
- Revisit trigger:
```

Parking a branch is a valid outcome when evidence does not justify investment.
