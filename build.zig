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
            .imports = &.{.{ .name = "emu", .module = emu_mod }},
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

    // ---- `golden`: the conformance speedometer ---------------------------------
    // Renders the synthetic corpus and compares SHA-256es against the committed
    // baseline. `zig build golden -- --update` rewrites the baseline.
    const golden = b.addExecutable(.{
        .name = "golden",
        .root_module = b.createModule(.{
            .root_source_file = b.path("golden/runner.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "emu", .module = emu_mod }},
        }),
    });
    const run_golden = b.addRunArtifact(golden);
    run_golden.setCwd(b.path("."));
    run_golden.has_side_effects = true;
    if (b.args) |args| run_golden.addArgs(args);
    const golden_step = b.step("golden", "Run the golden-render conformance harness");
    golden_step.dependOn(&run_golden.step);
}
