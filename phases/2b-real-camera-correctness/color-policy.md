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
profile calibration signatures match. LibRaw-backed proprietary files use its
documented camera-RGB-to-XYZ matrix at the same sensor-mosaic boundary.

The implementation is based on Chapter 6 of Adobe's
[DNG specification](https://helpx.adobe.com/camera-raw/digital-negative.html).

## Working and output spaces

- Working space: scene-referred linear Rec.2020 with a D65 white point.
- Display conversion: linear Rec.2020 to linear sRGB.
- Encoding: the existing exact sRGB transfer function, once, during RGBA8
  packing.
- The macOS shell declares the resulting bytes as `CGColorSpace.sRGB`.

## Range and finite-value policy

Matrix stages preserve finite negative and above-one values. The engine-v2
default tone operation bounds its input to `[0, 1]`; final linear-sRGB packing
also clamps to `[0, 1]`, so negative and out-of-gamut channels clip at display
black and above-white channels clip at display white. Any non-finite value
created or received by a colour transform is replaced with zero before it can
reach output encoding.

This is a technical neutral baseline. A future camera look must be a separately
versioned operation rather than a silent change to this policy.
