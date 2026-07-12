import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var controller = DevelopController()
    @State private var viewer = ViewerState()
    @State private var thumbs = ThumbnailStore()
    @State private var importing = false
    @State private var leftWidth: CGFloat = 268
    @State private var rightWidth: CGFloat = 322

    private static let rawTypes = ["dng", "cr2", "cr3"].compactMap {
        UTType(filenameExtension: $0, conformingTo: .image)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                NavigatorPanel(controller: controller, viewer: viewer)
                    .frame(width: leftWidth)
                    .padding(.leading, 10).padding(.vertical, 10)
                PanelDivider(width: $leftWidth, range: 210...440, sign: 1)
                PreviewCanvas(controller: controller, viewer: viewer) { importing = true }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                PanelDivider(width: $rightWidth, range: 250...460, sign: -1)
                ToolsColumn(controller: controller)
                    .frame(width: rightWidth)
                    .padding(.trailing, 10).padding(.vertical, 10)
            }
            if controller.folderFiles.count > 1 {
                Filmstrip(controller: controller, store: thumbs)
            }
        }
        // Backdrop as a background, never a sibling: a background is sized to the
        // content, so the blurred frame can't inflate the layout and shove the
        // fixed-width panels off-screen when an image loads.
        .background(backdrop)
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
        .onAppear {
            // Dev loop: `Banksia <shot.raw>` skips the picker entirely; ignore
            // any leading flags.
            if let path = CommandLine.arguments.dropFirst().first,
               !path.hasPrefix("-") {
                controller.open(url: URL(fileURLWithPath: path))
            }
        }
    }

    /// A heavily blurred, darkened copy of the current frame fills the window so
    /// the Liquid Glass tool cards refract the photograph's own colour. Falls
    /// back to flat near-black before anything is loaded.
    private var backdrop: some View {
        ZStack {
            Theme.base
            if let image = controller.image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 90, opaque: true)
                    .opacity(0.38)
            }
            LinearGradient(
                colors: [.black.opacity(0.5), .black.opacity(0.32)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
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
    }
}
