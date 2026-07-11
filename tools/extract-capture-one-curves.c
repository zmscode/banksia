#include <dlfcn.h>
#include <fts.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>

typedef void *(*film_curve_from_file_fn)(const char *);
typedef void (*film_curve_release_fn)(void *);
typedef const char *(*film_curve_string_fn)(void *);
typedef uint32_t (*film_curve_u32_fn)(void *);
typedef void *(*film_curve_component_fn)(void *);
typedef uint32_t (*gradation_count_fn)(void *);
typedef double (*gradation_value_fn)(void *, uint32_t);

static void *symbol(void *library, const char *name) {
    void *result = dlsym(library, name);
    if (result == NULL) {
        fprintf(stderr, "missing symbol %s: %s\n", name, dlerror());
        exit(1);
    }
    return result;
}

static void csv_string(const char *value) {
    putchar('"');
    for (; *value != '\0'; value++) {
        if (*value == '"') putchar('"');
        putchar(*value);
    }
    putchar('"');
}

static int extract_curve(
    const char *path,
    film_curve_from_file_fn create,
    film_curve_release_fn release,
    film_curve_string_fn get_name,
    film_curve_string_fn get_description,
    film_curve_u32_fn get_version,
    film_curve_u32_fn get_flags,
    film_curve_component_fn *getters,
    gradation_count_fn get_count,
    gradation_value_fn get_x,
    gradation_value_fn get_y) {
    void *film_curve = create(path);
    if (film_curve == NULL) {
        fprintf(stderr, "Capture One rejected curve file: %s\n", path);
        return 1;
    }

    printf("# source=%s\n", path);
    printf("# name=%s\n", get_name(film_curve));
    printf("# description=%s\n", get_description(film_curve));
    printf("# version=%u\n", get_version(film_curve));
    printf("# flags=%u\n", get_flags(film_curve));

    const char *names[] = {"film", "ccd", "contrast"};
    for (size_t component = 0; component < 3; component++) {
        void *curve = getters[component](film_curve);
        uint32_t count = get_count(curve);
        for (uint32_t index = 0; index < count; index++) {
            csv_string(path);
            printf(",%s,%u,%.17g,%.17g\n", names[component], index,
                   get_x(curve, index), get_y(curve, index));
        }
    }

    release(film_curve);
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s IMAGECORE CURVE.fcrv|FILM_CURVE_DIRECTORY\n", argv[0]);
        return 2;
    }

    void *library = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (library == NULL) {
        fprintf(stderr, "cannot load ImageCore: %s\n", dlerror());
        return 1;
    }

    film_curve_from_file_fn create = symbol(library, "POFilmCurveCreateFromFile");
    film_curve_release_fn release = symbol(library, "POFilmCurveRelease");
    film_curve_string_fn get_name = symbol(library, "POFilmCurveGetName");
    film_curve_string_fn get_description = symbol(library, "POFilmCurveGetFilmCurveDescription");
    film_curve_u32_fn get_version = symbol(library, "POFilmCurveGetVersion");
    film_curve_u32_fn get_flags = symbol(library, "POFilmCurveGetFlags");
    film_curve_component_fn get_curve = symbol(library, "POFilmCurveGetCurve");
    film_curve_component_fn get_ccd = symbol(library, "POFilmCurveGetCCDCurve");
    film_curve_component_fn get_contrast = symbol(library, "POFilmCurveGetContrastCurve");
    gradation_count_fn get_count = symbol(library, "POGradationCurveGetNumberOfPoints");
    gradation_value_fn get_x = symbol(library, "POGradationCurveGetXAtIndex");
    gradation_value_fn get_y = symbol(library, "POGradationCurveGetYAtIndex");

    film_curve_component_fn getters[] = {get_curve, get_ccd, get_contrast};
    puts("source,component,index,x,y");

    int failures = 0;
    struct stat info;
    if (stat(argv[2], &info) != 0) {
        perror(argv[2]);
        failures = 1;
    } else if (S_ISDIR(info.st_mode)) {
        char *paths[] = {argv[2], NULL};
        FTS *tree = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
        if (tree == NULL) {
            perror("fts_open");
            failures = 1;
        } else {
            FTSENT *entry;
            while ((entry = fts_read(tree)) != NULL) {
                size_t length = strlen(entry->fts_path);
                if (entry->fts_info == FTS_F && length >= 5 &&
                    strcasecmp(entry->fts_path + length - 5, ".fcrv") == 0) {
                    failures += extract_curve(
                        entry->fts_path, create, release, get_name, get_description,
                        get_version, get_flags, getters, get_count, get_x, get_y);
                }
            }
            if (fts_close(tree) != 0) {
                perror("fts_close");
                failures++;
            }
        }
    } else {
        failures = extract_curve(
            argv[2], create, release, get_name, get_description,
            get_version, get_flags, getters, get_count, get_x, get_y);
    }

    dlclose(library);
    return failures == 0 ? 0 : 1;
}
