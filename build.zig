const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ---- emu: the develop engine module --------------------------------------
    const emu_mod = b.createModule(.{
        .root_source_file = b.path("emu/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // wombat (storage, Phase 2) and lyrebird (similarity, Phase 4) are stubs;
    // they exist so the layout, tests, and tidy roots are stable from day one.
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
    //   zig build test-unit   module inline unit tests (emu + stubs)
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
    const shell_build = b.addSystemCommand(&.{ "swift", "build", "--package-path", "macos" });
    shell_build.step.dependOn(&lib_install.step);
    shell_build.has_side_effects = true; // SwiftPM does its own caching
    const shell_step = b.step("shell", "Build the SwiftUI inspection shell (needs Xcode)");
    shell_step.dependOn(&shell_build.step);

    const shell_run = b.addSystemCommand(&.{"macos/.build/debug/Banksia"});
    shell_run.step.dependOn(&shell_build.step);
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

    // ---- `sim`: the wombat crash simulator ---------------------------------------
    // 10k randomized vault workloads with crash/torn-write injection; the
    // invariant is zero acknowledged-data loss. The seed defaults to the
    // commit hash, so every commit explores differently and any CI failure
    // replays locally from the hash alone.
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
    const sim_step = b.step("sim", "Run the wombat crash simulator (10k seeded runs)");
    sim_step.dependOn(&run_sim.step);

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

/// The low 64 bits of HEAD's commit hash: every commit explores a
/// different corner of the state space, and any failure names its seed.
fn git_commit_seed(b: *std.Build) u64 {
    const output = b.run(&.{ "git", "rev-parse", "HEAD" });
    const trimmed = std.mem.trim(u8, output, " \t\r\n");
    if (trimmed.len < 16) return 0;
    return std.fmt.parseInt(u64, trimmed[0..16], 16) catch 0;
}
