const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const libraw_prefix = b.option(
        []const u8,
        "libraw-prefix",
        "LibRaw installation prefix",
    ) orelse "/opt/homebrew/opt/libraw";

    // ---- emu: the develop engine module --------------------------------------
    const emu_mod = emu_module(b, target, optimize, libraw_prefix);

    // wombat provides the durable vault and catalog baseline; lyrebird
    // (similarity, Phase 4) remains a layout/test stub.
    const wombat_mod = b.createModule(.{
        .root_source_file = b.path("wombat/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lyrebird_mod = b.createModule(.{
        .root_source_file = b.path("lyrebird/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ---- `banksia` executable: the CLI ----------------------------------------
    const exe = b.addExecutable(.{
        .name = "banksia",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "emu", .module = emu_mod },
                .{ .name = "wombat", .module = wombat_mod },
            },
        }),
    });
    b.installArtifact(exe);

    // `zig build render -- shot.dng recipe.json out.png`
    const run_render = b.addRunArtifact(exe);
    run_render.step.dependOn(b.getInstallStep());
    run_render.addArg("render");
    if (b.args) |args| run_render.addArgs(args);
    const render_step = b.step("render", "Render a RAW through a recipe to a PNG");
    render_step.dependOn(&run_render.step);

    // ---- `lib`: the C ABI dylib -------------------------------------------------
    // `zig build lib` produces zig-out/lib/libbanksia.dylib and installs the
    // hand-written header next to it; the SwiftUI shell links against both.
    const capi_mod = b.createModule(.{
        .root_source_file = b.path("src/capi.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{.{ .name = "emu", .module = emu_mod }},
    });
    const lib = b.addLibrary(.{
        .name = "banksia",
        .linkage = .dynamic,
        .root_module = capi_mod,
    });
    lib.installHeader(b.path("include/banksia.h"), "banksia.h");
    const lib_install = b.addInstallArtifact(lib, .{});
    b.getInstallStep().dependOn(&lib_install.step);
    const lib_step = b.step("lib", "Build libbanksia.dylib and install the C header");
    lib_step.dependOn(&lib_install.step);

    // ---- tests -----------------------------------------------------------------
    //   zig build test-unit   module inline unit tests (emu + wombat + lyrebird)
    //   zig build test-tidy   source lint (bans, reminders, long-line budget)
    //   zig build test        everything above
    const test_step = b.step("test", "Run all test suites");

    const unit_step = b.step("test-unit", "Run module inline unit tests");
    for ([_]*std.Build.Module{ emu_mod, wombat_mod, lyrebird_mod }) |mod| {
        const t = b.addTest(.{ .root_module = mod });
        const run_t = b.addRunArtifact(t);
        unit_step.dependOn(&run_t.step);
        test_step.dependOn(&run_t.step);
    }

    // capi tests read include/banksia.h and write DNG fixtures under
    // .zig-cache, so they run from the project root like tidy does.
    const capi_tests = b.addTest(.{ .root_module = capi_mod });
    const run_capi_tests = b.addRunArtifact(capi_tests);
    run_capi_tests.setCwd(b.path("."));
    run_capi_tests.has_side_effects = true;
    unit_step.dependOn(&run_capi_tests.step);
    test_step.dependOn(&run_capi_tests.step);

    const tidy_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tidy.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_tidy = b.addRunArtifact(tidy_tests);
    // `tidy` reads the source tree, so it must run from the project root.
    run_tidy.setCwd(b.path("."));
    run_tidy.has_side_effects = true; // re-run when sources change
    const tidy_step = b.step("test-tidy", "Lint the source: bans, reminders, long-line budget");
    tidy_step.dependOn(&run_tidy.step);
    test_step.dependOn(&run_tidy.step);

    // ---- `shell` / `run-shell`: the SwiftUI inspection shell ---------------------
    // The dev loop is zig build, not make: `zig build shell` builds the
    // dylib, installs the header, then drives SwiftPM; `run-shell` opens
    // the app. Requires a Swift toolchain (Xcode), so it is not in `test`.
    const shell_lib = b.addSystemCommand(&.{
        "zig",
        "build",
        "-Doptimize=ReleaseFast",
        b.fmt("-Dlibraw-prefix={s}", .{libraw_prefix}),
        "lib",
    });
    const metal_compile = b.addSystemCommand(&.{
        "xcrun",
        "--toolchain",
        "Metal",
        "-sdk",
        "macosx",
        "metal",
        "-std=metal3.0",
        "-c",
        "macos/Sources/Banksia/Shaders/LateDevelop.metal",
        "-o",
        ".zig-cache/LateDevelop.air",
    });
    const metal_link = b.addSystemCommand(&.{
        "xcrun",
        "--toolchain",
        "Metal",
        "-sdk",
        "macosx",
        "metallib",
        ".zig-cache/LateDevelop.air",
        "-o",
        "macos/Sources/Banksia/Shaders/LateDevelop.metallib",
    });
    metal_link.step.dependOn(&metal_compile.step);
    const shell_build = b.addSystemCommand(&.{ "swift", "build", "--package-path", "macos" });
    shell_build.step.dependOn(&shell_lib.step);
    shell_build.step.dependOn(&metal_link.step);
    shell_build.has_side_effects = true; // SwiftPM does its own caching
    const shell_step = b.step("shell", "Build the SwiftUI inspection shell (needs Xcode)");
    shell_step.dependOn(&shell_build.step);

    const swift_tests = b.addSystemCommand(&.{ "swift", "test", "--package-path", "macos" });
    swift_tests.step.dependOn(&shell_build.step);
    swift_tests.has_side_effects = true;
    const metal_test_step = b.step(
        "test-metal",
        "Run the compiled Metal surface and CPU/GPU conformance tests",
    );
    metal_test_step.dependOn(&swift_tests.step);

    const shell_run = b.addSystemCommand(&.{"macos/.build/debug/Banksia"});
    shell_run.step.dependOn(&shell_build.step);
    if (b.args) |args| shell_run.addArgs(args);
    shell_run.has_side_effects = true;
    const run_shell_step = b.step("run-shell", "Build and launch the inspection shell");
    run_shell_step.dependOn(&shell_run.step);

    // ---- `test-abi`: the C smoke test -------------------------------------------
    // A plain C program compiled against include/banksia.h and linked to the
    // dylib — no Xcode involved. The fixture DNG is synthesized by the CLI.
    const smoke_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    smoke_mod.addCSourceFile(.{
        .file = b.path("tests/abi_smoke.c"),
        .flags = &.{ "-std=c11", "-Wall", "-Wextra", "-Werror" },
    });
    smoke_mod.addIncludePath(b.path("include"));
    smoke_mod.linkLibrary(lib);
    const smoke = b.addExecutable(.{ .name = "abi_smoke", .root_module = smoke_mod });
    // Installed too: run it by hand against a 24MP synth for the timing
    // numbers the phase records.
    b.installArtifact(smoke);

    const synth_smoke = b.addRunArtifact(exe);
    synth_smoke.addArg("synth");
    const smoke_dng = synth_smoke.addOutputFileArg("smoke.dng");

    const run_smoke = b.addRunArtifact(smoke);
    run_smoke.addFileArg(smoke_dng);
    run_smoke.addArgs(&.{ "512", "384" });
    const abi_step = b.step("test-abi", "Smoke-test the C ABI from a C program");
    abi_step.dependOn(&run_smoke.step);
    test_step.dependOn(&run_smoke.step);

    // ---- `corpus`: optional local proprietary-RAW compatibility gate --------------
    // The 812 MB source files are intentionally untracked. This verifies their
    // hashes, committed metadata, LibRaw mosaics, and ImageIO 1024px previews.
    const corpus_check = b.addSystemCommand(&.{ "sh", "tools/verify-raw-corpus.sh" });
    corpus_check.step.dependOn(b.getInstallStep());
    corpus_check.has_side_effects = true;
    const corpus_step = b.step("corpus", "Verify and ImageIO-decode the local RAW corpus");
    corpus_step.dependOn(&corpus_check.step);

    // ---- `test-ci-corpus`: committed licensed DNG render gate ---------------------
    const ci_corpus_emu = emu_module(b, target, .ReleaseSafe, libraw_prefix);
    const ci_corpus = b.addExecutable(.{
        .name = "ci_corpus",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/ci_corpus.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
            .imports = &.{.{ .name = "emu", .module = ci_corpus_emu }},
        }),
    });
    const run_ci_corpus = b.addRunArtifact(ci_corpus);
    run_ci_corpus.setCwd(b.path("."));
    run_ci_corpus.has_side_effects = true;
    if (b.args) |args| run_ci_corpus.addArgs(args);
    const ci_corpus_step = b.step("test-ci-corpus", "Render the committed Phase 2B DNG corpus");
    ci_corpus_step.dependOn(&run_ci_corpus.step);
    test_step.dependOn(&run_ci_corpus.step);

    // ---- `raw-swarm`: deterministic DNG truncation/mutation parser swarm ----------
    const raw_swarm_emu = emu_module(b, target, .ReleaseSafe, libraw_prefix);
    const raw_swarm = b.addExecutable(.{
        .name = "raw_swarm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/raw_swarm.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
            .imports = &.{.{ .name = "emu", .module = raw_swarm_emu }},
        }),
    });
    const run_raw_swarm = b.addRunArtifact(raw_swarm);
    run_raw_swarm.has_side_effects = true;
    if (b.args) |args| run_raw_swarm.addArgs(args);
    const raw_swarm_step = b.step("raw-swarm", "Run the seeded DNG parser swarm");
    raw_swarm_step.dependOn(&run_raw_swarm.step);

    // ---- `raw-bench`: split real-camera decode/render timing ----------------------
    const raw_bench_emu = emu_module(b, target, .ReleaseFast, libraw_prefix);
    const raw_bench = b.addExecutable(.{
        .name = "raw_bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/raw_bench.zig"),
            .target = target,
            .optimize = .ReleaseFast,
            .imports = &.{.{ .name = "emu", .module = raw_bench_emu }},
        }),
    });
    const run_raw_bench = b.addRunArtifact(raw_bench);
    run_raw_bench.has_side_effects = true;
    if (b.args) |args| run_raw_bench.addArgs(args);
    const raw_bench_step = b.step("raw-bench", "Benchmark real RAW decode and v2 render");
    raw_bench_step.dependOn(&run_raw_bench.step);

    // ---- `sim`: the wombat crash simulator ---------------------------------------
    // 10k vault plus 10k catalog workloads with crash/torn-write injection.
    // The invariant is zero acknowledged blob or mutation loss.
    // The seed defaults to the commit hash for exact local replay.
    const sim_runs = b.option(u64, "sim-runs", "Crash-simulator runs (default 10000)") orelse
        10_000;
    const sim_seed = b.option(u64, "sim-seed", "Crash-simulator seed (default: commit hash)") orelse
        git_commit_seed(b);
    // The simulator always builds ReleaseSafe (the TigerBeetle convention):
    // assertions stay armed, and debug-speed BLAKE3 would turn 10k runs
    // from under a minute into three quarters of an hour.
    const sim_mod = b.createModule(.{
        .root_source_file = b.path("wombat/root.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });
    const sim_exe = b.addExecutable(.{
        .name = "sim",
        .root_module = b.createModule(.{
            .root_source_file = b.path("wombat/sim.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
            .imports = &.{.{ .name = "wombat", .module = sim_mod }},
        }),
    });
    b.installArtifact(sim_exe);
    const run_sim = b.addRunArtifact(sim_exe);
    run_sim.addArgs(&.{ "--seed", b.fmt("{d}", .{sim_seed}) });
    run_sim.addArgs(&.{ "--runs", b.fmt("{d}", .{sim_runs}) });
    run_sim.has_side_effects = true;
    const sim_step = b.step("sim", "Run 10k vault + 10k catalog crash workloads");
    sim_step.dependOn(&run_sim.step);

    // ---- `bench`: the catalog storage speedometers --------------------------------
    // Always ReleaseFast — phase latency gates are ReleaseFast numbers.
    const bench_mod = b.createModule(.{
        .root_source_file = b.path("wombat/root.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    const bench_exe = b.addExecutable(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("wombat/bench.zig"),
            .target = target,
            .optimize = .ReleaseFast,
            .imports = &.{.{ .name = "wombat", .module = bench_mod }},
        }),
    });
    b.installArtifact(bench_exe);
    const run_bench = b.addRunArtifact(bench_exe);
    run_bench.has_side_effects = true;
    if (b.args) |args| run_bench.addArgs(args);
    const bench_step = b.step("bench", "Run catalog filter/storage benchmarks (ReleaseFast)");
    bench_step.dependOn(&run_bench.step);

    // ---- `golden`: the conformance speedometer ---------------------------------
    // Renders the synthetic corpus and compares SHA-256es against the committed
    // baseline. `zig build golden -- --update` rewrites the baseline.
    const golden = b.addExecutable(.{
        .name = "golden",
        .root_module = b.createModule(.{
            .root_source_file = b.path("golden/runner.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "emu", .module = emu_mod },
                .{ .name = "wombat", .module = wombat_mod },
            },
        }),
    });
    const run_golden = b.addRunArtifact(golden);
    run_golden.setCwd(b.path("."));
    run_golden.has_side_effects = true;
    if (b.args) |args| run_golden.addArgs(args);
    const golden_step = b.step("golden", "Run the golden-render conformance harness");
    golden_step.dependOn(&run_golden.step);
}

fn emu_module(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libraw_prefix: []const u8,
) *std.Build.Module {
    const module = b.createModule(.{
        .root_source_file = b.path("emu/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    module.addIncludePath(.{
        .cwd_relative = b.fmt("{s}/include", .{libraw_prefix}),
    });
    module.addLibraryPath(.{
        .cwd_relative = b.fmt("{s}/lib", .{libraw_prefix}),
    });
    module.linkSystemLibrary("raw_r", .{ .use_pkg_config = .no });
    module.linkSystemLibrary("c++", .{});
    module.linkSystemLibrary("sqlite3", .{});
    return module;
}

/// The low 64 bits of HEAD's commit hash: every commit explores a
/// different corner of the state space, and any failure names its seed.
fn git_commit_seed(b: *std.Build) u64 {
    const output = b.run(&.{ "git", "rev-parse", "HEAD" });
    const trimmed = std.mem.trim(u8, output, " \t\r\n");
    if (trimmed.len < 16) return 0;
    return std.fmt.parseInt(u64, trimmed[0..16], 16) catch 0;
}
