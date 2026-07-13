import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var controller = DevelopController()
    @State private var viewer = ViewerState()
    @State private var thumbs = ThumbnailStore()
    @State private var importing = false
    @State private var solo = false

    private static let rawTypes = ["dng", "cr2", "cr3"].compactMap {
        UTType(filenameExtension: $0, conformingTo: .image)
    }

    var body: some View {
        VStack(spacing: 0) {
            // The viewer fills the whole area; the panels are floating card
            // columns over it, so the frame reads full-bleed and clipped behind
            // the glass. One base colour everywhere, no divider.
            ZStack {
                PreviewCanvas(controller: controller, viewer: viewer) { importing = true }
                if !solo {
                    HStack(spacing: 0) {
                        NavigatorPanel(controller: controller, viewer: viewer)
                            .frame(width: 268)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        Spacer(minLength: 0)
                        ToolsColumn(controller: controller)
                            .frame(width: 322)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    .padding(10)
                }
            }
            if !solo, controller.folderFiles.count > 1 {
                Filmstrip(controller: controller, store: thumbs)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(white: 0.10).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .toolbar { toolbar }
        .navigationTitle(controller.fileName ?? "banksia")
        .navigationSubtitle(subtitle)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: Self.rawTypes
        ) { result in
            if case .success(let url) = result {
                controller.open(url: url)
            }
        }
        .frame(minWidth: 1240, minHeight: 720)
        .onOpenURL { controller.open(url: $0) }
        .onChange(of: solo) { updateInsets() }
        .onChange(of: scenePhase, initial: true) {
            let active = scenePhase == .active
            controller.setApplicationActive(active)
            thumbs.setApplicationActive(active)
        }
        .onChange(of: controller.isRendering, initial: true) {
            thumbs.setInteractiveWorkActive(controller.isRendering || controller.isDragging)
        }
        .onChange(of: controller.isDragging) {
            thumbs.setInteractiveWorkActive(controller.isRendering || controller.isDragging)
        }
        .onAppear {
            updateInsets()
            // Environment form avoids AppKit treating a positional path as a
            // document-open launch during automated shell validation.
            if let path = ProcessInfo.processInfo.environment["BANKSIA_OPEN"] {
                if ProcessInfo.processInfo.environment["BANKSIA_CULLING_BENCHMARK"] == "1" {
                    let sampleCount = Int(
                        ProcessInfo.processInfo.environment[
                            "BANKSIA_CULLING_BENCHMARK_SAMPLES"
                        ] ?? "31"
                    ) ?? 31
                    thumbs.runBenchmark(
                        url: URL(fileURLWithPath: path),
                        sampleCount: sampleCount
                    )
                    return
                }
                controller.open(url: URL(fileURLWithPath: path))
                if ProcessInfo.processInfo.environment["BANKSIA_METAL_BENCHMARK"] == "1" {
                    controller.runMetalBenchmark()
                }
                return
            }
            // Dev loop: `Banksia <shot.raw>` skips the picker entirely; ignore
            // any leading flags.
            if let path = CommandLine.arguments.dropFirst().first,
               !path.hasPrefix("-") {
                controller.open(url: URL(fileURLWithPath: path))
            }
        }
    }

    /// Tell the viewer how much room the floating panels take, so Fit stays
    /// clear of them (panel width + padding + a small gap; nothing when solo).
    private func updateInsets() {
        viewer.insetLeading = solo ? 0 : 268 + 10 + 14
        viewer.insetTrailing = solo ? 0 : 322 + 10 + 14
    }

    private var subtitle: String {
        guard controller.pixelWidth > 0 else { return "" }
        var parts = ["\(controller.pixelWidth) × \(controller.pixelHeight)"]
        if let ms = controller.lastRenderMS {
            parts.append("\(Int(ms.rounded())) ms")
        }
        return parts.joined(separator: "   ·   ")
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button { importing = true } label: {
                Label("Open", systemImage: "folder")
            }
            .keyboardShortcut("o")
            .help("Open a RAW file")
        }
        ToolbarItem {
            Button(action: controller.resetAdjustments) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .disabled(!controller.develop.hasEdits)
            .help("Reset all adjustments")
        }
        ToolbarItem {
            Button(action: controller.runMetalBenchmark) {
                Label(
                    controller.isMetalBenchmarking ? "Benchmarking…" : "Benchmark GPU",
                    systemImage: "gauge.with.dots.needle.67percent"
                )
            }
            .disabled(controller.linearPreview == nil || controller.isMetalBenchmarking)
            .help("Run the 31-frame Phase 2C late-edit benchmark")
        }
        ToolbarItemGroup {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { solo.toggle() }
            } label: {
                Label("Solo", systemImage: solo ? "rectangle.split.3x1" : "rectangle.inset.filled")
            }
            .help(solo ? "Show panels" : "Solo — hide the panels")
            .keyboardShortcut("\\", modifiers: .command)

            Button { NSApp.keyWindow?.toggleFullScreen(nil) } label: {
                Label("Full screen", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .help("Toggle full screen")
            .keyboardShortcut("f", modifiers: [.command, .control])
        }
    }
}
