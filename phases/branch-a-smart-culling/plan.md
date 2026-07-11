# Branch A — smart culling

### Hypothesis

Burst grouping and relative focus assistance reduce culling time without hiding
keepers or replacing photographer judgment.

### Discover

- [ ] Collect licensed real shoots across portrait, action, panning, studio,
  brackets, high ISO, shallow depth of field, and intentional blur.
- [ ] Hand-label burst boundaries and preferred frames.
- [ ] Measure unassisted culling time and pick consistency.
- [ ] Identify whether grouping, focus inspection, or navigation is the actual
  bottleneck.

### Prove

- [ ] Key derived analysis by source, preview renderer, algorithm ID, and params.
- [ ] Keep derived data replaceable and user overrides durable.
- [ ] Segment by time before visual clustering.
- [ ] Start with dHash and measured SIMD linear search.
- [ ] Add pHash only if recall data requires it.
- [ ] Use stable group IDs derived from members.
- [ ] Provide split, merge, and do-not-regroup corrections.
- [ ] Compute relative per-tile focus energy within a burst.
- [ ] Normalize for scale/noise only when corpus results require it.
- [ ] Add focus overlay and synchronized 100% compare.
- [ ] Never auto-delete or permanently hide low-ranked frames.

### Tests and metrics

- [ ] Known perceptual-hash vectors.
- [ ] Boundary tests for time and distance.
- [ ] Stable deterministic reanalysis.
- [ ] Real-corpus pairwise precision/recall/F1.
- [ ] Controlled blur monotonicity.
- [ ] User overrides survive reindexing.
- [ ] Burst pairwise F1 ≥ 0.90 on held-out data.
- [ ] Human-selected frame appears in suggested top 3 for ≥ 95% of labelled
  bursts.
- [ ] Assisted culling reduces median time by ≥ 25% without materially reducing
  keeper agreement.
- [ ] 1,000-frame analysis completes within 30 seconds cold.

### Invest gate

Invest only if real users cull materially faster and do not miss more keepers.
If grouping works but ranking does not, ship grouping and focus overlays without
best-frame ranking.

### Non-goals

- Automatic deletion.
- General aesthetic scoring.
- Face identity databases.
- Machine learning before simpler methods fail measured gates.
- Universal cross-scene sharpness claims.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
