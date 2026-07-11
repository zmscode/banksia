# Capture One 16.7.3 image-curve defaults

Inspected build: `16.7.3.31` (`8ec6a0c5c0fabd9043f2a55c94cd239916f9ce76`),
arm64 slice of `ImageCore.framework`.

## Result

Capture One does not have one universal default image curve. Its default curve
choice is `Auto`, backed by a camera-specific `.fcrv` file. For ordinary RAW
cameras, `Auto` is generally the camera's `Film Standard` curve with the same
control points and an additional flag bit:

- `Auto`: flags `0x23` (`35`)
- explicitly selected `Film Standard`: flags `0x03` (`3`)

For example, the Canon EOS 5D Mark II and Sony A7R V `Auto` files differ from
their `Film Standard` counterparts at only the serialized flags byte. Their
curve points are byte-for-byte equivalent.

The installed database contains:

- 4,095 `.fcrv` files;
- 661 camera/file-format `Auto` curves;
- 656 case-insensitive `Film Standard` curves;
- 661 `Linear Response` curves;
- 1,188 Fuji `.P1X` variants.

`Linear Response` is the identity `(0,0) → (1,1)` in all three components in
the cameras sampled. It is not Capture One's normal default.

## Curve model recovered from ImageCore

Ghidra identifies the following exported entry points:

| Address | Symbol | Purpose |
|---:|---|---|
| `0x003134a8` | `POFilmCurveCreateFromFile` | Parse an `.fcrv` file |
| `0x0031139c` | `CreatePOFilmCurve(unsigned char const*, unsigned int)` | Internal deserializer |
| `0x0031690c` | `DeserialiseFilmCurveData<...tuple<double,double>...>` | Decode control-point pairs |
| `0x00313754` | `POFilmCurveGetCurve` | Main film-response curve |
| `0x00313760` | `POFilmCurveGetCCDCurve` | CCD/pre-curve |
| `0x0031376c` | `POFilmCurveGetContrastCurve` | Contrast curve |
| `0x01555efc` | `POGradationCurveGetNumberOfPoints` | Point count |
| `0x01555f1c` | `POGradationCurveGetXAtIndex` | Point input coordinate |
| `0x01555f5c` | `POGradationCurveGetYAtIndex` | Point output coordinate |

The format begins with `II` or `MM`, followed by a 32-bit version. Current
files are version 6. Each film-curve object contains three independent
gradation curves. The deserializer first reads a vector of `(double x, double
y)` pairs, then flags, name, description, and version-dependent fields. On
disk, each coordinate is an unsigned 32-bit fixed-point value; Ghidra recovers
the exact conversion `coordinate * 2.3283064370807974e-10` (approximately
`coordinate / 2^32`). The gradation object expands each point to a 48-byte
internal record and computes interpolation coefficients.

The top-level defaults are also distinct:

- `IC_GetDefaultProcessSettings` calls
  `CDefaultProcessSettings::GetForReducedSettings`;
- `IC_GetDefaultImageProcessSettings` calls
  `CDefaultProcessSettings::GetForImageProcessSettings`;
- `IC_GetDefaultCameraProcessSettings` calls
  `CImgCore::GetDefaultCameraProcessSettings` with the decoded RAW image and
  its camera/product identifier.

That last path is why a camera model is required to obtain the actual default
curve.

## Canon EOS 5D Mark II default (`Auto` / `Film Standard`)

Main film curve:

```text
(0, 0)
(0.03947368404815758, 0.05201673927996697)
(0.07017543843718604, 0.12117326052886743)
(0.12061403508312396, 0.24535355536391809)
(0.25219298229836695, 0.53084535257212007)
(0.34868421041143227, 0.68178776457947399)
(0.40570175424350929, 0.75114764267372613)
(0.47587719291352604, 0.82053309046210099)
(0.54605263135071203, 0.87423258481412958)
(0.63377192980464825, 0.92254738694116178)
(0.77412280691185098, 0.97044523339030453)
(1, 1)
```

CCD/pre-curve:

```text
(0, 0)
(0.03947368404815758, 0.07915567259284567)
(0.07017543843718604, 0.14775725573947590)
(0.12061403508312396, 0.24802110815607503)
(0.25219298229836695, 0.49340369377597321)
(0.34868421041143227, 0.64379947228445655)
(0.40570175424350929, 0.71767810003777921)
(0.47587719291352604, 0.79419525056010931)
(0.54605263135071203, 0.85488126633103967)
(0.63377192980464825, 0.91029023726244696)
(0.77412280691185098, 0.96569920842668489)
(1, 1)
```

Contrast curve:

```text
(0, 0)
(0.06359649101821624, 0.03957783618000751)
(0.25219298229836695, 0.25065963045942125)
(0.31359649107642390, 0.32717678098175135)
(1, 1)
```

## Sony A7R V default (`Auto` / `Film Standard`)

Main film curve:

```text
(0, 0)
(0.04824561394011732, 0.09776950746257079)
(0.09649122788023465, 0.24816234741549995)
(0.16885964902324127, 0.45341580278552507)
(0.24999999982537702, 0.62380353794987398)
(0.36842105243551104, 0.77871072706270750)
(0.50219298235657461, 0.87795232093845310)
(0.62061403496670864, 0.93116124624646301)
(0.75438596488777221, 0.96791738410664663)
(0.86842105255192636, 0.98625441151351068)
(1, 1)
```

CCD/pre-curve:

```text
(0, 0)
(0.04824561394011732, 0.12401055407803752)
(0.09649122788023465, 0.24802110815607503)
(0.16885964902324127, 0.42216358832599676)
(0.24999999982537702, 0.58575197881687247)
(0.36842105243551104, 0.74934036930774817)
(0.50219298235657461, 0.86015831117056274)
(0.62061403496670864, 0.92084432717432374)
(0.75438596488777221, 0.96306068589050808)
(0.86842105255192636, 0.98416886524860026)
(1, 1)
```

Contrast curve:

```text
(0, 0)
(0.09429824540724471, 0.06860158291379959)
(0.24999999982537702, 0.25065963045942125)
(1, 1)
```

## Reproducing an extraction

The companion extractor uses only the interfaces recovered above:

```sh
clang -std=c17 -Wall -Wextra -Werror \
  tools/extract-capture-one-curves.c -o /tmp/extract-c1-curves
codesign --force --sign - \
  --entitlements tools/reverse-engineering.entitlements \
  /tmp/extract-c1-curves
export DYLD_LIBRARY_PATH='/Applications/Capture One.app/Contents/Frameworks'
export DYLD_FRAMEWORK_PATH='/Applications/Capture One.app/Contents/Frameworks'
/tmp/extract-c1-curves \
  '/Applications/Capture One.app/Contents/Frameworks/ImageCore.framework/Versions/A/ImageCore' \
  '/Applications/Capture One.app/Contents/Frameworks/ImageProcessing.framework/Versions/A/Resources/FilmCurves/CanonEOS5DMk2-Auto.fcrv'
```

The extractor prints metadata and CSV rows for `film`, `ccd`, and `contrast`.
Passing the whole `FilmCurves` directory instead of one file exports every
`.fcrv` in a single ImageCore process; each CSV row includes its source path.
