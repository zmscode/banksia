/*
 * banksia — C ABI for the develop engine.
 *
 * Hand-written; changes land in the same commit as src/capi.zig, and a
 * sync test in capi.zig counts the declarations here against the exported
 * surface.
 *
 * Threading: an engine handle is single-threaded. Calls on one handle must
 * be serialized by the caller (the Swift shell funnels them through one
 * actor); there is no internal locking. Distinct handles are independent.
 *
 * Errors: functions returning int32_t return BK_OK (0) on success and a
 * negative BK_ERR_* code on failure, with a human-readable message
 * available from bk_last_error until the next call on the same handle.
 * Success clears the message.
 */

#ifndef BANKSIA_H
#define BANKSIA_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque engine handle. Create with bk_engine_create, destroy with
 * bk_engine_destroy; every other function takes one. */
typedef struct bk_engine bk_engine;

#define BK_OK 0
/* A required pointer argument was null. */
#define BK_ERR_INVALID_ARGUMENT (-1)
/* The raw file could not be read. */
#define BK_ERR_IO (-2)
/* The raw file was read but could not be decoded. */
#define BK_ERR_DECODE (-3)
/* The recipe JSON is malformed or not a recipe. */
#define BK_ERR_RECIPE (-4)
/* The recipe parsed but the pipeline rejected it (bad op stack, or an
 * engine_version this engine does not implement). */
#define BK_ERR_RENDER (-5)
/* bk_render was called before a successful bk_load_raw. */
#define BK_ERR_NO_RAW (-6)
#define BK_ERR_OUT_OF_MEMORY (-7)
/* A cooperative render cancellation callback requested termination. */
#define BK_ERR_CANCELLED (-8)

typedef int32_t (*bk_should_cancel_fn)(void *context);

/* Create an engine. Returns NULL only on allocation failure. The handle
 * owns all memory it hands out and must be released with
 * bk_engine_destroy. */
bk_engine *bk_engine_create(void);

/* Destroy an engine and every buffer it owns, including the pixels most
 * recently returned by bk_render. NULL is a no-op. */
void bk_engine_destroy(bk_engine *engine);

/* Load a raw file (uncompressed DNG) from a NUL-terminated path. Replaces
 * any previously loaded raw. The file is fully decoded before this
 * returns; the path is not retained. */
int32_t bk_load_raw(bk_engine *engine, const char *path);

/* Set the develop recipe from NUL-terminated canonical-form JSON. The
 * string is parsed and copied before this returns; it is not retained.
 * Until the first successful call, renders use the engine default recipe.
 * Stack-shape errors surface at render time as BK_ERR_RENDER. */
int32_t bk_set_recipe_json(bk_engine *engine, const char *json);

/* Render the loaded raw through the current recipe. edge_px_max bounds the
 * longest output edge (preview renders); 0 renders at full resolution.
 * On success writes the output dimensions and returns row-major RGBA8
 * pixels, out_width * out_height * 4 bytes, sRGB, alpha 255.
 *
 * The engine owns the returned buffer: it is valid until the next
 * bk_render on this handle or bk_engine_destroy, whichever comes first.
 * Copy it before rendering again. Returns NULL on failure with the reason
 * in bk_last_error. */
const uint8_t *bk_render(bk_engine *engine, uint32_t edge_px_max,
                         uint32_t *out_width, uint32_t *out_height);

/* Render the early, reusable preview stage for accelerated late develop.
 * On success writes row-major RGBA32F pixels in linear Rec.2020 after black
 * level, white balance, highlight recovery, demosaic, camera-to-working
 * conversion, crop/orientation, and preview scaling. Exposure, tone, output
 * conversion, and transfer encoding have not run; alpha is 1.
 *
 * The engine owns the returned buffer: it is valid until the next
 * bk_render_linear on this handle or bk_engine_destroy. This does not alter
 * the lifetime or behavior of a buffer returned by bk_render. */
const float *bk_render_linear(bk_engine *engine, uint32_t edge_px_max,
                              uint32_t *out_width, uint32_t *out_height);

/* The admitted form of bk_render_linear. A nonzero memory_budget_bytes rejects
 * the render before pipeline allocation when its conservative combined CPU/GPU
 * estimate exceeds the budget. should_cancel is polled between safe pipeline
 * stages; return nonzero to stop with BK_ERR_CANCELLED. The callback and context
 * are borrowed only for this synchronous call. */
const float *bk_render_linear_with_admission(
    bk_engine *engine, uint32_t edge_px_max, uint64_t memory_budget_bytes,
    bk_should_cancel_fn should_cancel, void *cancel_context,
    uint32_t *out_width, uint32_t *out_height);

/* The message for the most recent failure on this handle, or "" after a
 * success. Owned by the engine; valid until the next call on the handle.
 * Never NULL. */
const char *bk_last_error(const bk_engine *engine);

/* The engine version renders are pinned to (recipes record it; plan.md,
 * Phase 3). */
uint32_t bk_version(void);

#ifdef __cplusplus
}
#endif

#endif /* BANKSIA_H */
