# Phase 2 — wombat: content-addressed vault + columnar catalog

> **Objective:** The storage layer: import photos into a CAS vault with
> dedup, and a columnar catalog fast enough to filter a six-figure library
> by full scan. Simulation-tested from day one. Both Capture One workflow
> shapes: the global catalog and self-contained sessions.
>
> **Definition of done:** `banksia import <dir>` ingests a card, dedups
> byte-identical files, and populates the catalog; a 100k-asset synthetic
> catalog filters by rating+lens in single-digit milliseconds; the crash
> simulator never loses an acknowledged blob across 10k randomized runs.

**Status: in progress.**

## 1. The filesystem seam (prerequisite for everything)

- [x] `wombat/vfs.zig`: comptime-interface filesystem — `real` backend
      (std.Io) and `sim` backend. Every wombat file operation goes through
      it; **nothing else in the codebase opens files for writing** (moved
      the CLI's PNG/DNG writes and the golden baseline write behind
      `wombat.vfs.user_file_write`; tidy ban: `createFile(` outside
      `wombat/vfs.zig`).
- [x] Sim backend: in-memory tree; injects crash points (power cut between
      any two ops), torn writes (prefix of a write survives), and directory
      entry reordering. All injection driven by integer `Ratio{num, den}`
      probabilities — no floats in the test substrate. *(also models name
      durability: an un-fsynced create or rename may not survive reboot
      until the parent dir is fsynced — this is what makes the vault's
      dir-fsync step testable rather than decorative)*
- [x] Seed plumbing: `-Dsim-seed=<u64>`, defaulting to the low 64 bits of
      the git commit hash (bottlebrush's `gitCommitSeed`), printed on every
      failure so any CI failure replays locally from the hash alone.

## 2. Blob vault

- [x] BLAKE3 content addresses (`std.crypto.hash.Blake3`); object layout
      `vault/objects/aa/bb/<hex>` (two shard levels).
- [x] Write path: hash → write to `vault/tmp/<hex>` → fsync file → rename
      into place → fsync directory. Idempotent: existing object = dedup
      hit, no write (held by a test counting sim operations).
- [x] Read path: optional verify-on-read (rehash and compare — the pair
      assertion with the write-side hash); always-on in tests and sim.
- [x] Crash-sim suite: 10k randomized import runs with injected faults;
      invariant — every blob the API acknowledged is fully readable after
      "reboot"; unacknowledged writes may vanish but never corrupt others.
      *(`zig build sim`, in CI; the sim binary always builds ReleaseSafe —
      asserts armed, 10k runs in ~16s where Debug BLAKE3 took 45 min.
      First run: 138,407 crashes, 512,243 acknowledged blobs, zero lost)*
- [x] `wombat gc`: unreferenced-object sweep (behind an explicit verb;
      nothing deletes implicitly). *(vault.gc with a referenced set; also
      sweeps tmp leftovers; CLI verb arrives with import in section 5)*

## 3. Chunking (for the few mutable big files)

- [ ] FastCDC: comptime gear table from fixed constants; min/avg/max
      256KiB / 1MiB / 4MiB; chunk index file mapping chunk hash → offsets.
- [ ] Applies to catalog snapshots and future exports only — RAW blobs are
      whole-file addressed (they never mutate, and distinct RAWs share no
      bytes; documented non-goal).
- [ ] Test: chunk boundaries are content-defined (insert 1 byte at the
      front of a 10MiB file → only leading chunks change), plus an
      exhaustive small-input sweep (0..~8KiB) against stored boundaries.

## 4. Columnar catalog

- [ ] `wombat/catalog.zig`: `std.MultiArrayList(Asset)` — hash handle
      (u32 into a blob-hash side table), recipe_head (u32), capture_time
      (i64), rating (u3), packed flags, camera/lens ids (u16 interned),
      iso (u32), burst_group (u32, Phase 4), sharpness (f16, Phase 4).
- [ ] Interning tables: string → u16 id, id → string; serialized with the
      snapshot.
- [ ] Persistence: snapshot file (header + per-column sections + BLAKE3
      trailer) + WAL of append-only records (add_asset, set_rating,
      set_flags, …). Open = load snapshot, replay WAL; `compact` folds the
      WAL into a fresh snapshot. All through the vfs seam → crash-sim
      covers torn WAL tails (a torn record is truncated, never applied
      half-way).
- [ ] Filter engine: predicate → columnar scans touching only named
      columns; `zig build bench` builds a 100k synthetic catalog and
      times rating+lens filters in ReleaseFast.

## 5. Sessions and import

- [ ] Session = self-contained directory (`vault/`, `catalog`, `wal`)
      scoped to one shoot; `banksia session new <dir>`; a session is
      portable (relative paths only).
- [ ] `banksia import <dir> [--session <dir>]`: walk, hash, dedup, blob
      write, metadata extract (from the DNG tags emu already parses),
      catalog append. Progress line per 100 files; summary with dedup
      count.
- [ ] Thumbnail cache: emu preview renders (edge 256) stored in the CAS
      keyed by (blob hash, recipe hash, engine version, edge) — the first
      use of the render-cache pattern Phase 3 generalizes.

## Tests

- Crash-sim (10k seeded runs) — the phase's hard gate, in CI.
- Vault roundtrip + verify-on-read pair assertion; dedup idempotence.
- Chunker: content-defined boundary property + exhaustive small sweep.
- Catalog: WAL replay = in-memory state (property test over random op
  sequences, seeded); torn-tail recovery; snapshot/restore identity.
- Bench: filter latency number printed in CI (regression = >2x the
  recorded budget; update the budget in this file with the measured
  value).

## Exit criteria

- [ ] Import a synthetic 1000-file card twice: second run dedups 100%.
- [ ] 100k-asset filter (rating ≥ 4 AND lens = X) in < 10ms ReleaseFast on
      the CI runner (record actual: ___).
- [ ] 10k crash-sim runs, zero acknowledged-data loss, in CI.
- [ ] Nothing outside `wombat/` opens a file for writing (tidy-enforced).

## Learnings

*(recorded as the phase runs)*
