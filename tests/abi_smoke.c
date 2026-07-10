/*
 * abi_smoke.c — the Phase 1 CI gate.
 *
 * Exercises the whole bk_ surface from plain C against the built dylib:
 * version, create, every documented error path (each returns its code and
 * leaves a message; success clears it), load, recipe, preview and full
 * renders with the longest-edge dimension contract, and destroy. In debug
 * builds the engine runs on a debug allocator and destroy asserts a clean
 * leak report, so this binary is also the leak gate.
 *
 * usage: abi_smoke <fixture.dng> <width> <height>
 *
 * Render timings are printed for the record; the < 1s preview exit
 * criterion is measured with a 24MP synth fixture and a ReleaseFast dylib.
 */

#include "banksia.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static int failures = 0;

#define check(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            fprintf(stderr, "abi_smoke:%d: FAIL %s\n", __LINE__, #cond);     \
            failures += 1;                                                   \
        }                                                                    \
    } while (0)

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e3 + (double)ts.tv_nsec / 1e6;
}

/* The pipeline's longest-edge map: side * edge / longest, floor, min 1. */
static uint32_t scaled(uint32_t side, uint32_t edge, uint32_t longest) {
    uint64_t out = (uint64_t)side * edge / longest;
    return out == 0 ? 1 : (uint32_t)out;
}

static const char *recipe_json =
    "{\"engine_version\":1,\"ops\":["
    "{\"black_point\":{}},"
    "{\"white_balance\":{\"as_shot\":true,\"gain_r\":1,\"gain_g\":1,\"gain_b\":1}},"
    "{\"demosaic\":{}},"
    "{\"exposure\":{\"ev\":0.5}},"
    "{\"tone_curve\":{\"contrast\":0.25}},"
    "{\"srgb_encode\":{}}]}";

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: abi_smoke <fixture.dng> <width> <height>\n");
        return 2;
    }
    const char *path = argv[1];
    const uint32_t full_w = (uint32_t)strtoul(argv[2], NULL, 10);
    const uint32_t full_h = (uint32_t)strtoul(argv[3], NULL, 10);

    check(bk_version() == 1);

    bk_engine *engine = bk_engine_create();
    check(engine != NULL);
    check(bk_last_error(engine)[0] == '\0');

    /* Error paths: each failure returns its code and leaves a message. */
    uint32_t w = 0, h = 0;
    check(bk_render(engine, 0, &w, &h) == NULL); /* render before load */
    check(strlen(bk_last_error(engine)) > 0);
    check(bk_load_raw(engine, "no/such/banksia-fixture.dng") == BK_ERR_IO);
    check(strlen(bk_last_error(engine)) > 0);
    check(bk_set_recipe_json(engine, "{ garbage") == BK_ERR_RECIPE);
    check(strlen(bk_last_error(engine)) > 0);
    check(bk_load_raw(engine, NULL) == BK_ERR_INVALID_ARGUMENT);
    check(bk_set_recipe_json(engine, NULL) == BK_ERR_INVALID_ARGUMENT);

    /* Happy path: load clears the message, recipe sets, renders render. */
    check(bk_load_raw(engine, path) == BK_OK);
    check(bk_last_error(engine)[0] == '\0');
    check(bk_set_recipe_json(engine, recipe_json) == BK_OK);

    /* An empty op stack parses fine but the pipeline rejects it. */
    check(bk_set_recipe_json(engine, "{\"engine_version\":1,\"ops\":[]}") == BK_OK);
    check(bk_render(engine, 0, &w, &h) == NULL);
    check(strlen(bk_last_error(engine)) > 0);
    check(bk_set_recipe_json(engine, recipe_json) == BK_OK);

    /* Preview render: the longest edge maps to the bound, floor, min 1. */
    const uint32_t edge = 1024;
    const uint32_t longest = full_w > full_h ? full_w : full_h;
    double start = now_ms();
    const uint8_t *preview = bk_render(engine, edge, &w, &h);
    const double preview_ms = now_ms() - start;
    check(preview != NULL);
    if (edge >= longest) {
        check(w == full_w);
        check(h == full_h);
    } else {
        check(w == scaled(full_w, edge, longest));
        check(h == scaled(full_h, edge, longest));
    }
    check(bk_last_error(engine)[0] == '\0');

    start = now_ms();
    const uint8_t *full = bk_render(engine, 0, &w, &h);
    const double full_ms = now_ms() - start;
    check(full != NULL);
    check(w == full_w);
    check(h == full_h);
    check(full[3] == 255); /* alpha is opaque */

    printf("abi_smoke: %" PRIu32 "x%" PRIu32 " preview(%" PRIu32 ") %.1f ms, full %.1f ms\n",
           full_w, full_h, edge, preview_ms, full_ms);

    bk_engine_destroy(engine);
    bk_engine_destroy(NULL); /* documented no-op */

    /* A second full cycle so the leak gate audits more than one engine. */
    bk_engine *second = bk_engine_create();
    check(second != NULL);
    check(bk_load_raw(second, path) == BK_OK);
    check(bk_render(second, 64, &w, &h) != NULL);
    bk_engine_destroy(second);

    if (failures == 0) printf("abi_smoke: all checks passed\n");
    return failures == 0 ? 0 : 1;
}
