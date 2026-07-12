# Phase 2B local RAW corpus

The developer supplied 27 RAW files under `assets/`. The approximately 813 MB
originals are intentionally ignored by Git; `corpus.sha256` identifies the exact
local files and `corpus.tsv` records their per-file capture and render metadata.
The repository owner confirmed direct permission from the photographer on
2026-07-12. Originals remain an optional local compatibility corpus; eight
full-resolution Bayer-DNG derivatives form the committed required CI corpus.

## Required CI corpus

`tests/corpus/phase2b` contains eight deterministic derivatives from the two
Canon groups. Its manifest records each source, scenario, camera, lens, ISO,
storage, geometry, and permission; `corpus.sha256` pins every byte. The set
covers daylight, strong and warm backlight, high contrast, skin, neutral/black
fabric, saturated emerald, fine texture, ISO 1000/1600/12800, and landscape and
portrait orientations. It exercises uncompressed and lossless-JPEG DNG using
both strips and 512×256 tiles.

`zig build test-ci-corpus` uses the native DNG backend only. It verifies source
hashes and metadata, performs all eight full engine-v2 renders, and compares
dimension-framed RGBA bytes with committed SHA-256 baselines. This gate is part
of `zig build test` and therefore mandatory in CI.

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
emerald. The committed inventories record lens, ISO, capture time, sensor
geometry, crop, orientation, relevant format features, visually inspected scene
categories, and the photographer permission conveyed by the repository owner.

## Role in Phase 2B

- **Canon EOS-1D X Mark II / CR2:** LibRaw sensor and render corpus.
- **Canon EOS R3 / CR3:** LibRaw sensor/orientation and ImageIO comparison corpus.
- **macOS ImageIO:** local visual oracle only; it returns developed RGB and is
  not Banksia's sensor-data path.
- **Apple iPhone 15 Pro Max DNG:** expected-unsupported LinearRaw compatibility
  corpus and ImageIO oracle; it does not expand Phase 2B's Bayer support claim.
- **CI:** eight permission-covered DNG derivatives, their manifest, hashes,
  exact render baselines, and ImageIO comparison metrics are committed.

Run `zig build corpus` on a machine containing the local assets. It verifies all
27 SHA-256 hashes, requires the hash and metadata path sets to agree, checks 18
camera/lens/ISO/geometry records against Banksia's LibRaw boundary, completes a
full engine-v2 render for all 18 Canon files, checks all 9 LinearRaw files fail
by their expected name, and decodes every file to a temporary 1024px PNG through
ImageIO.

## Provenance and remaining coverage gaps

- Provenance: supplied locally by the developer on 2026-07-11; photographed by
  the repository owner's brother; unrestricted project use and redistribution
  permission confirmed by the owner on 2026-07-12.
- Permission wording: direct photographer permission, not relabelled as CC0;
  see `tests/corpus/phase2b/LICENSE.md`.
- Capture settings: the committed `corpus.tsv` records LibRaw's timestamp, lens,
  ISO, sensor size, orientation, and crop for every file. Scene classification
  remains incomplete where it cannot be established from capture notes.
- Oracle settings: all eight required DNGs have committed ImageIO/CoreGraphics
  settings and SSIM/CIEDE2000 measurements in `perceptual-baseline.json`.
- Deferred standardized coverage: tungsten, mixed light, a controlled grey
  card, and a ColorChecker. These are explicit follow-up improvements rather
  than hidden claims about the provisional corpus.
