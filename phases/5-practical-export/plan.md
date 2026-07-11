# Phase 5 — practical export and the first completed shoot

**Objective:** add the encoding, resizing, metadata, naming, batching, and
recovery features required to deliver a real job.

This phase is the first end-to-end product milestone.

## User outcome

A photographer can cull and develop a shoot, then export full-resolution and web
JPEGs safely without another editor.

## Dependencies

- Phase 4 develop gates.
- Persistent selections and recipes.
- Deliberate JPEG codec and licensing decision.
- Wombat atomic-write discipline.

## Work items

### 5.1 Define output recipes

- [ ] Separate develop recipes from output recipes.
- [ ] Version and canonicalize output recipes.
- [ ] Include format, quality, resize policy, upscaling policy, colour space,
  output sharpening, metadata policy, naming template, and destination policy.
- [ ] Content-address named presets.
- [ ] Ship full-resolution JPEG, 2048px web JPEG, and archival PNG presets.
- [ ] Keep built-in presets immutable and user presets separate.
- [ ] Validate incompatible settings before queue creation.

### 5.2 Integrate JPEG deliberately

- [ ] Select a maintained encoder.
- [ ] Record licence, revision, packaging, and security-update policy.
- [ ] Support 8-bit sRGB JPEG first.
- [ ] Add bounded quality controls and a conservative default.
- [ ] Preserve PNG as a lossless diagnostic output.
- [ ] Defer 16-bit TIFF unless needed by the acceptance workflow.
- [ ] Validate dimensions, stride, channel order, and codec limits.
- [ ] Test decoded pixels semantically if byte determinism is unavailable.

### 5.3 Add high-quality resize and output sharpening

- [ ] Fit-within, width, height, and long-edge policies.
- [ ] Preserve aspect ratio.
- [ ] Do not upscale by default.
- [ ] Add explicit upscale opt-in.
- [ ] Select and version a photographic resize filter.
- [ ] Perform filtering in the correct light domain.
- [ ] Add off/low/standard scale-aware output sharpening.
- [ ] Test ringing and halos.

### 5.4 Define export metadata policy

- [ ] Preserve approved capture time, camera, lens, exposure, focal length, ISO,
  creator, and copyright.
- [ ] Apply orientation to pixels and write exported orientation as normal.
- [ ] Strip GPS from web presets by default.
- [ ] Add keep-GPS and strip-all modes.
- [ ] Do not copy private maker notes blindly.
- [ ] Write Banksia version and output-recipe identity where appropriate.
- [ ] Test with at least two independent metadata readers.

### 5.5 Implement safe naming and destinations

- [ ] Filename templates using original stem, sequence, date, session, rating,
  and preset.
- [ ] Sanitize separators and unsupported characters.
- [ ] Preflight all output collisions.
- [ ] Support fail, skip, overwrite, and unique-suffix policies.
- [ ] Default to fail or unique suffix; never silently overwrite.
- [ ] Write temporary file, fsync, rename, and sync directory as required.
- [ ] Remove temporary files after cancellation.
- [ ] Produce JSON and human-readable export manifests.

### 5.6 Build the batch queue

- [ ] Export current asset, explicit selection, or filtered set.
- [ ] Snapshot selection and recipes at queue creation.
- [ ] Bound worker count by measured memory per render.
- [ ] Reuse one developed image for multiple outputs when safe.
- [ ] Otherwise reuse only proven shared cache prefixes.
- [ ] Report file, outputs, elapsed time, and estimated remaining time.
- [ ] Cancel at safe boundaries.
- [ ] Retry failed outputs without duplicating successes.
- [ ] Continue after per-file failure unless destination integrity is unsafe.
- [ ] Prevent sleep during active export and release the assertion on exit.

### 5.7 Add UI and CLI export clients

- [ ] Export sheet with destination, names, dimensions, format, and metadata
  preview.
- [ ] Keyboard-accessible preset selection.
- [ ] Disk-space and collision warnings.
- [ ] Background queue view.
- [ ] CLI export by selection, rating, and multiple presets.
- [ ] Stable JSON summary for automation.
- [ ] UI and CLI share the same parser, queue, naming, and encoder code.

### 5.8 Complete the real-shoot rehearsal

- [ ] Select a real supported shoot with at least 100 frames.
- [ ] Preserve an external untouched source copy.
- [ ] Create a clean Banksia session.
- [ ] Import, cull, develop, crop, and export entirely in Banksia.
- [ ] Produce full-resolution and web JPEG sets.
- [ ] Inspect every output for orientation, dimensions, colour, metadata, naming,
  and corruption.
- [ ] Reopen the session and repeat export.
- [ ] Record every workaround or external-editor escape.
- [ ] Fail the phase if another RAW editor is needed to deliver the shoot.

## Tests

- [ ] Canonical output-recipe roundtrip.
- [ ] Resize and aspect-ratio properties.
- [ ] Path-safe deterministic names.
- [ ] Preflight collision detection.
- [ ] Metadata inclusion/exclusion matrix.
- [ ] Worker count respects memory ceiling.
- [ ] Cancellation never publishes a partial file.
- [ ] JPEG encode → independent decode comparison.
- [ ] Flat, gradient, detail, noise, saturated, odd-dimension cases.
- [ ] Sharpening-off identity and halo limits.
- [ ] One source/multiple presets equals separate direct exports.
- [ ] Kill at each output write point.
- [ ] Destination-full, permission, and disconnected-volume failures.
- [ ] Retry and manifest correctness.

## Exit criteria

- [ ] JPEG outputs decode in two independent implementations.
- [ ] Full and web presets pass image and metadata checks.
- [ ] Kill-mid-export never publishes a torn output.
- [ ] Default collision policy never overwrites silently.
- [ ] Queue cancellation stops workers within 2 seconds.
- [ ] Peak batch-export memory is ≤ 2.5 GiB by default.
- [ ] 100 × 24MP full-resolution quality-90 JPEG export reaches at least 20
  photos/minute on the reference Mac.
- [ ] Two-preset fan-out takes no more than 1.7× the single-preset time.
- [ ] The acceptance shoot is delivered entirely from Banksia.
- [ ] Repeated export after reopen is semantically identical.

## Risks

- JPEG integration becomes a packaging project.
- Parallelism can exceed memory.
- Metadata can leak private location information.
- Output sharpening can become an image-quality research project.
- Multi-output cache optimization can arrive prematurely.

## Non-goals

- CMYK and printer profiles.
- Soft proofing.
- HEIF, AVIF, or JPEG XL.
- HDR merge, panorama, or focus stacking.
- Print layout.
- Cloud delivery.
- GPU export.
- Advanced local editing.

---

---

[Back to the roadmap](../../plan-v2.md) · [Shared phase rules](../README.md)
