# Phase 7 — interoperability, broader RAW input, and public beta

**Objective:** make Banksia a responsible participant in existing photography
workflows and remove DNG-only as the main public-beta limitation.

## User outcome

Users can import common RAW files through a packaged fallback, exchange standard
ratings and metadata through XMP, migrate a documented subset of existing
libraries, round-trip through an external editor, and export an understandable
archive if they leave Banksia.

## Dependencies

- Phase 6 stable packaged alpha.
- Decoder strategy evidence from Phase 2B.
- Stable migration framework.

## Work items

### 7.1 Integrate LibRaw behind the decoder interface

- [ ] Vendor or package a pinned LibRaw version.
- [ ] Record licence and source-availability obligations.
- [ ] Keep native DNG as the preferred/reference DNG path.
- [ ] Detect format before backend selection.
- [ ] Normalize output into the bounded emu sensor/metadata contract.
- [ ] Normalize backend errors into named Banksia errors.
- [ ] Record backend and version in diagnostics and renderer identity.
- [ ] Add force-native/force-LibRaw diagnostic options.
- [ ] Add licensed CR3, NEF, and ARW samples across selected camera families.
- [ ] Smoke-test decoding from the packaged application.
- [ ] Do not start native proprietary decoders.

### 7.2 Define descriptive metadata and conflict policy

- [ ] Canonical fields for rating, flags, label, title, caption, creator,
  copyright, keywords, time, GPS, orientation, and source identity.
- [ ] Track field provenance where needed.
- [ ] Define precedence among embedded metadata, XMP, and Banksia state.
- [ ] Never use file modification time as an implicit winner.
- [ ] Add per-field conflict reports.
- [ ] Support prefer-Banksia, prefer-sidecar, and report-only policies.
- [ ] Keep descriptive metadata separate from develop recipes.

### 7.3 Implement XMP import/export

- [ ] Parse required RDF/XMP structures.
- [ ] Support rating, label, keywords, pick/reject conventions, copyright, title,
  and caption.
- [ ] Preserve hierarchical keywords where representable.
- [ ] Preserve unknown namespaces when updating a sidecar.
- [ ] Write sidecars atomically.
- [ ] Define sidecar naming for RAW and DNG.
- [ ] Start with read-only and explicit sync modes, not live two-way sync.
- [ ] Add a Banksia namespace for recipe and renderer IDs.
- [ ] Round-trip Unicode, XML escaping, arrays, and empty values.

### 7.4 Add migration dry runs

- [ ] Scan without writing.
- [ ] Report assets, sidecars, missing originals, duplicates, unsupported fields,
  and estimated storage.
- [ ] Require conflict-policy confirmation.
- [ ] Produce a permanent migration report.
- [ ] Make migration resumable and cancellable.
- [ ] Recommended Lightroom path: save metadata to files/XMP, then import.
- [ ] Capture One path: preserve proprietary sidecars and import only verified
  standard fields.
- [ ] Report unsupported develop settings; never imply visual equivalence.
- [ ] Do not modify source catalogs or sidecars during scan/import.

### 7.5 Add managed and referenced original policies

- [ ] Keep managed portable sessions as default.
- [ ] Add referenced mode only with stable content hash and explicit missing or
  changed state.
- [ ] Add verified relink.
- [ ] Never substitute same-named but different content.
- [ ] Allow later copy into the managed vault.
- [ ] Keep all recipes addressed to immutable content identity.

### 7.6 Add external-editor round-trip

- [ ] Render a high-quality derivative, preferably 16-bit TIFF when available.
- [ ] Embed the chosen colour profile.
- [ ] Launch the external application.
- [ ] Reimport returned content as a derivative, never a RAW replacement.
- [ ] Link source asset, source recipe, derivative, and timestamps.
- [ ] Handle unchanged or missing returns.
- [ ] Let derivatives be rated and exported independently.

### 7.7 Add an exit/archive format

- [ ] Export originals with collision-safe names.
- [ ] Export standard XMP sidecars.
- [ ] Export canonical Banksia recipes and output recipes.
- [ ] Export catalog metadata as documented JSON/CSV.
- [ ] Include hash and relationship manifest.
- [ ] Include renderer and schema identities.
- [ ] Verify the archive.
- [ ] Reimport into an empty Banksia installation.
- [ ] Keep the archive understandable without a live Banksia database.

### 7.8 Public beta program

- [ ] Recruit at least three external testers.
- [ ] Complete at least 20 aggregate real shoots.
- [ ] Test clean install, update, migration, backup restore, and uninstall.
- [ ] Cover every supported macOS major version.
- [ ] Collect opt-in diagnostics without image contents.
- [ ] Publish release notes and compatibility matrix.
- [ ] Resolve P0/P1 issues and triage every P2 issue.

## Tests

- [ ] XMP roundtrip for every supported field.
- [ ] Unknown namespace preservation.
- [ ] Conflict policies per field.
- [ ] Migration fixture counts and mappings.
- [ ] Cancellation/resume and source immutability.
- [ ] Native DNG versus LibRaw overlap comparisons.
- [ ] Licensed CR3/NEF/ARW packaged smoke tests.
- [ ] Malformed backend output cannot violate emu bounds.
- [ ] External derivative roundtrip.
- [ ] Archive export, delete test catalog, restore cleanly.

## Exit criteria

- [ ] XMP import → export → import has zero drift for supported fields.
- [ ] Unknown XMP data survives supported-field updates.
- [ ] Every migration has a write-free dry run.
- [ ] Source libraries are never modified.
- [ ] Packaged LibRaw opens the blessed CR3, NEF, and ARW corpus.
- [ ] Native DNG remains independent of LibRaw.
- [ ] External derivatives never replace originals.
- [ ] A verified archive restores into a clean installation.
- [ ] At least 20 beta shoots complete without data loss.
- [ ] Signed/notarized distribution works on every supported macOS version.
- [ ] No P0/P1 issue remains.

## Risks

- Proprietary develop settings cannot be reproduced.
- Vendor metadata formats evolve.
- XMP updates can erase unknown data if not carefully preserved.
- LibRaw adds packaging and security maintenance.
- Referenced originals move or change.
- Users may mistake import-once for live synchronization.

## Non-goals

- Pixel-identical Lightroom or Capture One migration.
- Import of proprietary layers, masks, healing, or styles.
- Parsing every historical catalog version.
- Live two-way catalog sync.
- Native CR3/NEF/ARW decoders.
- Support for every LibRaw-recognized camera.
- Cloud-library migration.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
