# Phase 2B initial RAW support profile

This profile describes the files Banksia intends to support during Phase 2B. It
is deliberately narrower than DNG and LibRaw's full capabilities. A valid file
outside the profile must fail with a named `Unsupported*` error rather than be
reported as malformed.

## Initial workflows

1. **Adobe DNG Converter output** from Bayer cameras, when the converted file
   matches the technical profile below. Adobe conversion is an accepted
   temporary ingestion workflow for private-alpha testing.
2. **Camera-native Bayer DNG** matching the same profile.
3. **Canon EOS-1D X Mark II CR2 and Canon EOS R3 CR3** through the LibRaw
   sensor-mosaic backend. ImageIO is the local developed-RGB visual oracle.

## Technical profile

| Area | Phase 2B initial support |
|---|---|
| Container | Native TIFF/DNG; LibRaw-backed CR2 and CR3 |
| Raw image | One CFA raw IFD |
| CFA | 2×2 Bayer (RGGB, BGGR, GRBG, or GBRG) |
| Samples | One sample per pixel, 16-bit storage |
| Compression | Native DNG uncompressed/lossless JPEG; LibRaw CR2/CR3 unpack |
| Layout | Strips or tiles with bounded segment counts and dimensions |
| White balance | `AsShotNeutral`, with identity fallback while corpus policy is finalized |
| Geometry | TIFF `Orientation` 1–8; integer `ActiveArea`, `DefaultCropOrigin`, and `DefaultCropSize` |
| Levels | Scalar DNG or 2×2 LibRaw black/white maps |
| Colour | DNG colour matrices and calibration are not yet in the supported profile |
| Opcodes | Geometry/processing opcodes are not yet applied |

Fractional default-crop geometry is valid DNG but currently returns
`UnsupportedGeometry`; malformed or out-of-sensor rectangles return `Corrupt`.

## Unsupported valid features

The following are tracked as unsupported, not corrupt input:

- compression other than uncompressed or lossless JPEG;
- non-16-bit sample storage;
- non-Bayer CFA layouts, including X-Trans;
- fractional default-crop coordinates;

- unsupported lossless-JPEG modes;
- geometry or processing opcodes;
- linear DNG and multi-plane raw data;
- proprietary RAW containers outside the initial CR2/CR3 corpus, including NEF
  and ARW.

## Promotion rule

A camera/workflow becomes declared-supported only when the corpus manifest
records provenance, licence, SHA-256, expected dimensions/orientation/crop, and
relevant DNG features, and CI decodes and renders it successfully. Accidental
compatibility is not a support claim.
