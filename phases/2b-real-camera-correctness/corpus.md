# Phase 2B local RAW corpus

The developer supplied 27 RAW files under `assets/`. The approximately 813 MB
originals are intentionally ignored by Git; `corpus.sha256` identifies the exact
local files. This corpus is an optional compatibility/oracle corpus until its
licence is recorded and distributable DNG derivatives are produced.

## Camera groups

| Group | Files | Camera | Container | LibRaw mosaic | ImageIO output | Size |
|---|---:|---|---|---:|---:|---:|
| `assets/CR2/AM4I*.CR2` | 9 | Canon EOS-1D X Mark II | CR2 v2 | 5496×3670 | 5472×3648 | 233 MB |
| `assets/CR3/*.CR3` | 9 | Canon EOS R3 | ISO-BMFF CR3 | 6032×4032 | 6000×4000 | 250 MB |
| `assets/DNG/IMG_*.DNG` | 9 | Apple iPhone 15 Pro Max | DNG 1.6 LinearRaw | expected unsupported | 4032×3024 or 8064×6048 | 330 MB |

All 18 files unpack through LibRaw 0.22.1 to RGGB Bayer mosaics and decode
through macOS ImageIO to 16-bit, three-channel Display P3 RGB previews. The
combined hash + mosaic + preview gate completes in approximately 21.28 seconds.

The nine Apple files contain three-channel LinearRaw data rather than a CFA
mosaic. They intentionally return `UnsupportedLinearRaw`, which distinguishes a
valid out-of-profile DNG from malformed input. They cover ISO 64/100, 12 MP and
48 MP dimensions, and TIFF orientations 1, 3, and 6; ImageIO remains their
developed-RGB oracle.

Engine-v2 full-render smokes now cover one file from each camera group. LibRaw's
standard vendor crop and orientation produce 3648×5472 output for the portrait
CR2 and 4000×6000 for the portrait CR3, matching the corresponding ImageIO
dimensions after orientation. Both renders use LibRaw's documented
camera-RGB-to-XYZ matrix, Banksia's Bradford/D50 transform, linear Rec.2020
working space, and final sRGB encoding.

The CR3 filenames provide three scene/wardrobe groups: black strip, olive, and
emerald. The CR2 scene content, lens, ISO, orientation, and licensing terms still
need to be entered from a trusted metadata tool or capture notes.

## Role in Phase 2B

- **Canon EOS-1D X Mark II / CR2:** LibRaw sensor and render corpus.
- **Canon EOS R3 / CR3:** LibRaw sensor/orientation and ImageIO comparison corpus.
- **macOS ImageIO:** local visual oracle only; it returns developed RGB and is
  not Banksia's sensor-data path.
- **Apple iPhone 15 Pro Max DNG:** expected-unsupported LinearRaw compatibility
  corpus and ImageIO oracle; it does not expand Phase 2B's Bayer support claim.
- **CI:** hashes and manifest are committed, original files are not. A smaller
  licensed DNG corpus is still required for mandatory CI.

Run `zig build corpus` on a machine containing the local assets. It verifies all
27 SHA-256 hashes, unpacks and copies the 18 LibRaw sensor mosaics, checks all 9
LinearRaw files fail by their expected name, and decodes every file to a
temporary 1024px PNG through ImageIO.

## Provenance and licence gaps

- Provenance: supplied locally by the developer on 2026-07-11.
- Copyright/licence: not yet recorded; do not redistribute or commit originals.
- Capture settings: LibRaw provides timestamp, lens, and ISO; a committed
  per-file metadata export is still required.
- Oracle settings: current ImageIO output uses its default RAW development and
  Display P3 profile; exact neutral oracle settings remain to be produced.
