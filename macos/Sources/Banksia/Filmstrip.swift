import CoreGraphics
import SwiftUI

/// Renders neutral-develop thumbnails on its own engine handle so the strip
/// never contends with the main viewer's renders (distinct handles are
/// independent per banksia.h). Lazy: a thumbnail is requested when its cell
/// scrolls on screen.
@MainActor
@Observable
final class ThumbnailStore {
    private(set) var images: [URL: CGImage] = [:]
    private let renderer = Renderer()
    private let neutral = DevelopModel().recipeJSON
    private var inFlight: Set<URL> = []

    func request(_ url: URL) {
        guard images[url] == nil, !inFlight.contains(url) else { return }
        inFlight.insert(url)
        Task {
            defer { inFlight.remove(url) }
            do {
                // One atomic call — a concurrent request can't swap the loaded
                // raw out from under this render, so each thumbnail is its own.
                let image = try await renderer.loadAndRender(
                    path: url.path, recipeJSON: neutral, edgeMax: 220
                )
                images[url] = image
            } catch {
                // Leave a placeholder; a failed thumbnail isn't worth surfacing.
            }
        }
    }
}

/// The bottom filmstrip: every RAW in the current file's folder, click to open.
struct Filmstrip: View {
    let controller: DevelopController
    let store: ThumbnailStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(controller.folderFiles, id: \.self) { url in
                    cell(url)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 86)
        .background(.black.opacity(0.18))
        .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 1) }
    }

    private func cell(_ url: URL) -> some View {
        let isCurrent = url == controller.currentURL
        return Button {
            controller.open(url: url)
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(.black.opacity(0.35))
                    if let image = store.images[url] {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .interpolation(.medium)
                            .scaledToFill()
                    } else {
                        ProgressView().controlSize(.small)
                    }
                }
                .frame(width: 78, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(
                            isCurrent ? Theme.accent : .white.opacity(0.12),
                            lineWidth: isCurrent ? 2 : 1
                        )
                )
                Text(url.lastPathComponent)
                    .font(.system(size: 9))
                    .foregroundStyle(isCurrent ? Theme.textPrimary : Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(width: 78)
            }
        }
        .buttonStyle(.plain)
        .onAppear { store.request(url) }
    }
}
