# Banksia calibration data

`banksia-calibration-v1.sqlite3` is the immutable runtime calibration bundle for
Phase 2D's initial supported set. Runtime code reads this database; it never
queries a Capture One installation or the reverse-engineering workspace.

The bundle contains the complete extracted records Banksia wants to preserve
for the initial cameras and lenses:

- every camera default and sparse ISO property for Canon EOS-1D X Mark II and
  Canon EOS R3;
- both complete ProStandard ICC profiles, including original tag payloads,
  decoded XYZ/curve values, and lossless `mft2` tables;
- all film, CCD/pre-curve, and contrast points for both Auto film curves; and
- every flattened node and attribute for the three initial Canon lens profiles.

The source extraction remains an audit artifact under
`reverse-engineering/capture-one-extracted/`. Rebuild this compact runtime
bundle from the installed Capture One 16.7.3.31 files and that extraction with:

```sh
perl tools/build-calibration-data.pl
```

The script refuses to overwrite an existing database. Remove the old bundle
explicitly when intentionally publishing a new immutable version, and change
the bundle ID/schema version rather than silently replacing a released bundle.

Inspect the committed bundle with:

```sh
sqlite3 data/calibration/banksia-calibration-v1.sqlite3 \
  "SELECT key, value FROM bundle_metadata ORDER BY key"
```
