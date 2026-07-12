# Engine v2 baseline colour policy

Engine v2 follows the DNG 1.7.1 colour model without applying a camera look,
profile tone curve, hue/saturation map, or local contrast.

## Transform convention

For native DNG, Banksia uses the specification's matrix direction and order:

```text
XYZtoCamera = AnalogBalance × CameraCalibration × ColorMatrix
CameraToXYZ_D50 = Bradford(selected white → D50) × inverse(XYZtoCamera)
```

Dual-illuminant matrices are linearly interpolated in inverse correlated colour
temperature. Camera calibration matrices participate only when the camera and
profile calibration signatures match.

LibRaw-backed proprietary files use the same convention at the sensor-mosaic
boundary. LibRaw's historical `cam_xyz[camera][xyz]` field contains its
per-camera XYZ-to-camera table (the values `raw-identify -v` labels
`XYZ->CamRGB`) despite API prose describing a camera-to-XYZ conversion. Banksia
constructs that row-major XYZ-to-camera matrix and inverts it exactly once. A
boundary regression test freezes both the direction and array layout.

The implementation is based on Chapter 6 of Adobe's
[DNG specification](https://helpx.adobe.com/camera-raw/digital-negative.html).

## Working and output spaces

- Working space: scene-referred linear Rec.2020 with a D65 white point.
- Display conversion: linear Rec.2020 to linear sRGB.
- Encoding: the existing exact sRGB transfer function, once, during RGBA8
  packing.
- The macOS shell declares the resulting bytes as `CGColorSpace.sRGB`.

## Range and finite-value policy

Matrix stages preserve finite negative and above-one values. A neutral
engine-v2 tone operation is an identity in linear Rec.2020; clipping those
working-space channels before conversion to sRGB can manufacture false hues.
Final linear-sRGB packing clamps to `[0, 1]`, so negative and out-of-gamut
channels clip at display black and above-white channels clip at display white.

All engine-v2 camera paths receive a conservative highlight blend before
camera-to-working conversion. LibRaw-backed files use the Bayer-domain gains
already applied; native DNG uses `AsShotNeutral` to compare unbalanced camera
channels. The blend is bit-identical until at least two sensor channels enter
the top 20% of their range, then progressively removes false chroma as the
channels clip. This turns unrecoverable clipped illumination neutral rather
than magenta without collapsing a single legitimately saturated colour
channel. It does not invent lost sky detail. A later general highlight
reconstruction remains a separate renderer operation.

Any non-finite value created or received by a colour transform is replaced with
zero before it can reach output encoding.

This is a technical neutral baseline. A future camera look must be a separately
versioned operation rather than a silent change to this policy.
