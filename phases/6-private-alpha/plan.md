# Phase 6 — product hardening and private alpha

**Objective:** turn the completed-shoot workflow into a distributable application
that upgrades, recovers, diagnoses failures, and protects user work.

## User outcome

Trusted testers can install Banksia without developer tools, complete shoots,
recover from interruptions, verify sessions, and provide useful diagnostics.

## Dependencies

- Phase 5 completed-shoot gate.
- Stable session, catalog, recipe, and output-recipe schemas.
- Apple signing/notarization capability.

## Work items

### 6.1 Session integrity and repair boundaries

- [ ] Document ownership and purpose of every session file.
- [ ] Validate manifest, snapshot, WAL, recipes, refs, and vault on open.
- [ ] Distinguish recoverable damage from unrecoverable corruption.
- [ ] Add `banksia verify` full scan.
- [ ] Add `banksia repair` only for provably safe actions.
- [ ] Produce a recovery report before modifying damaged state.
- [ ] Never delete suspect data automatically.
- [ ] Test copied, restored, and partially restored sessions.

### 6.2 Schema migrations

- [ ] Ordered migrations for session, catalog, recipe, and output-recipe formats.
- [ ] Atomic or resumable behavior.
- [ ] Back up pre-migration metadata.
- [ ] Verify all references before commit.
- [ ] Record source/destination version and application version.
- [ ] Test upgrade from every distributed alpha format.
- [ ] Reject unsafe downgrade.
- [ ] Keep old render semantics available.

### 6.3 Error handling and diagnostics

- [ ] Replace generic UI failures with named actionable errors.
- [ ] Classify unsupported, corrupt, permission, out-of-space, transient I/O, and
  internal errors.
- [ ] Add bounded structured local logs.
- [ ] Redact paths and metadata by default.
- [ ] Add an opt-in diagnostics bundle.
- [ ] Record app, engine, schema, OS, architecture, and codec versions.
- [ ] Add optional crash reporting only with explicit consent.
- [ ] Maintain a fully functional no-network mode.
- [ ] Ensure malformed input never crashes the process.

### 6.4 UI and accessibility hardening

- [ ] First-run session guidance.
- [ ] Clear supported-format limits.
- [ ] Keyboard shortcut help.
- [ ] Accessibility labels and logical focus order.
- [ ] Dark and light appearance.
- [ ] Persist layout, selection, filters, sort, and export preset.
- [ ] Pending-write indicators where needed.
- [ ] Prevent unsafe close during import, migration, or export.
- [ ] Progress and cancellation for all long operations.
- [ ] Missing/moved-session guidance.

### 6.5 Resource and soak testing

- [ ] Fix benchmark corpus and workload manifests.
- [ ] Bound thumbnail, import, and export concurrency.
- [ ] Add cache-size configuration and safe cleanup.
- [ ] Profile startup at 1,000 and 10,000 assets.
- [ ] Profile 100,000-asset filters.
- [ ] Run eight-hour mixed-workload memory soak.
- [ ] Add performance regression gates where CI variance allows.
- [ ] Keep CPU rendering as production baseline.

### 6.6 Packaging

- [ ] Build a complete `.app` bundle.
- [ ] Apple Silicon first; explicitly decide Intel support.
- [ ] Pin minimum macOS version.
- [ ] Stable bundle ID and semantic version.
- [ ] Icons and privacy descriptions.
- [ ] Sign all nested binaries.
- [ ] Enable hardened runtime compatibly.
- [ ] Notarize external builds.
- [ ] Produce a DMG or documented drag-install package.
- [ ] Test on a clean macOS account.
- [ ] Verify no development-tree rpaths remain.
- [ ] Publish checksums and release notes.

### 6.7 Documentation

- [ ] Supported DNG characteristics and exclusions.
- [ ] Session, import, culling, develop, export, backup, verify, and recovery.
- [ ] Colour-management assumptions.
- [ ] Metadata and GPS defaults.
- [ ] DNG conversion workflow for unsupported RAWs.
- [ ] Benchmark hardware and expectations.
- [ ] Known issues and bug-report template.
- [ ] Alpha policy requiring backed-up originals.

### 6.8 Private alpha program

- [ ] At least five packaged-build shoots.
- [ ] At least 1,000 aggregate imported images.
- [ ] Include interrupted import/export.
- [ ] Restore one session from backup.
- [ ] Upgrade one session from an earlier schema.
- [ ] Record every crash, integrity issue, blocked workflow, and escape to another
  editor.
- [ ] Resolve every P0/P1 issue before phase close.

## Tests

- [ ] Crash simulation across import, mutations, autosave, compaction,
  migration, and export.
- [ ] Session verification after injected crashes.
- [ ] Random rating/edit/undo/batch sequences.
- [ ] Repeated open/close with no state drift.
- [ ] Cache eviction during browsing/export.
- [ ] Disk-full and permission changes.
- [ ] Restore from copied session.
- [ ] Fuzz DNG, lossless JPEG, recipes, output recipes, catalog, WAL, and manifest.
- [ ] Diagnostics redaction.
- [ ] Keyboard-only workflow.
- [ ] Accessibility inspection.
- [ ] Code-sign, notarization, clean install, and packaged smoke tests.

## Exit criteria

- [ ] Packaged app runs without Zig, SwiftPM, or Xcode.
- [ ] No operation can mutate an original RAW.
- [ ] Crash simulation reports zero acknowledged-data loss.
- [ ] Verification detects every injected corruption case.
- [ ] Five packaged shoots complete end to end.
- [ ] Backup restore and schema upgrade succeed.
- [ ] No known P0 or P1 issue remains.
- [ ] Unsupported inputs fail clearly without crashing.
- [ ] Cold launch ≤ 2 seconds on the reference Mac.
- [ ] Cached 10,000-image session opens ≤ 8 seconds, with a path to 5 seconds
  before public beta.
- [ ] Eight-hour soak has no crash and bounded memory growth.

## Risks

- Hardening can attract unrelated feature work.
- Migration code can damage sessions.
- SwiftUI behavior varies by macOS version.
- Signing can expose late dylib problems.
- Users may assume broader RAW support than advertised.

## Non-goals

- Public broad-camera release.
- Windows or Linux applications.
- Cloud sync.
- Plugins.
- Tethering.
- Smart culling.
- Advanced layers.
- Metal.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
