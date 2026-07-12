import AppKit
import SwiftUI

/// The left panel: passive inspection — an overview of the whole frame (handy
/// once the viewer is zoomed in), the file's metadata, and the exact recipe
/// JSON the engine received.
struct NavigatorPanel: View {
    let controller: DevelopController
    let viewer: ViewerState

    var body: some View {
        VStack(spacing: 10) {
            navigator
            info
            recipe
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var navigator: some View {
        ToolCard("Navigator", systemImage: "map") {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.black.opacity(0.3))
                if let image = controller.image {
                    thumbnail(image)
                } else {
                    Text("no image")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(height: 150)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.white.opacity(0.06))
            )
        }
    }

    private func thumbnail(_ image: CGImage) -> some View {
        GeometryReader { geo in
            let box = CGSize(width: geo.size.width - 10, height: geo.size.height - 10)
            let fitted = fit(CGSize(width: image.width, height: image.height), in: box)
            let originX = (geo.size.width - fitted.width) / 2
            let originY = (geo.size.height - fitted.height) / 2
            ZStack(alignment: .topLeading) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .padding(5)
                if let rect = viewer.visibleRect {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color.white.opacity(0.95), lineWidth: 1.5)
                        .frame(width: fitted.width * rect.width, height: fitted.height * rect.height)
                        .offset(x: originX + fitted.width * rect.minX,
                                y: originY + fitted.height * rect.minY)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                }
            }
        }
    }

    private func fit(_ size: CGSize, in box: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0, box.width > 0, box.height > 0 else { return box }
        let s = min(box.width / size.width, box.height / size.height)
        return CGSize(width: size.width * s, height: size.height * s)
    }

    private var info: some View {
        ToolCard("Info", systemImage: "info.circle") {
            infoRow("File", controller.fileName ?? "—")
            infoRow("Dimensions", controller.pixelWidth > 0
                ? "\(controller.pixelWidth) × \(controller.pixelHeight)" : "—")
            infoRow("Last render", controller.lastRenderMS.map {
                "\(Int($0.rounded())) ms"
            } ?? "—")
            infoRow("Engine", "v2")
        }
    }

    private var recipe: some View {
        ToolCard("Recipe", systemImage: "curlybraces", trailing: {
            cardIconButton("doc.on.doc", help: "Copy recipe JSON") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(controller.develop.recipeJSON, forType: .string)
            }
        }) {
            Text(controller.develop.recipeJSON)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
