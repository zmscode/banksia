# Phase 2E — safe sessions, import, and provenance

**Objective:** provide a conservative, resumable path from a card or folder into
a self-contained session. No acknowledged catalog entry may reference missing
source data.

## User outcome

The user can:

- create a portable session;
- import a folder without modifying it;
- interrupt and safely resume import;
- rerun import without duplicate assets;
- see imported, duplicate, unsupported, and failed counts;
- verify the session afterward.

## Dependencies

- Phase 2A catalog durability.
- Phase 2B metadata-only parsing and supported-image profile.
- Existing vault.

## Work items

### 2E.1 Define the session format

- [ ] Define a versioned layout containing `session.json`, `vault/`, catalog,
  WAL, `cache/`, and lock state.
- [ ] Generate a stable session ID.
- [ ] Use session-relative paths only.
- [ ] Publish a new session manifest only after required directories are durable.
- [ ] Add `banksia session new`, `inspect`, `verify`, and `compact`.
- [ ] Reject unknown future session versions without modifying them.
- [ ] Implement a single-writer lock and documented stale-lock recovery.
- [ ] Treat `cache/` as disposable and everything else as authoritative.

### 2E.2 Define asset and provenance records

- [ ] Store source blob ID separately from source occurrence/provenance.
- [ ] Record original filename, source-relative path, size, modification time,
  import batch, metadata status, preview status, and displayed dimensions.
- [ ] Decide whether byte-identical files from two paths create one asset with
  two occurrences or one asset plus import provenance.
- [ ] Define RAW+JPEG pair representation for future culling.
- [ ] Preserve unsupported or corrupt files as verified source objects when
  copying succeeded, with visible status.
- [ ] Do not let preview or metadata failure discard a safely copied source.

### 2E.3 Discover source files safely

- [ ] Walk deterministically.
- [ ] Do not follow symlinks by default.
- [ ] Skip Banksia sessions and vault directories inside a source tree.
- [ ] Use a bounded candidate extension and signature list.
- [ ] Handle non-UTF-8 or unusual names without aborting the entire batch.
- [ ] Add `--dry-run`.
- [ ] Record every skipped file and reason.
- [ ] Compare source metadata before and after reading; retry or reject files
  that change during import.
- [ ] Hash the source tree before and after acceptance testing.

### 2E.4 Implement bounded streaming ingest

- [ ] Avoid loading a multi-gigabyte source entirely into memory.
- [ ] Hash while writing a temporary object.
- [ ] Verify the complete object before acknowledgement.
- [ ] Commit in this order:
  1. discover source;
  2. durably store source blob;
  3. extract best-effort metadata;
  4. durably append catalog and provenance records;
  5. report imported.
- [ ] Treat a crash after object storage but before catalog append as a harmless
  orphan.
- [ ] Make rerun adopt or deduplicate safe orphan objects.
- [ ] Ensure the reverse state—a catalog row referencing an unacknowledged
  object—is impossible.
- [ ] Continue after per-file decode errors unless storage safety is compromised.

### 2E.5 Add import batches and resumability

- [ ] Record batch ID, source, start time, completion state, counts, and failures.
- [ ] Make restart detect incomplete batches.
- [ ] Resume by source identity and content hash, not only filename.
- [ ] Ensure completed assets are not duplicated on resume.
- [ ] Add stable text and JSON summaries.
- [ ] Return nonzero CLI status for incomplete batches while preserving successes.
- [ ] Keep GC manual and disabled by default.

### 2E.6 Define the thumbnail handoff

- [ ] Define keys using source hash, renderer manifest, recipe, edge, and encoded
  thumbnail format.
- [ ] Do not make import acknowledgement depend on thumbnail generation.
- [ ] Queue thumbnail work as low-priority derived work.
- [ ] Allow Phase 3 to regenerate all thumbnails after cache deletion.
- [ ] Record whether an embedded preview is available.

### 2E.7 Add session verification

- [ ] Default verification checks catalog references and object presence.
- [ ] Full verification rehashes every referenced object.
- [ ] Report missing, corrupt, orphan, and unreferenced objects separately.
- [ ] Never delete findings automatically.
- [ ] Add `gc --dry-run` before destructive GC is exposed.
- [ ] Produce machine-readable verification output.

## Tests

- [ ] Create, open, close, copy, and reopen a session.
- [ ] Import one file and compare exact source/stored bytes.
- [ ] Import same source twice with zero duplicate assets.
- [ ] Import two paths with identical bytes and verify provenance policy.
- [ ] Unsupported and corrupt DNG behavior.
- [ ] Source mutated during read.
- [ ] Symlink and recursive-session exclusion.
- [ ] Permission, disk-full, and interrupted-read cases.
- [ ] Combined source/vault/catalog crash simulation.
- [ ] Resume reaches the same final state as uninterrupted import.
- [ ] Verification detects missing and corrupt objects.
- [ ] Source tree remains byte-identical.

## Exit criteria

- [ ] Import a deterministic 1,000-file card twice.
- [ ] Second import creates zero new objects and zero duplicate assets under the
  documented policy.
- [ ] Source tree is unchanged.
- [ ] 10,000 crash-injected import workloads lose zero acknowledged assets and
  never publish a dangling catalog reference.
- [ ] Import peak memory remains below 256 MiB independent of source-file size.
- [ ] Streaming ingest reaches at least 70% of measured read + BLAKE3 + write
  baseline.
- [ ] `banksia verify` reports a clean session after import, reopen, and copy.
- [ ] Metadata or preview failure never discards a verified RAW object.

## Risks

- Source files may change while copied.
- Removable filesystems may have weak durability.
- Per-file fsync can limit throughput.
- Dedup and provenance semantics can confuse users if not visible.
- GC is dangerous until every live reference is enumerated.

## Non-goals

- Erasing or ejecting cards.
- Moving instead of copying.
- Global catalogs or session merge.
- Watched folders.
- Tether import.
- Cloud or NAS sync.
- Sidecar writes.
- Automatic GC.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
