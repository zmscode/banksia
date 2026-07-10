import CoreGraphics
import Foundation
import Observation

/// Orchestration on the main actor: slider changes debounce into renders on
/// the Renderer actor; finished CGImages come back here for display.
@MainActor
@Observable
final class DevelopController {
    var develop = DevelopModel()
    private(set) var image: CGImage?
    private(set) var statusText = "Open a DNG to begin (make one: banksia synth shot.dng)."
    /// Set by the sliders while a drag is in flight: renders are bounded to
    /// `previewEdgeMax` until release.
    var isDragging = false

    private let renderer = Renderer()
    private var renderTask: Task<Void, Never>?
    private var hasRaw = false

    /// The "feels responsive" bound while a slider drags; release renders
    /// full resolution.
    static let previewEdgeMax: UInt32 = 1024

    func open(url: URL) {
        renderTask?.cancel()
        renderTask = Task {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                try await renderer.load(path: url.path)
                hasRaw = true
                statusText = url.lastPathComponent
                await renderNow(edgeMax: 0)
            } catch {
                hasRaw = false
                image = nil
                statusText = "\(error)"
            }
        }
    }

    /// A slider value moved: preview-resolution render while dragging,
    /// full resolution otherwise.
    func parameterChanged() {
        scheduleRender(edgeMax: isDragging ? Self.previewEdgeMax : 0)
    }

    /// A slider drag ended: replace the preview with the full render.
    func dragEnded() {
        isDragging = false
        scheduleRender(edgeMax: 0)
    }

    private func scheduleRender(edgeMax: UInt32) {
        guard hasRaw else { return }
        renderTask?.cancel()
        renderTask = Task {
            // One frame of debounce coalesces slider spam; the render
            // itself serializes on the actor.
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            await renderNow(edgeMax: edgeMax)
        }
    }

    private func renderNow(edgeMax: UInt32) async {
        do {
            let rendered = try await renderer.render(
                recipeJSON: develop.recipeJSON,
                edgeMax: edgeMax
            )
            if !Task.isCancelled { image = rendered }
        } catch {
            statusText = "\(error)"
        }
    }
}
