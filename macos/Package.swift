// swift-tools-version:5.10
// The SwiftUI inspection shell. Not the product UI: it exists to *see* the
// engine work (plan.md). Built by `zig build shell` from the repo root,
// which produces the dylib and header first.
import PackageDescription

// Link against the zig build output; the absolute rpath means the debug
// binary runs from anywhere without copying the dylib around.
let zigOutLib = Context.packageDirectory + "/../zig-out/lib"

let package = Package(
    name: "Banksia",
    // macOS 26: the shell is dev-only and leans on Liquid Glass (glassEffect,
    // .buttonStyle(.glass)), so it targets Tahoe directly rather than guarding
    // every glass call behind availability.
    platforms: [.macOS("26.0")],
    targets: [
        .systemLibrary(name: "CBanksia", path: "Sources/CBanksia"),
        .executableTarget(
            name: "Banksia",
            dependencies: ["CBanksia"],
            path: "Sources/Banksia",
            linkerSettings: [
                .unsafeFlags([
                    "-L\(zigOutLib)",
                    "-Xlinker", "-rpath", "-Xlinker", zigOutLib,
                ])
            ]
        ),
        .testTarget(
            name: "BanksiaTests",
            dependencies: ["Banksia"],
            path: "Tests/BanksiaTests"
        ),
    ]
)
