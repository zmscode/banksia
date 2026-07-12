# Capture One calibration adoption audit

Reviewed 2026-07-12 against the committed Capture One 16.7.3 extraction,
focused Ghidra reports, Banksia engine-v2 implementation, and Capture One's
published Base Characteristics, ProStandard, film-curve, and lens-correction
documentation.

## Decision

Banksia should become camera-, ISO-, and lens-aware, but must keep four
independent, versioned concepts:

1. a technically neutral camera matrix and as-shot white balance;
2. an optional nonlinear camera colour profile;
3. an independently selectable camera tone curve;
4. an optical profile interpolated from lens and capture metadata.

Engine v2 owns only the first item. Adding the other three silently would
change every historical render and mix technical correction with a creative
default.

## What Banksia does now

The proprietary RAW path identifies the camera and lens through LibRaw, uses
the camera-specific XYZ-to-camera table (inverted exactly once), applies the
recorded white-balance gains, neutralizes false colour at sensor-clipped
highlights, and converts through linear Rec.2020 to display sRGB. The Canon
EOS-1D X Mark II and EOS R3 therefore already receive different technical
camera transforms.

The 2026-07-12 audit found and fixed an XYZ-to-camera direction bug at the
LibRaw boundary. A real EOS-1D X Mark II render changed from a severe
magenta/cyan cast to plausible neutral colour, and the committed derived DNGs,
hashes, and provisional perceptual measurements were regenerated.

Lens model and ISO are currently descriptive metadata. Banksia does not yet
apply lens distortion, chromatic-aberration, falloff, diffraction, denoise, or
capture-sharpen calibration.

## What Capture One adds

The extracted records select these defaults for the current Banksia corpus:

| Camera | Input profile | Film curve | Base gain | Sensor-range gain |
|---|---|---|---:|---:|
| Canon EOS-1D X Mark II | `CanonEOS1DX2-ProStandard.icm` | `CanonEOS1DX2-Auto.fcrv` | 1.00 | 1.15 |
| Canon EOS R3 | `CanonEOSR3-ProStandard.icm` | `CanonEOSR3-Auto.fcrv` | 1.07 | 1.00 |

Both inspected ProStandard ICC profiles are RGB-to-Lab `A2B0` transforms with
a 33×33×33 CLUT, 1,025-entry input tables, and separate output tables. This can
perform saturation- and hue-dependent correction that a 3×3 matrix cannot.
Capture One selects its Auto film curve separately, so profile colour and tone
are not one operation.

Its camera database also supplies ISO-dependent read/shot-noise coefficients,
anti-colour-alias strength, sharpening, high-ISO cleanup, and fine-grain
defaults. The EOS-1D X Mark II extraction, for example, contains measured noise
coefficients and changes detail defaults at high ISO.

All three lenses in the initial corpus have measured profiles:

| Lens | Geometric/CA focal nodes | Falloff records |
|---|---:|---:|
| Canon EF 24–105mm f/4L IS II USM | 12 | 192 |
| Canon EF 24–70mm f/2.8L II USM | 5 | 95 |
| Canon EF 70–200mm f/4L IS USM | 4 | 77 |

The records vary by focal length, aperture, and where available focus distance,
with distortion, red/blue lateral chromatic aberration, falloff, and radial
detail correction represented independently.

## Safe implementation route

### Camera colour

- Define an immutable Banksia camera-profile format: matrix fallback, optional
  one-dimensional shaper curves, optional 3D LUT, supported illuminants,
  profile ID, version, and provenance.
- Build our own rights-cleared profiles from controlled chart captures. The
  extracted Capture One profiles are behavioral research evidence, not assets
  to redistribute or silently embed.
- Apply the nonlinear profile in a named, versioned renderer operation after
  neutral camera conversion. Keep tone response as a separate operation.
- Compare the bare matrix and candidate profile using chart ΔE00, neutral-axis
  checks, skin/saturated scenes, and blind preference tests.

### ISO/detail calibration

- Add a camera/ISO calibration schema for black/white behavior, a two-term
  noise model, defect cleanup, false-colour suppression, denoise, and input
  sharpening defaults.
- Interpolate only parameters whose calibration domain supports it; preserve
  explicit sensor-gain discontinuities.
- Keep these defaults reproducible through profile and renderer identities.

### Lens correction

- Extend decoded metadata with stable camera/lens identifiers, focal length,
  aperture, and focus distance before applying any profile.
- Define independent, bounded models for distortion, lateral CA, falloff, and
  corner/detail correction. Missing dimensions must disable or degrade a
  correction explicitly rather than guess.
- Interpolate a small rights-cleared, versioned lens dataset and include its
  profile identity in the render/cache key.
- Apply optical geometry before user crop, falloff in linear light, and detail
  correction only after the noise model exists.

## Placement

- Phase 2B remains the neutral matrix/white-balance correctness gate.
- Phase 4.7 may add a small profiled lens minimum when an acceptance shoot
  demonstrates the need.
- Branch B1 owns nonlinear camera profiles and their calibration/validation.
- Branch B4 owns expanded lens, denoise, and capture-sharpen processing.

The detailed reverse-engineering evidence remains in
[`capture-one-quality-techniques.md`](capture-one-quality-techniques.md) and
[`capture-one-image-curves.md`](capture-one-image-curves.md).
