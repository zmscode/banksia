# RAW editor image assessment and parameter survey

> A source-grounded review of how major open-source RAW editors and Capture One
> inspect images, derive automatic adjustments, choose defaults, and represent
> processing parameters.

**Research date:** 2026-07-11  
**Purpose:** inform Banksia's analysis model, recipe schema, defaults, and roadmap  
**Status:** completed from material gathered before the research stop request

---

## Executive summary

The strongest RAW editors do not use one universal “image assessment” algorithm.
They combine several layers:

1. **Capture metadata and sensor calibration**
   - black and white levels;
   - CFA layout;
   - active area and crop;
   - camera white balance;
   - camera-to-reference colour data;
   - ISO, shutter, aperture, and lens metadata.
2. **Camera- and ISO-specific defaults**
   - camera colour profiles;
   - default tone curves;
   - noise profiles;
   - capture sharpening;
   - lens corrections.
3. **Image-derived statistics**
   - RAW and rendered histograms;
   - clipping percentiles;
   - average or median log luminance;
   - colour-neutral estimates;
   - local contrast and edge energy;
   - noise estimates;
   - face, eye, and focus analysis in newer commercial tools.
4. **A versioned processing recipe**
   - explicit adjustment parameters;
   - processing-engine or module versions;
   - per-image sidecars or database records;
   - output recipes separate from develop settings.
5. **Human evaluation aids**
   - stage-specific histograms;
   - exposure warnings;
   - focus peaking/masks;
   - 100% loupe and synchronized compare;
   - ratings and colour labels.

The central lesson for Banksia is:

> Automatic assessment should produce explicit, inspectable recipe parameters.
> It should not be hidden inside rendering kernels.

A useful Banksia architecture should distinguish:

- immutable capture facts;
- derived analysis results;
- camera/profile defaults;
- user edits;
- output settings.

That distinction is more important than copying the exact formulas of any one
editor.

---

## Scope and evidence levels

It is not practical to audit every historical RAW editor. This review focuses on
the major active or technically influential projects for which meaningful source
or official documentation was available:

- darktable;
- RawTherapee;
- ART;
- Filmulator;
- vkdt;
- LibRaw/dcraw;
- digiKam and several historical editors at a higher level.

Capture One is proprietary. No legitimate public source tree for its RAW engine
was found. Capture One findings therefore come from:

- official Capture One documentation and release notes;
- its public AppleScript surface;
- documented sidecar/cache formats;
- ExifTool's open-source COS/EIP parser;
- clearly labelled third-party pipeline observations.

### Evidence labels

- **Source verified:** observed directly in a public repository.
- **Official:** stated in vendor/project documentation.
- **Reverse engineered:** inferred by inspecting outputs, histograms, or sidecars.
- **Inference:** architectural conclusion, not a confirmed implementation detail.

---

## Repositories inspected

| Project | Inspected revision |
|---|---|
| darktable | `78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d` |
| RawTherapee | `039b9b89d43315be6b42e8fbb33b8cfb39edd4bf` |
| ART | `da08e8d56e4a07f7eb0dbfa20b13c5c27f8fe397` |
| Filmulator | `57fbaec57555432d86d3aa632990cd8fa09114ad` |
| vkdt | `d166d05306a458536517f7fb6fe1509f11a84761` |
| LibRaw | `2751f9692d9401875551693e0c7c88e8b71db115` |

---

# 1. Common RAW-processing structure

Despite major implementation differences, the editors broadly perform these
stages:

```text
Container and metadata decode
→ sensor crop/orientation and black/white normalization
→ defective-pixel, dark-frame, flat-field, and CA preparation
→ white balance in mosaic/camera space
→ highlight handling
→ denoise and demosaic
→ camera profile / camera RGB to working colour space
→ exposure and scene-referred tonal operations
→ tone/display transform
→ colour editing and local adjustments
→ geometry and resize
→ output colour transform, sharpening, and encoding
```

The exact order matters. Moving one operation changes the meaning of its
parameters and the resulting pixels.

## 1.1 Parameters derived from the file

These should not normally be user-authored:

| Category | Typical parameters |
|---|---|
| Sensor | dimensions, active area, CFA, bit depth |
| Calibration | black level per site/channel, white level per channel |
| Capture | ISO, shutter, aperture, focal length, exposure bias |
| White balance | as-shot neutral or camera multipliers |
| Colour | camera matrix, calibration illuminants, profile identity |
| Geometry | orientation, default crop, pixel aspect |
| Lens | make/model, focal length, aperture, focus distance |
| Preview | embedded preview location, dimensions, orientation |

## 1.2 Parameters derived from analysis

These vary by algorithm and must carry an analysis-version identity:

| Analysis | Possible outputs |
|---|---|
| RAW histogram | per-channel clipping, black floor, headroom |
| Log-luma histogram | median/mean exposure, dynamic-range estimate |
| Auto levels | black and white percentiles per RGB/composite channel |
| Auto white balance | gains or temperature/tint plus confidence |
| Noise | signal-dependent coefficients and confidence |
| Focus | tile edge energy, relative burst score, focus overlay |
| Faces/eyes | regions of interest and eye state |
| Lens analysis | distortion, vignetting, CA estimate |
| Embedded-JPEG match | tone curve approximating the camera rendering |

## 1.3 User-controlled develop parameters

The common practical set is:

- exposure;
- white balance;
- highlights, shadows, whites, blacks;
- levels and curves;
- tone/display transform;
- saturation/vibrance;
- targeted hue, saturation, and lightness;
- crop, rotate, straighten, and keystone;
- denoise and sharpening;
- clarity/structure/local contrast;
- lens correction;
- masks and layer opacity.

## 1.4 Output parameters

Mature editors keep these separate from develop settings:

- format and bit depth;
- output ICC profile;
- pixel dimensions or scale policy;
- resampling method;
- output sharpening intent;
- metadata inclusion;
- naming and destination;
- watermark or overlay.

---

# 2. darktable

## 2.1 Processing model

**Source verified.** darktable implements a versioned image-operation pipeline.
Each operation has parameters, defaults, migration code, CPU processing, and in
many cases an OpenCL path.

Relevant modules include:

- `src/iop/rawprepare.c`;
- `src/iop/temperature.c`;
- `src/iop/demosaic.c`;
- `src/iop/denoiseprofile.c`;
- `src/iop/exposure.c`;
- `src/iop/channelmixerrgb.c`;
- `src/iop/filmicrgb.c`;
- `src/iop/sigmoid.c`;
- `src/iop/agx.c`;
- `src/iop/colorbalancergb.c`;
- `src/iop/colorin.c` and `colorout.c`.

This is the closest open-source reference for a deeply versioned modular RAW
pipeline.

## 2.2 Sensor preparation

`rawprepare.c` enables itself for supported, non-normalized RAW inputs. It owns
RAW crop and black/white normalization behavior rather than treating those as an
ordinary creative edit.

**Banksia lesson:** sensor normalization should be a required decode/render
stage with explicit metadata, not a user-visible optional exposure adjustment.

## 2.3 White balance and colour calibration

`temperature.c` applies per-channel camera-space coefficients and supports:

- as-shot values;
- camera reference values;
- spot selection;
- camera WB presets;
- Kelvin and tint conversion.

Modern scene-referred workflows pair this with the RGB colour-calibration /
channel-mixer module, which can estimate or select an illuminant and adapt camera
colour into the working space.

**Assessment inputs:** camera metadata, selected pixels/regions, camera presets,
and colour-space transforms.

## 2.4 Exposure assessment

`exposure.c` exposes manual exposure and black offset. Its deflicker mode builds
a source histogram, selects a percentile, converts that value to EV, and applies
correction toward a target level.

Verified defaults in the inspected source include:

- deflicker percentile: `50.0`;
- target level: `-4.0 EV`;
- optional exposure-bias compensation.

For scene-referred workflows the module's reload defaults may initialize a
non-monochrome RAW near `+0.7 EV` and a very small negative black offset. This is
a workflow default, not a claim that every image has been visually assessed as
underexposed.

**Important distinction:** darktable's normal default exposure and its deflicker
histogram measurement are separate concepts.

## 2.5 Demosaic selection

`demosaic.c` chooses methods according to CFA type:

- RCD is the inspected default for Bayer;
- Markesteijn for X-Trans;
- VNG variants for some Bayer4/special cases;
- passthrough/monochrome for monochrome sensors.

Optional parameters include:

- green equilibration;
- edge-aware median threshold;
- colour-smoothing passes;
- dual-demosaic threshold.

The UI describes RCD/PPG as fast, LMMSE as useful for high ISO, and dual methods
as blends with slower secondary demosaic output.

**Banksia lesson:** demosaic is a profile/quality choice, not an image-wide
“sharpness” parameter. Start with one reference and one production method.

## 2.6 Tone and dynamic-range assessment

### Filmic RGB

`filmicrgb.c` represents scene dynamic range using parameters such as:

- source black relative exposure;
- source white relative exposure;
- middle grey;
- latitude;
- contrast;
- shadow/highlight balance;
- colour-preservation method;
- dynamic-range safety factor.

Its auto controls inspect picked minimum, maximum, and grey values to derive
black and white exposure limits. They are picker-driven analysis operations, not
an opaque always-on auto-look.

### Sigmoid and AgX

darktable also offers sigmoid and AgX-style display transforms. The important
architectural point is that display rendering is an explicit module with
versioned parameters, rather than a hard-coded final S-curve.

## 2.7 Noise assessment

`denoiseprofile.c` uses camera noise profiles stored in
`data/noiseprofiles.json`. Profiles are indexed by camera and ISO and contain
per-channel coefficients commonly described as a signal-dependent model.
Profiles are interpolated for the image ISO.

The module supports wavelet and non-local-means variants and stores frequency- /
channel-specific strengths.

**Banksia lesson:** prefer a camera/ISO noise model such as
`variance = intercept + slope × signal` over a single universal ISO slider.

## 2.8 Focus and culling assessment

**Source verified.** darktable includes focus peaking in
`src/common/focus_peaking.h`, used by lighttable and preview views. It highlights
high-frequency edges for human inspection.

It does not make that overlay a trustworthy global sharpness rank. Ratings and
reject state remain user decisions.

**Banksia lesson:** ship an overlay before claiming automatic best-frame
selection.

## 2.9 What to borrow

- Version each operation and provide migration code.
- Keep stage-specific histograms and pickers.
- Represent scene dynamic range explicitly.
- Use camera/ISO noise profiles.
- Support a strict CPU path plus accelerated paths.
- Preserve human culling as the authority.

## 2.10 What not to copy initially

- The full breadth of modules.
- Multiple competing display transforms in the first release.
- A highly reorderable module graph before recipe semantics are stable.
- darktable's accumulated UI and compatibility complexity.

---

# 3. RawTherapee

## 3.1 Processing model

**Source verified.** RawTherapee uses a large parameter structure serialized to
`.pp3` processing profiles. It has a mostly fixed processing coordinator with
many specialized algorithms rather than darktable's freely visible module stack.

Important files include:

- `rtengine/procparams.cc` and `.h`;
- `rtengine/improccoordinator.cc`;
- `rtengine/rawimagesource.cc`;
- `rtengine/improcfun.cc`;
- `rtengine/histmatching.cc`;
- `rtengine/dcp.cc`;
- `rtengine/dynamicprofile.cc`.

## 3.2 Defaults and profiles

The base `ToneCurveParams` defaults observed in source include:

- auto exposure disabled;
- clipping parameter `0.02`;
- exposure compensation `0`;
- brightness `0`;
- black `0`;
- shadow compression `50`;
- highlight compression `0`;
- histogram matching disabled.

The default Bayer demosaic is AMaZE. The default X-Trans method is three-pass.
Fast preview/export paths substitute cheaper demosaic methods.

RawTherapee supports:

- default RAW/non-RAW profiles;
- `.pp3` sidecars;
- partial profile composition;
- dynamic profile rules matched on camera, lens, path, image type, ISO,
  aperture, focal length, shutter speed, and exposure compensation.

**Banksia lesson:** metadata-driven defaults are often more useful and
predictable than a universal auto-adjust button.

## 3.3 Auto exposure

`ImProcFunctions::getAutoExp` in `improcfun.cc` analyzes a compressed histogram.
It derives a collection of editable values rather than returning one opaque
“auto” state:

- exposure compensation;
- brightness;
- contrast;
- black;
- highlight compression;
- highlight-compression threshold.

The clipping parameter determines how much of the histogram may be ignored when
finding endpoints. The code includes safeguards against pushing the histogram
average too high.

This is a valuable model for Banksia:

```text
analysis(image, policy) → explicit recipe parameters
```

not:

```text
render(image, auto=true) → unexplained pixels
```

## 3.4 Camera-JPEG histogram matching

`histmatching.cc` is one of RawTherapee's most distinctive assessment features.
For a RAW file it:

1. extracts the embedded camera thumbnail;
2. generates a neutral RAW rendering using fast demosaic;
3. handles aspect-ratio/crop differences;
4. compares luminance distributions;
5. creates a tone curve approximating the camera JPEG rendering.

If no useful thumbnail exists, it returns a neutral curve.

**What this achieves:** a familiar camera-like starting point without attempting
to reverse-engineer every proprietary camera tone pipeline.

**Limitations:** it copies tonal distribution, not necessarily local tone,
colour appearance, sharpening, or noise behavior.

**Banksia opportunity:** offer “Match embedded preview tone” as an explicit,
optional starting recipe. Do not call it colour accuracy.

## 3.5 Auto white balance

RawTherapee contains multiple WB approaches:

- camera/as-shot;
- RGB-grey histogram averaging;
- spot/custom;
- a more complex temperature-correlation / ITCWB path.

Thumbnail and image-source code calculate RGB averages over eligible pixels and
convert multipliers to temperature/green values. The ITCWB path uses camera
reference information, histogram/chromatic statistics, and several heuristics.

**Banksia lesson:** begin with camera WB and a user-selected neutral region. A
general auto-WB algorithm requires a real, labelled illuminant corpus and
confidence reporting.

## 3.6 Colour management

RawTherapee supports:

- built-in camera matrices;
- ICC input profiles;
- DCP profiles;
- DCP colour matrices, hue/saturation maps, look tables, and illuminant
  interpolation;
- selectable working and output spaces.

`dcp.cc` constructs camera-to-XYZ D50 transforms based on WB and interpolates
profile data between illuminants.

This supports the conclusion that “good colour” is a combination of pipeline
math and substantial profile data.

## 3.7 Noise and detail assessment

RawTherapee includes robust noise estimation in denoise code, including median
absolute deviation of detail coefficients. It also has:

- impulse denoise;
- chroma/luma denoise;
- wavelet processing;
- capture sharpening;
- deconvolution sharpening;
- auto radius/contrast options;
- dark-frame matching by camera, ISO, shutter, and capture time;
- flat-field correction.

It is a good algorithm reference but also an example of how quickly a parameter
surface can become overwhelming.

## 3.8 What to borrow

- Auto analysis writes normal parameters.
- Embedded-JPEG tone matching.
- Metadata-driven dynamic profiles.
- DCP support and illuminant interpolation.
- Fast preview algorithms distinct from production algorithms.
- Dark-frame/flat-field matching as optional technical workflows.

## 3.9 What not to copy initially

- The very large monolithic parameter structure.
- Numerous overlapping sharpening, tone, denoise, and wavelet controls.
- Complex auto-WB heuristics without a validation corpus.
- UI exposure of every internal tuning parameter.

---

# 4. ART

## 4.1 Relationship to RawTherapee

ART is a RawTherapee-derived editor that deliberately changes workflow and tool
selection. Much decode, colour, DCP, and demosaic code is shared, but ART favors
a smaller, more integrated editing surface and extensive masking.

## 4.2 Distinct defaults and assessment

**Source verified:** in the inspected revision:

- Bayer demosaic defaults to RCD rather than RawTherapee's AMaZE;
- X-Trans defaults to three-pass;
- tone curves begin neutral/linear;
- histogram matching is available;
- camera and auto WB remain available;
- sharpening uses RL-deconvolution defaults and enables automatic deconvolution
  radius;
- noise routines include automatic strength calculations and robust estimates;
- log-encoding parameters can automatically compute scene white/black exposure
  ranges and gain.

ART's histogram matching includes additional handling such as dark-corner
assessment before matching the embedded thumbnail.

## 4.3 Local adjustments

ART stores masks alongside several tool parameter groups, including:

- local contrast;
- texture boost;
- smoothing;
- colour correction.

It also includes log encoding, tone equalization, spot removal, HSL tools, and
mask-aware processing.

**Banksia lesson:** a restrained set of tools that share one mask model is more
maintainable than making every module independently invent local-edit semantics.

## 4.4 What to borrow

- RCD as a practical production demosaic candidate.
- A smaller public control surface than RawTherapee.
- Automatic deconvolution-radius estimation as a later experiment.
- Shared mask representation across compatible operations.
- Log scene-range assessment producing explicit parameters.

---

# 5. Filmulator

## 5.1 Distinctive philosophy

Filmulator does not primarily assess an image and then select dozens of ordinary
sliders. Its central operation simulates aspects of film development.

The algorithm models:

- active crystals;
- crystal radius and growth;
- silver-salt density;
- developer concentration;
- developer consumption;
- diffusion;
- reservoir exchange;
- agitation;
- highlight crosstalk.

Bright regions consume developer locally, reducing subsequent development and
compressing large bright regions. Diffusion and reservoir behavior create a
spatially varying tone response.

## 5.2 Main parameters

Source-visible parameters include:

- initial developer concentration;
- reservoir thickness;
- active-layer thickness;
- crystals per pixel;
- initial crystal radius;
- developer-consumption constant;
- crystal-growth constant;
- development steps;
- agitation count;
- film area;
- layer mixing constants;
- rolloff boundary;
- toe boundary;
- highlight crosstalk.

The UI additionally exposes conventional controls such as:

- exposure compensation;
- temperature and tint;
- highlight recovery;
- post-filmulation black and white points;
- shadow/highlight curve points;
- vibrance and saturation;
- denoise and lens corrections.

## 5.3 Image assessment

Filmulator emphasizes before/after pipeline histograms. Its documentation tells
users to use the pre-filmulation histogram for exposure/highlight recovery and
the post-filmulation histogram for output clipping.

It generally disables LibRaw automatic brightness and keeps its central look
controlled by the film-development simulation rather than opaque auto exposure.

**Banksia lesson:** a strong default rendering can come from a coherent physical
or perceptual model, not necessarily from more auto sliders. However, Filmulator's
iterative spatial simulation is not the shortest route to Banksia's first
product.

---

# 6. vkdt

## 6.1 Processing model

vkdt is a Vulkan-first graph processor. Modules are GPU compute nodes connected
by an explicit graph. RAW files use a default graph, but users can customize the
graph and module order.

A representative RAW graph is:

```text
i-raw
→ denoise / black-white normalization
→ highlight handling
→ demosaic
→ crop/lens
→ colour
→ film curve / display transform
→ local-Laplacian or other creative modules
→ display/output
```

## 6.2 RAW and colour parameters

The RAW input uses rawspeed or rawloader. Metadata supplies:

- black and white levels;
- CFA;
- white balance;
- colour matrix;
- exposure metadata;
- noise-profile identity.

The `colour` module applies:

- camera white balance;
- camera colour matrix;
- gamut correction;
- optional profiled radial-basis colour correction.

## 6.3 Noise assessment

vkdt's denoise path uses a signal-dependent model documented in shader code as:

```text
variance = a + signal × b
```

Noise-profile tooling can estimate, inspect, and install profiles. Denoise can
run before or after demosaic, and the module also owns RAW black subtraction and
white normalization in the default graph.

## 6.4 Exposure assessment

vkdt includes a GPU auto-exposure module that builds a log-luminance histogram
across a wide range and derives an average luminance/exposure result.

Its ordinary exposure module remains explicit and simple: exposure correction in
stops.

## 6.5 Tone and display

The `filmcurv` module provides a display/tone curve with parameters for light,
contrast, bias, and colour-reconstruction mode. Modes include approaches based
on darktable UCS, HSL, Munsell data, and AgX-like behavior.

## 6.6 Focus and culling

vkdt supports star ratings and a GPU lighttable. It includes focus-related
operations for blending/focus stacking, but those are not equivalent to a
validated automatic culling rank.

## 6.7 What to borrow

- GPU graph as evidence that RAW processing maps well to compute kernels.
- Signal-dependent noise profiles.
- GPU histograms and analysis.
- Half-resolution demosaic paths.
- Keeping exposure as a simple explicit stop value even when auto exposure
  computes it.

## 6.8 What not to copy initially

- GPU-only product dependency.
- Arbitrary graph editing before stable recipe semantics.
- Maintaining many experimental display/ML modules.

---

# 7. LibRaw and dcraw

LibRaw is primarily a decode and baseline post-processing engine, not a complete
modern editor. It remains important because many editors use it for camera
compatibility.

## 7.1 Inputs and parameters

The dcraw-style processing API includes concepts such as:

- camera or auto white balance;
- user channel multipliers;
- black and saturation overrides;
- demosaic quality;
- median-filter passes;
- denoise threshold;
- highlight mode;
- output colour space/profile;
- gamma/tone settings;
- automatic brightness and clipping;
- exposure shift and highlight preservation;
- half-size and document modes.

## 7.2 Role in Banksia

Use LibRaw for:

- proprietary format breadth;
- metadata extraction;
- a decode fallback;
- comparison/oracle behavior;
- camera-compatibility testing.

Do not treat LibRaw's baseline output as the final Banksia look. Its job should
end at a validated sensor/camera-space contract wherever practical.

---

# 8. Other open-source editors

## digiKam / Showfoto

digiKam is primarily a digital-asset manager and general image editor. Its RAW
import is backed by LibRaw and exposes decode controls such as demosaic,
white-balance, colour management, noise reduction, and brightness. It is more
useful to Banksia as a DAM/interoperability reference than as a state-of-the-art
RAW rendering reference.

## PhotoFlow

PhotoFlow explored a non-destructive node/layer pipeline with high-bit-depth
processing and rawspeed/LibRaw integration. It is technically relevant to layer
and graph design but is not the primary active benchmark for current camera
support or culling workflows.

## LightZone

LightZone is historically important for zone-based tonal editing and region
masks. Its “ZoneMapper” demonstrates a user-facing tonal model based on visual
zones rather than low-level curve parameters. It is less useful as a current RAW
compatibility or performance reference.

## UFRaw and dcraw frontends

UFRaw exposed dcraw parameters through a GUI and sidecars. It is historically
important, but its pipeline and colour defaults should not define a new editor.

## Rawstudio and similar inactive projects

These projects demonstrate early non-destructive sidecars and batch workflows,
but current Banksia decisions should be based on active darktable,
RawTherapee/ART, vkdt, LibRaw, and contemporary commercial behavior.

---

# 9. Capture One

## 9.1 Source-code availability

No legitimate public Capture One RAW-engine source code was found.

What is public:

- official user and release documentation;
- an AppleScript/JXA automation dictionary;
- plugin/export integration behavior;
- XML-based `.cos` settings files;
- EIP package structure;
- cache and sidecar naming;
- ExifTool's open-source parser for COS and EIP files.

What is not public:

- demosaic implementation;
- colour-profile generation method;
- tone/HDR algorithms;
- focus-mask formula;
- denoise and sharpening kernels;
- exact processing graph.

Any repository claiming to contain Capture One Pro source should be treated as
untrusted and potentially unauthorized. It is not a sound basis for Banksia.

## 9.2 Sidecars and caches

**Official and open-source verified:**

- EIP is a ZIP package containing an image and settings files.
- COS files are XML-based and often encode settings as key/value attributes.
- ExifTool dynamically exposes COS properties and recognizes a large
  `ColorCorrections` value payload.
- `.cos` stores adjustments.
- `.comask` stores layer-mask data.
- `.icm` stores custom ICC profiles.
- `.cop` is a preview cache.
- `.cot` is a thumbnail cache.
- `.cof` stores Focus Mask information.
- `Settings###` directories correspond to processing/settings generations.

This confirms that Capture One separates authoritative settings from disposable
previews and focus-analysis caches.

## 9.3 Base Characteristics

**Official.** After demosaic, Capture One selects:

- a camera-specific input ICC profile;
- an associated film/tone curve;
- a processing engine.

Profile families include:

- camera-specific Generic profiles;
- ProStandard profiles;
- specialized e-commerce/reference profiles;
- camera/vendor looks such as Fujifilm simulations;
- generic DNG profiles for unsupported DNG cameras.

Capture One states that its profiles balance quantitative correctness with a
pleasing result.

### ProStandard intent

Official documentation describes ProStandard as improving:

- hue preservation through contrast gradients;
- colour transitions between hues;
- consistency across camera models;
- skin and saturated-colour rendering.

### Film curves

Documented choices include:

- Auto;
- Film Standard;
- Film Extra Shadow;
- Film High Contrast;
- Linear Response;
- Linear Scientific for supported technical workflows.

Film Standard behaves like an S-curve. Linear Response retains a small highlight
rolloff. Linear Scientific removes that rolloff for profiling/scientific use.

**Banksia lesson:** the camera profile and default tone curve should be separate,
immutable dependencies. A camera profile alone does not define the whole look.

## 9.4 Processing-engine versioning

**Official.** New images use the latest engine. Existing variants are not
silently upgraded. Legacy engines remain available. Upgrading is explicit and
Capture One recommends cloning important variants first because results and tool
behavior may change.

This is weaker and more practical than “bit-identical forever.”

**Banksia lesson:** preserve old semantics and require explicit migration, but
state a bounded reproducibility contract.

## 9.5 Pipeline ordering

### Official stage evidence

Capture One documents four histograms at different processing points:

1. **Exposure Evaluation**
   - RAW capture data plus selected film curve and WB/tint;
   - affected by crop;
   - not affected by most later edits.
2. **Levels histogram**
   - includes exposure, contrast, brightness, saturation, HDR, vignetting, and
     some clarity behavior;
   - excludes Levels' own current transform.
3. **Curve histogram**
   - additionally reflects Levels endpoints.
4. **Final Histogram**
   - reflects curves, colour edits, ICC/output profile, and the final preview.

### Third-party reverse-engineered ordering

Image Alchemist's histogram-based observations place the rough flow as:

```text
Base curve / WB / LCC / lens light falloff / geometry
→ exposure / HDR / clarity variants / vignetting / master colour balance
→ per-channel then RGB Levels
→ per-channel, Luma, then RGB Curves
→ later colour-editor, B&W, 3-way colour balance, classic clarity,
  camera/output ICC behavior, grain/detail stages
```

This ordering is useful evidence, but it is not official source code and may vary
by processing engine.

## 9.6 Exposure assessment

### Exposure Evaluation

**Official.** The tool uses a RAW-oriented histogram plus film curve and white
balance. Its meter is center-weighted and displays approximately ±2 EV.
Documentation describes a green safe range around `-1.7` to `+2` stops,
overexposure/clipping warnings, and underexposure warnings.

### Auto Exposure

**Official high-level behavior.** Auto exposure uses:

- the original exposure-meter reading;
- average exposure relative to an 18% middle-grey reference;
- additional logic intended to avoid colour casts/hue shifts.

The exact formula is not public.

### Auto Levels

Capture One exposes configurable highlight and shadow clipping thresholds.
Recent official negative-film documentation states a typical default of `0.10%`
for each side. Auto Levels may operate on composite RGB or individual channels,
depending on workflow.

**Banksia lesson:** store the percentile policy and resulting endpoints in the
recipe. Do not hide the threshold.

## 9.7 Focus assessment

### Focus Mask

**Official.** Focus Mask:

- highlights areas considered sharply focused;
- is RAW-only;
- is independent of applied sharpening;
- is affected by image resolution and noise;
- exposes colour, opacity, and threshold;
- has a documented default threshold of `250` in preferences;
- should be confirmed at 100% rather than trusted as final proof.

The exact edge/frequency algorithm is not public.

The existence of `.cof` cache files shows Focus Mask analysis is stored as a
separate disposable derivative.

### Focus Area / Snap to Eye

Modern Capture One can detect faces and center the Focus tool on the closest eye
or face. When several faces are detected, official documentation says it selects
the largest face, assuming it is nearer.

### Assisted Review

Capture One 16.8 release documentation describes an Assisted Review beta that
tags images for:

- closed eyes;
- missed focus/out-of-focus eyes;
- exposure problems;
- black frames.

The results are filterable and complement rather than replace manual ratings.
No model or scoring details are public.

**Banksia lesson:** technical issue tags are more honest than one universal
“quality score.” Store independent findings with confidence and permit filtering.

## 9.8 White balance and Smart Adjustments

Capture One supports:

- as-shot WB;
- Kelvin and tint;
- neutral picker;
- auto WB;
- per-camera/preset behavior;
- Next Capture Adjustments.

Smart Adjustments can normalize exposure and WB across portraits/reference
images, but the exact implementation is proprietary. Styles themselves are
explicitly documented as fixed values, not dynamic image-dependent adjustments.

**Banksia lesson:** distinguish fixed styles from analysis-driven normalization.

## 9.9 Noise reduction

### Standard Noise Reduction

**Official.** Parameters are:

- Luminance;
- Color;
- Details;
- Single Pixel.

Documented defaults include:

- Luminance `50`;
- Details `50`.

Capture One says ISO, exposure metadata, and camera model are used to calculate
noise reduction defaults. The exact profile/formula is not public.

Single Pixel compares isolated pixels against their surroundings and targets hot
pixels, especially for long exposures.

### Enhanced Denoise

Capture One 16.8 documentation describes:

- Bayer RAW only;
- most useful around ISO 3200 and above;
- asynchronous background generation;
- a denoised sidecar computed once per source and reused by all variants;
- automatic colour-noise and hot-pixel removal;
- one Impact slider controlling luminance-noise removal;
- default Impact `50`, intentionally retaining natural achromatic grain;
- disposable/regenerable sidecar data.

This is a strong validation of Banksia's proposed model: expensive source-level
analysis can be shared across variants, but its backend identity must be part of
the derived artifact key.

## 9.10 Sharpening

Capture One documents a three-stage model:

1. **Capture sharpening**
   - camera-model defaults;
   - counters demosaic, optical low-pass, capture softness, and diffraction.
2. **Creative sharpening**
   - global or local/layer-based.
3. **Output sharpening**
   - screen or print;
   - based on output dimensions and, for print, viewing distance/diagonal.

Main sharpening parameters:

- Amount;
- Radius;
- Threshold;
- Halo Suppression.

Lens tools also include diffraction correction using deconvolution and sharpness
falloff correction.

**Banksia lesson:** do not implement one sharpening slider at one fixed point.
Separate input/capture sharpening from output sharpening.

## 9.11 Clarity and Structure

Capture One defines Clarity and Structure as local-contrast operations at
different scales:

- Clarity affects broader transitions/midtone local contrast;
- Structure affects smaller-scale texture/detail.

Methods:

- Natural;
- Punch;
- Neutral;
- Classic.

Their colour and highlight behavior differs. Punch can increase saturation;
Neutral retains saturation; Classic is mild and protects highlights better.

## 9.12 Colour Editor

### Basic

- fixed broad colour ranges;
- Hue, Saturation, Lightness;
- intelligent/non-linear saturation behavior.

### Advanced

- up to 30 colour-range corrections;
- picked origin colour;
- adjustable hue and saturation range;
- smoothness;
- Hue, Saturation, Lightness changes;
- supports layers and mask creation.

The public AppleScript interface exposes useful parameter ranges:

- hue start: `-360..0` relative to origin;
- hue end: `0..360`;
- saturation start: `-100..0`;
- saturation end: `0..100`;
- smoothness: `1..30`;
- hue change: `-30..30`;
- saturation change: `-100..200`;
- lightness change: `-100..200`.

### Skin Tone

Skin Tone selects a reference colour and moves selected colours toward it with
independent uniformity controls for:

- hue;
- saturation;
- lightness.

It also has HSL amount controls and selection smoothness. The operation is not
limited to skin; it can homogenize any selected colour range.

**Banksia lesson:** model this as colour-range selection plus a “move toward
reference” operator, not a magical skin-only algorithm.

## 9.13 Exposure, HDR, and saturation parameters

### Exposure panel

- Exposure, approximately ±4 EV in the documented UI;
- Contrast;
- Brightness, primarily midtones;
- Saturation.

Positive saturation is documented as non-linear/intelligent, affecting already
saturated colours and skin less. Negative saturation behaves more like ordinary
desaturation.

### HDR panel

- Highlight;
- Shadow;
- White;
- Black.

Highlight compresses the bright end; Shadow raises deep values. White/Black
provide endpoint contrast control. Capture One recommends applying HDR before
Levels/Curves.

## 9.14 Output recipes

Capture One's mature export model separates development from output and supports
simultaneous recipes containing:

- format and bit depth;
- ICC profile;
- dimensions, resolution, and no-upscale policy;
- screen or print sharpening;
- crop behavior;
- metadata inclusion;
- naming and destination;
- watermark, overlay, annotations, and PSD assets.

Recipe proofing displays scaling, compression, output profile, sharpening,
watermark, and other output effects before export.

This should remain a direct Banksia influence.

---

# 10. Comparison matrix

| System | Main assessment style | Defaults/profile strategy | Distinctive feature |
|---|---|---|---|
| darktable | Stage histograms, pickers, scene dynamic range, profiled noise | Versioned modules and camera/ISO data | Deep scene-referred modular pipeline |
| RawTherapee | Histogram-derived explicit params, AWB, embedded-JPEG matching | PP3 and metadata dynamic profiles | Camera-JPEG histogram matching |
| ART | Histogram matching, auto log range, auto radius/denoise | Simplified RT-derived profiles and masks | Restrained integrated workflow |
| Filmulator | Histograms plus spatial film-development simulation | Coherent simulation defaults | Developer-depletion tone mapping |
| vkdt | GPU histograms, log exposure, noise profiling | Explicit Vulkan graph | GPU-first graph and source noise model |
| LibRaw | Metadata and baseline dcraw controls | Camera tables and caller parameters | Broad decoder compatibility |
| Capture One | Stage histograms, camera defaults, focus/face/AI technical tags | Camera ICC + curve + process engine | Camera-specific look and studio assessment |

---

# 11. Recommended Banksia assessment model

## 11.1 Store five separate classes of state

### A. Capture facts

Immutable and source-derived:

```zig
const CaptureFacts = struct {
    source_hash: [32]u8,
    width: u32,
    height: u32,
    active_area: RectU32,
    default_crop: RectU32,
    orientation: Orientation,
    cfa: Cfa,
    black_level: [4]f32,
    white_level: [4]f32,
    as_shot_neutral: [3]f32,
    camera: CameraId,
    lens: ?LensId,
    iso: u32,
    shutter_seconds: f32,
    aperture: f32,
    focal_length_mm: f32,
};
```

### B. Derived analysis

Versioned and regenerable:

```zig
const AnalysisResult = struct {
    algorithm_id: Hash,
    renderer_manifest: Hash,
    source_hash: Hash,
    params_hash: Hash,
    payload_hash: Hash,
    confidence: f32,
};
```

Examples:

- RAW histogram;
- preview histogram;
- noise model;
- focus map;
- face/eye regions;
- embedded-preview tone match;
- auto-exposure suggestion.

### C. Defaults

Resolved from camera/profile/workflow:

- camera profile;
- default tone transform;
- demosaic method;
- noise profile;
- capture sharpening;
- lens correction;
- session default recipe.

### D. User recipe

Only explicit chosen parameters. If auto analysis changes exposure, write the
resulting EV and attach provenance:

```json
{
  "exposure": {
    "ev": 0.73,
    "provenance": {
      "kind": "auto_exposure",
      "algorithm": "auto-exposure-v1",
      "analysis": "...hash..."
    }
  }
}
```

### E. Output recipe

Keep format, resize, profile, sharpening, naming, and metadata independent of the
develop recipe.

---

## 11.2 Assessment features to implement first

### Stage 1 — capture and display diagnostics

Implement before smart image ranking:

- per-channel RAW histogram after black subtraction;
- scene-linear luminance histogram;
- final-preview histogram;
- raw clipping count per channel;
- output clipping count per channel;
- exposure warnings;
- neutral-region picker;
- 100% loupe;
- focus-energy overlay.

### Stage 2 — conservative automatic suggestions

#### Auto levels

- configurable low/high clipping percentiles;
- start with 0.10% per side as a documented experiment, not a universal truth;
- support composite RGB and independent channel modes;
- write resulting endpoints into the recipe;
- display clipped-pixel counts.

#### Auto exposure

Use a log-luminance histogram:

1. exclude invalid and deeply clipped pixels;
2. compute center-weighted and whole-frame statistics;
3. estimate median/trimmed mean luminance;
4. target a documented middle-grey value;
5. constrain correction by highlight headroom;
6. return EV plus confidence and diagnostics.

Do not auto-change contrast, brightness, HDR, and black simultaneously in v1.
RawTherapee proves this can work, but it makes failures harder to understand.

#### Auto white balance

First release:

- camera/as-shot;
- explicit Kelvin/tint or gains;
- spot neutral picker.

Later experimental auto WB:

- grey-world/trimmed neutral candidates;
- reject saturated and near-black pixels;
- report confidence;
- never silently override as-shot WB.

#### Embedded-preview tone match

Implement as an optional named action:

> Match camera preview tone

- extract embedded preview;
- render a neutral low-resolution RAW;
- align crop/aspect;
- derive a monotonic luminance curve;
- store the generated curve;
- clearly state that colour and local processing are not matched.

### Stage 3 — noise profile

Adopt a signal-dependent model:

```text
variance(channel, signal) = intercept[channel] + slope[channel] × signal
```

- profile by camera and ISO;
- interpolate in log ISO;
- store profile provenance;
- fall back to conservative manual denoise;
- validate against flat-field/dark-frame captures.

### Stage 4 — focus assistance

Start with an overlay, not a global score:

- operate on a versioned neutral preview;
- use multi-scale gradient/Laplacian energy;
- normalize for resolution and preview scale;
- reduce sensitivity to high-ISO noise;
- store a tile grid;
- permit threshold, colour, and opacity;
- require 100% confirmation.

For burst ranking:

- compare only within a temporal/visual burst;
- prefer subject/eye ROI where available;
- report relative rank and confidence;
- do not hide or reject automatically.

### Stage 5 — technical issue tags

Following Capture One's modern direction, store independent findings:

- probable black frame;
- probable severe under/overexposure;
- no confident focus region;
- likely closed eye;
- eye focus uncertain;
- duplicate/near-duplicate.

Independent tags are more actionable than one “quality = 73” score.

---

# 12. Recommended Banksia develop parameters

These are suggested product parameters, not claimed copies of another editor.

## 12.1 RAW preparation

- source crop and orientation;
- black level per CFA site;
- white level per channel;
- defect/hot-pixel policy;
- optional flat field;
- optional raw CA correction.

## 12.2 White balance

- mode: as-shot, camera preset, custom gains, temperature/tint, spot;
- gains or temperature/tint canonical representation;
- adaptation method;
- selected illuminant/profile dependency.

## 12.3 Demosaic and highlight

- method/implementation ID;
- quality/preview mode;
- optional green equilibration;
- colour-smoothing amount;
- highlight reconstruction method and threshold.

## 12.4 Exposure and scene tone

- exposure EV;
- black offset only as a technical correction;
- highlights;
- shadows;
- whites;
- blacks;
- middle grey;
- source black/white EV or equivalent dynamic-range limits;
- contrast;
- toe/shoulder or display-transform parameters.

## 12.5 Colour

- camera-profile dependency;
- working-space identity;
- saturation/vibrance;
- colour-balance shadows/midtones/highlights;
- colour-range origin;
- hue and chroma boundaries;
- smoothness;
- HSL deltas;
- optional uniformity-toward-reference controls.

## 12.6 Detail

- capture sharpening: amount, radius, threshold, halo suppression;
- denoise: profile, luminance, colour, detail retention, hot pixel;
- clarity/local contrast scale and amount;
- structure/fine-detail amount;
- lens correction profile and strengths.

## 12.7 Geometry

- orientation;
- crop in normalized source coordinates;
- rotation/straighten;
- keystone/perspective;
- flips;
- lens geometry identity.

## 12.8 Output

- format and bit depth;
- dimensions/long edge/no-upscale;
- resampler;
- output ICC profile;
- output sharpening mode and params;
- metadata policy;
- filename template and collision policy;
- destination.

---

# 13. Architectural recommendations for Banksia

## 13.1 Auto operations should be commands, not permanent render modes

Prefer:

```text
Auto Exposure command
→ reads analysis
→ writes exposure.ev = 0.73
→ records provenance
```

Avoid:

```text
recipe.auto_exposure = true
```

The first form is deterministic, debuggable, cacheable, and stable when an auto
algorithm changes.

Exceptions may exist for intentionally live operations such as tethered
deflicker, but they should still pin their algorithm and inputs.

## 13.2 Histograms belong to named pipeline stages

Do not expose one ambiguous histogram.

Recommended views:

- RAW capture histogram;
- scene/develop histogram before display transform;
- final proof/output histogram.

Capture One's stage-specific histograms are one of its best assessment UX ideas.

## 13.3 Keep profile defaults separate from content analysis

A camera-specific `+0.5 EV`, sharpening amount, or tone curve is a default
profile choice, not proof that the current image was assessed.

Record:

- source of the default;
- camera/profile match;
- algorithm/profile version;
- user override.

## 13.4 Expensive source-level analysis should be shared by variants

Examples:

- demosaiced neutral preview;
- enhanced denoise result;
- RAW histogram;
- noise profile;
- face/eye detections;
- focus tile map.

Key them by source, analysis renderer, algorithm, and parameters. Do not key them
by variant message/history.

## 13.5 Do not promise automatic artistic selection

The reliable early assessments are technical:

- clipping;
- probable black frame;
- focus energy;
- eye open/closed;
- relative burst similarity;
- noise level.

Expression, gesture, composition, and emotional preference remain human choices.

## 13.6 Profile data is product work

Capture One, darktable, RawTherapee, and vkdt all demonstrate that camera quality
requires maintained data:

- colour profiles;
- tone defaults;
- noise profiles;
- lens profiles;
- camera quirks;
- per-format metadata handling.

Banksia should budget profile tooling, corpus capture, provenance, and regression
testing as ongoing product work—not a one-time matrix implementation.

---

# 14. Recommended implementation order

1. Validate recipe values so untrusted JSON cannot reach assertions.
2. Add real-camera geometry and baseline colour.
3. Add RAW, scene, and final histograms.
4. Add exposure and clipping diagnostics.
5. Add spot WB and neutral readouts.
6. Add explicit auto levels.
7. Add conservative single-parameter auto exposure.
8. Add optional embedded-preview tone matching.
9. Add a camera/ISO noise-profile format.
10. Add focus overlay and 100% compare.
11. Validate relative burst focus ranking on real shoots.
12. Add face/eye technical assessment only after the culling MVP works.
13. Add advanced colour-range and uniformity controls after basic export ships.

---

# 15. Conclusions

## What the open-source editors show

- darktable is the best reference for versioned module semantics, scene-referred
  processing, and camera/ISO noise profiles.
- RawTherapee is the best reference for histogram-derived explicit auto
  parameters, embedded-JPEG tone matching, DCP support, and metadata-driven
  profiles.
- ART shows the value of reducing parameter breadth and sharing a coherent mask
  system.
- Filmulator shows that a strong default look can come from one coherent spatial
  model rather than dozens of unrelated sliders.
- vkdt shows a credible GPU graph and noise-profile architecture, but not a
  reason to make Banksia GPU-only.
- LibRaw should solve format breadth, not define the final Banksia look.

## What Capture One shows

Capture One's advantage appears to come less from one secret automatic formula
and more from the combination of:

- camera-specific colour/profile work;
- carefully chosen tone defaults;
- engine-version compatibility;
- camera/ISO-aware detail defaults;
- stage-specific diagnostic tools;
- fast preview and cache behavior;
- strong compare/focus/tether workflows;
- separate develop and output recipes;
- recent source-level derived artifacts reused across variants.

## Best direction for Banksia

Build an assessment system that is:

- stage-aware;
- explicit;
- confidence-bearing;
- versioned;
- camera/profile-aware;
- human-overridable;
- reusable across variants;
- independent from the strict renderer.

The first useful “smart” Banksia is not an AI that chooses the keeper. It is an
editor that tells the photographer, quickly and honestly:

- what the sensor captured;
- what is clipped;
- what appears in focus;
- what WB/profile/defaults were applied;
- why an automatic suggestion changed a parameter;
- whether that suggestion is reliable.

---

# Sources

## darktable

- Repository: https://github.com/darktable-org/darktable
- Exposure module: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/src/iop/exposure.c
- RAW prepare: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/src/iop/rawprepare.c
- White balance: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/src/iop/temperature.c
- Demosaic: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/src/iop/demosaic.c
- Filmic RGB: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/src/iop/filmicrgb.c
- Profiled denoise: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/src/iop/denoiseprofile.c
- Noise profiles: https://github.com/darktable-org/darktable/blob/78ad08c3833eeb4a56d5fc6a390c0f9ef3b4272d/data/noiseprofiles.json

## RawTherapee

- Repository: https://github.com/Beep6581/RawTherapee
- Parameter defaults: https://github.com/Beep6581/RawTherapee/blob/039b9b89d43315be6b42e8fbb33b8cfb39edd4bf/rtengine/procparams.cc
- Auto exposure: https://github.com/Beep6581/RawTherapee/blob/039b9b89d43315be6b42e8fbb33b8cfb39edd4bf/rtengine/improcfun.cc
- Histogram matching: https://github.com/Beep6581/RawTherapee/blob/039b9b89d43315be6b42e8fbb33b8cfb39edd4bf/rtengine/histmatching.cc
- Processing coordinator: https://github.com/Beep6581/RawTherapee/blob/039b9b89d43315be6b42e8fbb33b8cfb39edd4bf/rtengine/improccoordinator.cc
- DCP support: https://github.com/Beep6581/RawTherapee/blob/039b9b89d43315be6b42e8fbb33b8cfb39edd4bf/rtengine/dcp.cc
- Dynamic profiles: https://github.com/Beep6581/RawTherapee/blob/039b9b89d43315be6b42e8fbb33b8cfb39edd4bf/rtengine/dynamicprofile.cc

## ART

- Repository: https://github.com/artpixls/ART
- Parameter defaults: https://github.com/artpixls/ART/blob/da08e8d56e4a07f7eb0dbfa20b13c5c27f8fe397/rtengine/procparams.cc
- Histogram matching: https://github.com/artpixls/ART/blob/da08e8d56e4a07f7eb0dbfa20b13c5c27f8fe397/rtengine/histmatching.cc
- Auto deconvolution radius: https://github.com/artpixls/ART/blob/da08e8d56e4a07f7eb0dbfa20b13c5c27f8fe397/rtengine/deconvautoradius.cc

## Filmulator

- Repository: https://github.com/CarVac/filmulator-gui
- Project description: https://github.com/CarVac/filmulator-gui/blob/57fbaec57555432d86d3aa632990cd8fa09114ad/README.md
- Film simulation: https://github.com/CarVac/filmulator-gui/blob/57fbaec57555432d86d3aa632990cd8fa09114ad/filmulator-gui/core/filmulate.cpp
- Pipeline: https://github.com/CarVac/filmulator-gui/blob/57fbaec57555432d86d3aa632990cd8fa09114ad/filmulator-gui/core/imagePipeline.cpp

## vkdt

- Repository: https://github.com/hanatos/vkdt
- RAW graph example: https://github.com/hanatos/vkdt/blob/d166d05306a458536517f7fb6fe1509f11a84761/bin/examples/raw.cfg
- Colour module: https://github.com/hanatos/vkdt/blob/d166d05306a458536517f7fb6fe1509f11a84761/src/pipe/modules/colour/readme.md
- Denoise module: https://github.com/hanatos/vkdt/blob/d166d05306a458536517f7fb6fe1509f11a84761/src/pipe/modules/denoise/readme.md
- Denoise noise model: https://github.com/hanatos/vkdt/blob/d166d05306a458536517f7fb6fe1509f11a84761/src/pipe/modules/denoise/assemble.comp
- Demosaic: https://github.com/hanatos/vkdt/blob/d166d05306a458536517f7fb6fe1509f11a84761/src/pipe/modules/demosaic/readme.md
- Film curve: https://github.com/hanatos/vkdt/blob/d166d05306a458536517f7fb6fe1509f11a84761/src/pipe/modules/filmcurv/readme.md

## LibRaw

- Repository: https://github.com/LibRaw/LibRaw
- Documentation: https://www.libraw.org/docs

## Capture One official

- Base Characteristics overview: https://support.captureone.com/hc/en-us/articles/360002588917-The-Base-Characteristics-panel-overview
- Film curves: https://support.captureone.com/hc/en-us/articles/360002424317-What-is-the-Curve-section-of-the-Base-Characteristics-tool
- Processing engines: https://support.captureone.com/hc/en-us/articles/360002590037-Overview-of-the-process-engines
- RAW behavior: https://support.captureone.com/hc/en-us/articles/360002481998-The-way-Capture-One-works-with-RAW-files
- Exposure Evaluation: https://support.captureone.com/hc/en-us/articles/360002597757-The-Exposure-Evaluation-panel
- Histogram stages: https://support.captureone.com/hc/en-us/articles/360002589878-About-histograms
- Auto/manual exposure: https://support.captureone.com/hc/en-us/articles/360002602077-Adjusting-exposure-in-the-Exposure-tool
- Focus Mask: https://support.captureone.com/hc/en-us/articles/360002473597-The-Focus-Mask
- Focus preferences: https://support.captureone.com/hc/en-us/articles/360002487898-Capture-One-Preferences-Settings-The-Focus-tab
- Focus Area: https://support.captureone.com/hc/en-us/articles/360002477058-Focus-Tool-AI-Snap-to-Eye
- Noise Reduction: https://support.captureone.com/hc/en-us/articles/360002615758-The-Noise-Reduction-tool
- Enhanced Denoise: https://support.captureone.com/hc/en-us/articles/35840235353117-Enhanced-Denoise
- Sharpening workflow: https://support.captureone.com/hc/en-us/articles/360002606817-Overview-of-sharpening-workflow
- Sharpening parameters: https://support.captureone.com/hc/en-us/articles/360002606917-Adjusting-sharpening-in-the-Sharpening-tool
- Clarity and Structure: https://support.captureone.com/hc/en-us/articles/360002605157-The-Clarity-tool-overview
- Color Editor overview: https://support.captureone.com/hc/en-us/articles/360002601358-The-Color-Editor-overview
- Advanced Color Editor: https://support.captureone.com/hc/en-us/articles/360002601978-Advanced-Color-Editor
- Skin Tone: https://support.captureone.com/hc/en-us/articles/360002596077-Adjusting-skin-tones
- AppleScript parameter surface: https://support.captureone.com/hc/en-us/articles/360002681418-Capture-One-Workflow-Automation-with-AppleScript
- Process recipes: https://support.captureone.com/hc/en-us/articles/360002633697-Process-Recipes-and-Export-Recipes
- Capture One 16.8 / Assisted Review: https://support.captureone.com/hc/en-us/articles/35747427882653-Capture-One-16-8-release-notes
- Session sidecars: https://support.captureone.com/hc/en-us/articles/360002862137-Session-sidecar-files-explained-What-s-inside-the-CaptureOne-folder

## Capture One public format/reverse-engineering evidence

- ExifTool Capture One parser: https://github.com/exiftool/exiftool/blob/master/lib/Image/ExifTool/CaptureOne.pm
- Third-party histogram pipeline analysis: https://imagealchemist.net/processing-pipeline-in-capture-one/
