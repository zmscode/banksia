# Phase 2B real-camera conformance

The synthetic golden suite remains the byte-exact regression oracle. Real-camera
reports are a second, perceptual layer and never replace those hashes.

## Oracle contract

`tools/real-camera-report.sh INPUT ROTATION_CW OUTPUT_DIRECTORY` renders engine
v2 with the committed `neutral-v2.json`, asks macOS ImageIO for its default RAW
development, physically applies the TIFF orientation, converts both images to
sRGB through CoreGraphics, then reports global luminance SSIM and sampled
CIEDE2000 median/p95. The deterministic sampling grid contains at most roughly
one million pixels.

ImageIO is a visual comparison, not a neutral colourimetric truth: it applies an
undocumented camera profile and tone rendering. Consequently its delta values
must not be compared with the controlled-chart gates. The provisional baseline
records the large expected difference honestly.

## Baseline review rule

`perceptual-baseline.json` starts as `provisional_pending_human_review`. A future
baseline may be marked `approved` only by a commit that records the reviewer,
date, reason, old/new metrics, and representative-image visual decision here.
Automated tooling and agents may produce candidate numbers but may not approve
them. Any approved regression requires the same recorded decision.

## 2026-07-12 matrix-boundary correction

The initial provisional derivatives and measurements were discarded after a
real CR2 visual check exposed a severe magenta/cyan cast. LibRaw's historical
`cam_xyz[camera][xyz]` table contains XYZ-to-camera coefficients, although its
API prose describes a camera-to-XYZ conversion. Banksia had consumed those
coefficients in the wrong direction.

The backend now constructs XYZ-to-camera using the actual array layout and
inverts it exactly once. The eight permission-covered DNG derivatives, their
source/render SHA-256 values, and all provisional ImageIO measurements were
regenerated after that fix. The baseline remains pending human review; the
replacement is a correctness repair, not an approval or creative preference.

The same visual audit exposed false magenta in sensor-clipped bridge, sky, and
water highlights. Engine v2 now keeps its neutral working-space tone operation
as an identity and applies a bounded, camera-range-aware highlight blend to
native DNG and LibRaw files before colour conversion. Pixels remain unchanged
until at least two camera channels enter the top 20% of sensor range;
unrecoverable clipped highlights converge toward neutral while single-channel
saturated colours remain intact. Exact render hashes and provisional metrics
were regenerated again after this repair.

## Compatibility rule

`compatibility.tsv` is append-reviewed evidence. A group may move from `pass` to
failure, or from an expected named rejection to a different result, only when a
decision identifier and explanation are committed with the change. The corpus
gate enforces the per-file hash, metadata, geometry, decode, and rejection facts
underlying the table.

## Controlled targets

No controlled grey-card or ColorChecker capture is available locally. Neutral-patch
and chart ΔE00 are therefore recorded as unavailable, not silently replaced by
ImageIO pixel differences. Their Phase 2B thresholds remain open until a rights-
cleared controlled capture is supplied.
