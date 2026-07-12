# Branch C — CPU performance and Metal

Phase 2C promotes the backend contract, measurement harness, on-demand Metal
surface, and one late-develop vertical slice into the mandatory sequence. This
branch now owns deeper acceleration only after the Phase 2C invest decision:
GPU demosaic/detail/export, deterministic CPU tiling, additional shader ports,
and broader throughput or thermal optimization.

### Hypothesis

After the Phase 2C proof, additional CPU or Metal work may improve a measured
interaction or throughput bottleneck enough to justify its maintenance cost.

### Entry gate

- [ ] Phase 2C invest decision identifies the next dominant workload or kernel.
- [ ] Record p50/p95/p99 for cold render, late slider edit, loupe, export, and
  thumbnails.
- [ ] Attribute time to decode, demosaic, kernels, allocation, cache, transfer,
  encoding, and UI.
- [ ] Demonstrate a missed user-facing objective caused by compute rather than
  I/O, invalidation, or UI scheduling.

### CPU-first work

- [ ] Eliminate accidental full-frame copies.
- [ ] Add true preview-resolution decode/demosaic where still missing.
- [ ] Fuse compatible pointwise operations.
- [ ] Tile with explicit halo and boundary semantics.
- [ ] Bounded thread pool.
- [ ] Reuse arenas and buffers based on profiles.
- [ ] Cancellation and drop-on-supersede.
- [ ] Preview priority over background warming.
- [ ] Prove thread/tile invariance.
- [ ] Record traversal count before and after.

### Metal proof

- [ ] Backend-independent op contract.
- [ ] Port only the dominant measured kernel first.
- [ ] Keep strict CPU as canonical backend.
- [ ] Separate cache identity unless byte-exact.
- [ ] Record GPU family, shader ID, precision, OS/runtime.
- [ ] Avoid readback where a GPU-resident display path is measured to help.
- [ ] Treat f16 as an experiment requiring ΔE evidence.
- [ ] Clean fallback on unsupported or failed GPU initialization.
- [ ] Bound in-flight command buffers and texture memory.
- [ ] Test sustained thermal behavior.

### Tests and metrics

- [ ] CPU thread/tile invariance.
- [ ] Per-kernel CPU/GPU adversarial comparison.
- [ ] Full-pipeline ΔE/SSIM and finite-output checks.
- [ ] Backend cache separation.
- [ ] Cancellation and fallback.
- [ ] Memory-pressure and repeated-render leak tests.
- [ ] Input-to-visible preview under 100 ms p95.
- [ ] Late pointwise adjustment under 50 ms p95.
- [ ] Metal proof at least 2× faster than optimized CPU at p95.
- [ ] GPU mean ΔE00 ≤ 0.5 with worst-case also reported.
- [ ] No visible tile boundaries or clipping-policy regressions.

### Invest gate

Invest only if optimized CPU still misses a user-visible objective and Metal
provides a substantial p95 improvement at acceptable quality and maintenance
cost. If one kernel benefits, accelerate one kernel rather than the whole engine.

### Non-goals

- Metal-only rendering.
- GPU as canonical historical backend without exactness proof.
- Porting every operation before profiling.
- A universal 16 ms target for every workflow.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
