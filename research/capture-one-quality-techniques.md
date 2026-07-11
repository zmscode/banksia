# Capture One 16.7.3 quality techniques

Inspected build: `16.7.3.31` (`8ec6a0c5c0fabd9043f2a55c94cd239916f9ce76`),
arm64 `ImageCore.framework`, `coreConfig.cdx`, `lensDatabase.cdx`, input ICC
profiles, and film-curve resources.

This report distinguishes direct evidence from inference. Symbol names,
decompiled control flow, constants, and decoded configuration values are direct
evidence. The photographic purpose assigned to an undocumented calculation is
labelled as an inference.

## Executive result

Capture One's quality does not come from one hidden tone curve or one unusually
good demosaic algorithm. The implementation shows a calibrated stack:

1. sensor cleanup before demosaic;
2. camera-specific Bayer or X-Trans reconstruction;
3. camera- and ISO-specific signal-dependent noise models;
4. camera-specific 3D-LUT input profiles;
5. a separate camera-specific film curve;
6. sharpening coupled to noise, colour gains, and optical information;
7. measured lens corrections indexed by focal length, aperture, and sometimes
   focus distance;
8. separate capture, creative, and output/detail operations.

The most transferable idea is not a particular default value. It is that
Capture One calibrates the early pipeline for the exact camera, ISO, and lens,
then applies creative controls later.

## 1. Camera- and ISO-specific defaults

`coreConfig.cdx` is XML obfuscated with a bytewise XOR of `0x81`. The decoded
database contains:

- 719 camera records;
- 7,590 ISO records;
- 4,385 measured `noiseFloorCoeff_ISO` entries;
- 2,133 measured `noisePoissonCoeff_ISO` entries;
- 2,871 sharpening-amount overrides;
- 1,863 anti-colour-aliasing overrides;
- 2,670 long-exposure-cleanup overrides;
- 2,425 fine-grain overrides.

The base defaults are:

| Parameter | Base value |
|---|---:|
| Colour NR amount | 50 |
| Colour/luma NR ratio | 1.6 |
| Luminance NR amount | 50 |
| Details | 50 |
| Capture sharpening amount | 160 |
| Capture sharpening radius | 0.8 |
| Capture sharpening threshold | 1.0 |
| Halo control | 0 |
| Anti-colour-aliasing blend | 0.5 |
| Normalized noise floor coefficient | 8.0 |
| Normalized Poisson coefficient | 0.8 |

These are fallbacks. A supported camera normally replaces several of them.

### Sony A7 III example

The Sony A7 III selects `SonyA7M3-ProStandard.icm` and
`SonyA7M3-Auto.fcrv`. Its detail defaults change with ISO:

| ISO | Sharpen amount | Radius | Threshold | Anti-alias blend | Long-exposure cleanup | Fine grain |
|---:|---:|---:|---:|---:|---:|---:|
| base | 180 | 0.8 | 1.0 | inherited | — | — |
| 1,600 | 160 | inherited | inherited | 0.50 | — | — |
| 3,200 | 140 | inherited | inherited | 0.75 | — | — |
| 6,400 | 120 | inherited | inherited | 1.00 | 20 | 10 |
| 12,800 | 100 | inherited | 1.5 | inherited | 40 | 20 |
| 25,600 | 80 | 1.0 | inherited | inherited | 60 | 30 |

Its measured noise-floor coefficient drops from roughly `0.031` at ISO 500 to
`0.00757` at ISO 640. That sharp discontinuity is consistent with accounting
for a dual-gain sensor mode rather than assuming noise changes smoothly with
the ISO label.

### Canon EOS 5D Mark II example

The 5D Mark II selects a ProStandard profile and Auto film curve, carries
separate floor and Poisson coefficients across its ISO range, and gradually
reduces sharpening from `180` to `140`. At high ISO it increases threshold,
long-exposure cleanup, fine grain, and sometimes luminance-noise offset.

### Why this matters

Capture One does not treat noise reduction and sharpening as independent
cosmetic sliders. As measured noise rises, it reduces sharpening, increases
anti-alias suppression and isolated-pixel cleanup, and adds controlled fine
grain rather than erasing all texture.

## 2. Camera colour is a 3D LUT, not just a matrix

The installation contains 1,402 input ICC profiles, including:

- 581 `Generic` profiles;
- 126 `ProStandard` profiles;
- many vendor looks and illuminant-specific Phase One/Leaf profiles.

The inspected Generic and ProStandard files are input-class RGB-to-Lab ICC
profiles with an `A2B0` `mft2` transform. They use three input channels, three
output channels, and a 33-point grid: a `33 × 33 × 33` three-dimensional CLUT,
with per-channel input/output tables.

This is much richer than a 3×3 camera matrix. It can correct hue twists,
saturation-dependent errors, and transitions through contrast gradients. The
film curve is selected separately, so colour characterization and tonal style
remain independent.

ImageCore also contains distinct gamut-compression, colour-management, camera
ICC, screen ICC, and output ICC operations. Its built-in working spaces include
`Capture One RGB 2024`, Phase One RGB variants, Adobe RGB, Display P3, sRGB,
and Rec. 2020.

## 3. Demosaic is sensor-specific and multi-stage

### Bayer

The full-resolution Bayer path has several versioned implementations:

- `BayerC1v2012_1`;
- `BayerC1v2012_2`;
- `BayerC1v2012_3`;
- a Sensor+ specialization;
- separate bilinear and quick-preview paths.

Recovered method names show the full path performs:

- white-balance-aware edge-direction estimation;
- green estimation using colour-sum ratios;
- green smoothing;
- red-at-blue and red/blue-at-green reconstruction;
- green-channel blur compensation;
- shadow-colour matching;
- optional chromatic-aberration computation/application during reconstruction;
- transfer from a simple demosaic as one input to a later refinement stage.

There is also a separate `AntiColorAliasing` operation whose blend is tuned by
camera and ISO. This is an important quality tradeoff: false-colour suppression
is increased at noisy ISOs while capture sharpening is reduced.

### Fujifilm X-Trans

X-Trans has a separate pipeline rather than a Bayer algorithm with a different
CFA table:

- green reconstruction along the flattest direction;
- refined 3×3 interpolation;
- 8×8 or 16×16 green re-interpolation/fix passes;
- separate chroma interpolation;
- black-offset removal and green rescaling;
- an explicitly named `ApplyOrganicLook` stage.

The chroma stage consumes the camera noise coefficients and chooses different
neighbourhood parameters at thresholds around values `70` and `90` of an
internal setting. This is direct evidence that X-Trans reconstruction adapts to
noise/detail policy.

## 4. Signal-dependent, colour-aware denoising

The modern luminance path is `CImgOpLumaNoise2018`. Ghidra shows it uses:

- a two-parameter noise model: floor/read noise plus a Poisson/shot-noise term;
- white-balance and per-channel gain scaling;
- 8×8 or 16×16 DCT filtering;
- directional measures;
- overlapping patch shifts drawn from fixed Poisson-disc patterns for 8, 16,
  and 32-pixel cases;
- block confidence weighting;
- a later spatial/detail reconciliation stage named `ApplySecretSauce`.

One recovered 8×8 block-weight expression is:

```text
weight = (p / 8) / ((p / 8 + block_measure) - abs(dc_component))
```

The setup computes effective noise after applying the RGB/WB gains and clamps
a directional preference to `[0.05, 1.0]`. If the camera noise model is absent
or invalid, it falls back to an ISO-derived estimate.

Colour noise is separate:

- `PreColorNoise2018` prepares the data;
- `ColorNoise2018` uses a parameterized bilateral-style filter;
- `ColorNoiseHighISO` is a distinct high-ISO path with its own weights and box
  filtering;
- spike/single-pixel reduction and hot-pixel correction are separate again.

This separation avoids the common failure mode where one denoiser trades away
colour fidelity, fine luminance texture, and isolated defect removal together.

## 5. Sensor cleanup happens before ordinary editing

The static-calibration code contains dedicated stages for:

- black clamp and several generations of `BlackClean`;
- flagged and automatically detected hot pixels;
- a hot-pixel NLM path;
- long-integration-time noise;
- row/column defects and gain relations;
- green-green equalization;
- chroma and luma calibration;
- adaptive moiré handling;
- saturation and blooming behavior.

Many camera subclasses override which calibration generation or sensor fix to
use. These are source-level corrections, not develop-tool adjustments applied
after demosaic.

## 6. Highlight recovery uses RAW channel headroom

`CImgOpClippingRecovery::SetParameters` uses:

- the RAW representation's saturation/clip value;
- per-channel gains;
- white-balance factors;
- camera-specific recovery parameters;
- a safety point at `clip × 0.9659363`;
- separately calculated channel recovery slopes.

The control response includes:

```text
2 ^ (control × 0.01 - 0.3)
```

This is not a single luminance shoulder applied to rendered RGB. It prepares
channel-specific recovery from sensor headroom before later HDR/creative
controls. The exposed Highlight, Shadow, White, and Black tools are separate
operations.

## 7. Capture sharpening is coupled to optics and noise

ImageCore has separate `CaptureSharpening` and `UnsharpMaskLinear` operations.
The capture path contains:

- luminance extraction and multi-band splitting;
- symmetric convolution, Gaussian, and box filters;
- cross-term construction;
- a solver and `applySolution` stage;
- transfer of reconstructed luminance back to colour;
- sensor-noise and RGB/WB-gain inputs.

Its parameter setup also consumes aperture-like data constrained to approximately
`1…50`, builds a 4,000-element table, integrates samples across wavelengths
`461…619`, and evaluates roughly 500 frequency positions. The use of visible
wavelengths, aperture, and a solved filter strongly suggests a physically
motivated diffraction/PSF model with regularization. That interpretation is an
inference, but the constants and solver structure are direct evidence.

The practical lesson is stronger than the exact formula: capture sharpening is
noise- and optics-aware. It is not the same operation as creative or output
unsharp masking.

## 8. Lens correction is measured in several dimensions

`lensDatabase.cdx` uses the same XOR encoding and contains 901 lens records:

- 4,340 geometric-aberration curves;
- 3,538 red/blue chromatic-aberration curve sets;
- 57,255 light-falloff records;
- 701 radial and 701 transverse blur/correction records;
- dependencies on focal length, aperture, and frequently focus distance.

For example, the Canon EF 11–24mm profile has independent geometric shift
curves by focal length, red/blue shift curves by focal length and aperture, and
falloff curves across focal length and aperture. ImageCore interpolates these
using spline-based profile correction and has separate operations for radial
blur, chromatic aberration, light falloff, and purple-fringe suppression.

This avoids treating distortion, vignetting, chromatic aberration, and corner
sharpness as one generic radial coefficient set.

## 9. Other quality-preserving design choices

- The engine keeps versioned processing semantics (`0x514`, or 1300, is the
  current processing-method value seen in this build).
- Full-quality Bayer/X-Trans paths are separate from quick preview demosaic.
- Many colour-critical and reconstruction stages use normalized or ordinary
  32-bit float buffers.
- Dithering is an explicit operation rather than an incidental export detail.
- Capture sharpening, creative clarity/structure, grain, and output unsharp
  masking are independent stages.
- Local contrast has distinct Natural, Neutral, Punch, Classic, and Structure
  implementations rather than one radius-scaled filter.
- Sensor/source analysis and cached proxy/focus products are kept separate from
  the authoritative adjustment recipe.

## 10. Extracted calibration corpus

`tools/extract-capture-one-calibration.pl` turns the installed resources into a
queryable SQLite corpus. The validated extraction contains:

| Table | Rows |
|---|---:|
| cameras | 719 |
| camera properties | 3,127 |
| camera/ISO properties | 24,120 |
| lenses | 901 |
| flattened lens nodes | 141,801 |
| lens attributes | 193,415 |
| ICC profiles | 1,402 |
| raw ICC tags | 11,154 |
| parsed ICC curve samples | 333,492 |
| parsed ICC `mft2` transforms | 1,414 |

The database preserves the original ICC tag payloads as blobs and separately
extracts XYZ values, sampled curves, 3×3 fixed-point matrices, input/output
tables, and complete CLUTs. Of the parsed `mft2` transforms, 1,405 are 3→3
with a 33-point grid; six use 65 points and three use 25 points.

The bulk film-curve export adds all 4,095 `.fcrv` files and 80,082 exact
control points: 33,570 film-response, 30,495 CCD/pre-curve, and 16,017 contrast
points. The generated `film-curves.csv` is about 14 MB.

This is exact data extraction, not a visual approximation. It does not turn
the compiled processing engine into maintainable source code. The focused
Ghidra output recovers constants, control flow, calls, and substantial
pseudocode, but compiler optimization removes names and types and several
large SIMD-heavy functions do not decompile cleanly. Reimplementing those
algorithms still requires tests against Capture One output and independent
engineering judgment.

## 11. Proxy files

Capture One 16.7 creates `.cop` files as standards-compliant JPEG XL
containers. The sample generated during this investigation contains ordinary
`JXL `/`ftyp`/`jxlp` boxes plus custom `C1pv` and `C1pm` boxes; `C1pm` begins
with the string `CaptureOneProxyMetadata`. macOS ImageIO can decode the image
while safely ignoring those private boxes.

`tools/capture-one-proxy-to-jpeg.sh` therefore converts a current `.cop`
directly to a quality-95 JPEG. The end-to-end test recovered a 3,456×2,304 RGB
JPEG from a 1.8 MB proxy.

`tools/capture-one-raw-to-jpeg.sh` takes a RAW path directly. It creates a
temporary session and JPEG recipe, calls Capture One's `process` AppleScript
command on a temporary copy of the RAW, waits for the asynchronous
render, and removes the temporary session. Keeping the processed path in the
temporary directory prevents Capture One from writing a `.cos` sidecar beside
the user's original RAW.
This is a full Capture One render rather than extraction of the RAW's embedded
preview. It was validated with a Canon CR2 at 3,525×5,288.

### Runtime requirements

- RAW-to-JPEG requires macOS, an installed and activated Capture One edition
  that supports the AppleScript `process` command, and Automation permission
  for the terminal or calling application to control Capture One. Capture One
  is launched automatically if necessary.
- `.cop`-to-JPEG requires only macOS `file` and `sips` for current JPEG XL
  proxies; it does not require Capture One once the proxy exists.
- Calibration extraction requires the Capture One installation plus Perl
  modules `DBI`, `DBD::SQLite`, and `XML::LibXML`.
- Re-running the film-curve binary extractor requires `clang`, `codesign`, and
  Capture One. Re-running the decompilation additionally requires Ghidra and
  Java 21. The committed reports and Ghidra output need none of these tools to
  be read.

ImageCore also retains an older `ProxyContainer2006` backend with 23 legacy
versions, two JPEG XR versions, and S-JPEG versions 1 and 2. Those containers
are not ordinary JPEG XL and the converter rejects them explicitly rather than
emitting a plausible but incorrect image.

## What Banksia should copy first

In likely order of visible benefit:

1. **A camera/ISO calibration schema.** Store black/white behavior, a two-term
   noise model, anti-alias strength, capture-sharpen defaults, and provenance.
2. **Camera-specific nonlinear input profiles.** Add 3D-LUT ICC/DCP-quality
   transforms rather than relying only on DNG matrices.
3. **A coherent detail pipeline.** Mosaic defect removal → edge-aware demosaic
   → chroma NR → luminance NR → capture sharpening, with parameters shared
   through one noise model.
4. **Measured lens models.** Interpolate distortion, CA, falloff, and corner
   sharpness independently over focal length/aperture/focus distance.
5. **Separate the profile and tone curve.** Preserve the camera colour mapping
   while allowing Linear, Standard, or other tonal responses.
6. **Preserve texture deliberately.** Reduce sharpening as ISO rises, use
   confidence-aware denoising, and add controlled grain only after cleanup.

The architectural takeaway is that the best default rendering is a coordinated
calibration problem. Individually good kernels will not match this result if
their assumptions about noise, colour, headroom, and optics disagree.

## Reproduction artifacts

- `tools/decode-capture-one-core-config.pl` decodes either `.cdx` XML database.
- `tools/extract-capture-one-calibration.pl` exports camera, ISO, lens, and ICC
  calibration data to decoded XML plus SQLite.
- `tools/extract-capture-one-curves.c` exports one curve or the complete curve
  directory; the latter was validated across all 4,095 `.fcrv` files.
- `tools/capture-one-proxy-to-jpeg.sh` converts current JPEG XL `.cop` proxies.
- `tools/capture-one-raw-to-jpeg.sh` renders a RAW directly through Capture One.
- `reverse-engineering/ghidra/capture-one-quality-decompiled.c` contains the
  focused Ghidra output.
- `reverse-engineering/ghidra/capture-one-proxy-decompiled.c` contains the
  focused proxy-backend output.
- `reverse-engineering/ghidra/DecompileCaptureOneCurves.java` can decompile
  additional symbols by substring.
- `research/capture-one-image-curves.md` contains the film-curve findings.
