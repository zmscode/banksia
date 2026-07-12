# Phase 3 — keyboard-driven culling MVP

**Objective:** turn the inspection shell into a useful session-based culling
application before adding perceptual grouping or focus scoring.

## User outcome

A photographer can import a shoot, browse it immediately, rate and reject from
the keyboard, filter to keepers, inspect images at larger size, close the app,
and reopen with every decision preserved.

## Dependencies

- Phase 2D sessions, paging, and durable mutations.
- Phase 2B correct default rendering.
- Existing Swift actor and SwiftUI shell.

## Work items

### 3.1 Build the fast thumbnail path

- [ ] Extract validated embedded DNG previews when available.
- [ ] Add bounded-resolution Bayer decode/demosaic fallback.
- [ ] Retain full-render-then-downsample as the correctness oracle.
- [ ] Compare fast previews against the oracle under a perceptual threshold.
- [ ] Generate asynchronously with bounded concurrency.
- [ ] Prioritize visible, then near-visible, then background cells.
- [ ] Cancel work when cells scroll away or the session closes.
- [ ] Prevent stale results from being displayed in reused cells.
- [ ] Select an encoded cache format after measuring size and decode cost.
- [ ] Target median thumbnail size below 100 KiB.
- [ ] Treat absent or corrupt cache entries as regeneration events.

### 3.2 Add session-oriented engine/API boundaries

- [ ] Introduce a session handle separate from the single-image render handle.
- [ ] Add batched operations for open, count, query page, fetch thumbnail, set
  rating, and set flags.
- [ ] Avoid one C call per field per grid cell.
- [ ] Return stable asset IDs.
- [ ] Document buffer ownership, cancellation, and actor serialization.
- [ ] Extend the C smoke test through open/query/mutate/reopen.
- [ ] If the ABI approaches 16–20 functions, design a command/result protocol.

### 3.3 Implement practical queries

- [ ] Deterministic capture-time ordering with stable tie-breaking.
- [ ] Filters for all, picked, rejected, non-rejected, unrated, exact rating,
  and minimum rating.
- [ ] Ascending and descending capture-time sort.
- [ ] Include unsupported-preview assets rather than hiding them.
- [ ] Ensure pages cannot duplicate or omit assets.
- [ ] Define page invalidation after mutations.
- [ ] Preserve selection where possible when filters change.

### 3.4 Build the virtualized culling UI

- [ ] Open/create session flow.
- [ ] Lazy thumbnail grid and filmstrip.
- [ ] Bounded image residency around the viewport.
- [ ] Rating, pick/reject, filename, and warning badges.
- [ ] Clear selected-cell focus.
- [ ] Large single-image view.
- [ ] Fit, fill, 100% zoom, and pan.
- [ ] Toggle embedded preview versus developed preview when both exist.
- [ ] Loading, generation, and error states that do not block other assets.
- [ ] Keep filesystem and engine calls off the main actor.

### 3.5 Implement the keyboard workflow

- [ ] Arrow keys and J/K navigation.
- [ ] `0`–`5` ratings.
- [ ] `X` reject.
- [ ] `P` pick if pick remains distinct from rating.
- [ ] Space toggles grid and loupe.
- [ ] Shortcut for filters.
- [ ] Centralized, testable shortcut mapping.
- [ ] Optimistic UI updates followed by durable acknowledgement.
- [ ] Revert optimistic state and display an error on persistence failure.
- [ ] Add bounded in-session undo/redo using inverse catalog actions.

### 3.6 Add compare and multi-selection essentials

- [ ] Side-by-side compare for 2–4 selected images.
- [ ] Synchronized zoom and pan.
- [ ] Survey mode for a small selection.
- [ ] Multi-selection ratings and rejects as one transaction.
- [ ] Selection count and active filter summary.
- [ ] RAW+JPEG pair handling if represented by Phase 2D.
- [ ] Prefetch the next and previous likely selections.

### 3.7 Operational hardening

- [ ] Clean cancellation on close.
- [ ] Cache trim and cache-size reporting.
- [ ] Visible catalog-write failure state.
- [ ] Reopen restores ratings, filters, ordering, and last selection.
- [ ] Corrupt cache does not affect source or catalog.
- [ ] App remains navigable during uncached generation.

## Tests

- [ ] Fast preview versus reference threshold.
- [ ] Cache key and corrupt-cache regeneration.
- [ ] Paging and filtering versus a naive oracle.
- [ ] No duplicate or omitted IDs across pages.
- [ ] Rating/reject → close → reopen.
- [ ] Crash after acknowledged mutation retains it.
- [ ] Shortcut and selection-boundary tests.
- [ ] Cancellation and stale-result suppression.
- [ ] Multi-selection transaction recovery.
- [ ] C ABI smoke extension.
- [ ] Swift model/controller tests independent of view rendering.

## Exit criteria

- [ ] 10,000-asset session opens interactively in under 1 second with an
  existing catalog snapshot.
- [ ] First cached grid page appears in under 250 ms.
- [ ] Cached scrolling sustains 60 fps with p95 frame time below 16.7 ms on the
  reference Mac.
- [ ] Uncached thumbnails for a representative 1,000-shot session complete in
  under 60 seconds in the background.
- [ ] Rating/reject visible feedback occurs next frame and durable acknowledgement
  is under 100 ms p95 on local SSD.
- [ ] Steady-state browsing memory remains below 500 MiB at 10,000 assets.
- [ ] Full manual workflow succeeds using only keyboard navigation and Banksia.
- [ ] Existing storage, colour, ABI, golden, and simulation gates stay green.

## Risks

- SwiftUI lazy grids may retain too many views or images.
- Thumbnail generation can dominate until embedded/low-resolution paths work.
- Actor cancellation bugs may show the wrong image.
- Fsync latency may affect keystrokes.
- ABI growth may become fragmented.

## Non-goals

- Perceptual hashing.
- Automatic burst grouping.
- Focus masks or best-frame ranking.
- Face or subject detection.
- Recipe branches or merge.
- Advanced developing.
- Export.
- Tethering.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
