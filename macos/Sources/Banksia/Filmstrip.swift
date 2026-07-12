import CoreGraphics
import SwiftUI

/// Renders neutral-develop thumbnails on its own engine handle so the strip
/// never contends with the main viewer's renders (distinct handles are
/// independent per banksia.h). Lazy: a thumbnail is requested when its cell
/// scrolls on screen.
@MainActor
@Observable
final class ThumbnailStore {
    static let maximumQueuedRequests = 12

    private(set) var images: [URL: CGImage] = [:]
    private let renderer = Renderer()
    private let neutral = DevelopModel().recipeJSON
    private var pending: [URL] = []
    private var active: URL?
    private var worker: Task<Void, Never>?
    private var applicationActive = true
    private var interactiveWorkActive = false

    private var isPaused: Bool { !applicationActive || interactiveWorkActive }

    func request(_ url: URL) {
        guard images[url] == nil, active != url, !pending.contains(url) else { return }
        guard pending.count < Self.maximumQueuedRequests else { return }
        pending.append(url)
        startWorkerIfNeeded()
    }

    func cancel(_ url: URL) {
        pending.removeAll { $0 == url }
    }

    func setApplicationActive(_ active: Bool) {
        applicationActive = active
        updateWorkerState()
    }

    func setInteractiveWorkActive(_ active: Bool) {
        interactiveWorkActive = active
        updateWorkerState()
    }

    private func updateWorkerState() {
        if isPaused {
            worker?.cancel()
        } else {
            startWorkerIfNeeded()
        }
    }

    private func startWorkerIfNeeded() {
        guard worker == nil, !isPaused else { return }
        worker = Task { await drainQueue() }
    }

    private func drainQueue() async {
        while !Task.isCancelled, !isPaused, !pending.isEmpty {
            let url = pending.removeFirst()
            active = url
            do {
                // One atomic call — a concurrent request can't swap the loaded
                // raw out from under this render, so each thumbnail is its own.
                let image = try await renderer.loadAndRender(
                    path: url.path, recipeJSON: neutral, edgeMax: 220
                )
                if !Task.isCancelled { images[url] = image }
            } catch {
                // Leave a placeholder; a failed thumbnail isn't worth surfacing.
            }
            active = nil
        }
        worker = nil
        if !isPaused, !pending.isEmpty { startWorkerIfNeeded() }
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
        .onDisappear { store.cancel(url) }
    }
}
