import CoreGraphics
import Foundation
import Observation

/// Orchestration on the main actor: slider changes debounce into renders on
/// the Renderer actor; finished CGImages come back here for display. Everything
/// added beyond the render loop is UI telemetry — timing, dimensions, activity —
/// so the shell can *show* how the engine behaves, not just what it produced.
@MainActor
@Observable
final class DevelopController {
    var develop = DevelopModel()
    private(set) var image: CGImage?
    /// The neutral (all-sliders-zero) render, captured once per file so the
    /// compare gesture has an instant "before" to flash.
    private(set) var baselineImage: CGImage?
    private(set) var statusText = "Open a DNG, CR2, or CR3 to begin."
    private(set) var fileName: String?
    /// The open file and its sibling RAWs, for the filmstrip.
    private(set) var currentURL: URL?
    private(set) var folderFiles: [URL] = []

    private static let rawExtensions: Set<String> = ["dng", "cr2", "cr3"]

    /// A render is on the actor right now: drives the non-blocking HUD pill.
    private(set) var isRendering = false
    /// Wall-clock latency of the last completed render, as the shell measures
    /// it (actor hop included) — the number a human watches while dragging.
    private(set) var lastRenderMS: Double?
    private(set) var lastLoadTiming: LoadTiming?
    private(set) var lastRenderTiming: RenderTiming?
    private(set) var pixelWidth = 0
    private(set) var pixelHeight = 0
    /// Bumps on every displayed frame so the histogram can key its recompute
    /// off `.task(id:)` without diffing CGImages.
    private(set) var renderID: UInt = 0

    /// Set by the sliders while a drag is in flight: renders are bounded to
    /// `previewEdgeMax` until release.
    var isDragging = false
    /// Held true while the compare control is pressed; the canvas shows the
    /// baseline instead of the live image.
    var showBaseline = false

    /// What the canvas should actually display: the pristine baseline while
    /// comparing, the live render otherwise.
    var displayImage: CGImage? {
        showBaseline ? (baselineImage ?? image) : image
    }

    private let renderer = Renderer()
    private var loadTask: Task<Void, Never>?
    private var renderTask: Task<Void, Never>?
    private var baselineTask: Task<Void, Never>?
    private var hasRaw = false

    /// A render is queued: the loop reads the latest recipe when it gets to it,
    /// so a burst of slider changes coalesces into whatever value is current.
    private var renderRequested = false
    private var requestedEdgeMax: UInt32 = 0

    /// The "feels responsive" bound while a slider drags; release renders
    /// full resolution.
    static let previewEdgeMax: UInt32 = 1024

    func open(url: URL) {
        loadTask?.cancel()
        renderTask?.cancel()
        baselineTask?.cancel()
        renderTask = nil
        renderRequested = false
        baselineImage = nil
        image = nil
        lastRenderMS = nil
        lastLoadTiming = nil
        lastRenderTiming = nil
        fileName = url.lastPathComponent
        currentURL = url
        folderFiles = Self.listRawSiblings(of: url)
        statusText = "Opening \(url.lastPathComponent)…"
        isRendering = true
        loadTask = Task {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                lastLoadTiming = try await renderer.loadMeasured(path: url.path)
                guard !Task.isCancelled else { return }
                hasRaw = true
                statusText = url.lastPathComponent
                await renderNow(edgeMax: 0)
                isRendering = false
                prepareBaseline()
            } catch {
                hasRaw = false
                image = nil
                isRendering = false
                statusText = "\(error)"
            }
        }
    }

    /// A slider value moved: preview-resolution render while dragging,
    /// full resolution otherwise.
    func parameterChanged() {
        requestRender(edgeMax: isDragging ? Self.previewEdgeMax : 0)
    }

    /// A slider drag ended: replace the preview with the full render.
    func dragEnded() {
        isDragging = false
        requestRender(edgeMax: 0)
    }

    /// Reset every adjustment and re-render at full resolution.
    func resetAdjustments() {
        guard develop.hasEdits else { return }
        develop.reset()
        requestRender(edgeMax: 0)
    }

    /// Coalescing render loop: mark a render wanted and, if the loop is idle,
    /// start it. Renders never cancel each other mid-flight — the loop just
    /// re-renders the current recipe when one finishes, so continuous dragging
    /// produces a steady stream of live frames instead of starving.
    private func requestRender(edgeMax: UInt32) {
        guard hasRaw else { return }
        requestedEdgeMax = edgeMax
        renderRequested = true
        guard renderTask == nil else { return }
        renderTask = Task { await renderLoop() }
    }

    private func renderLoop() async {
        isRendering = true
        while renderRequested, !Task.isCancelled {
            renderRequested = false
            await renderNow(edgeMax: requestedEdgeMax)
        }
        isRendering = false
        renderTask = nil
    }

    private func renderNow(edgeMax: UInt32) async {
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let rendered = try await renderer.renderMeasured(
                recipeJSON: develop.recipeJSON,
                edgeMax: edgeMax
            )
            guard !Task.isCancelled else { return }
            image = rendered.image
            pixelWidth = rendered.image.width
            pixelHeight = rendered.image.height
            lastRenderTiming = rendered.timing
            let elapsed = start.duration(to: clock.now).components
            lastRenderMS = Double(elapsed.seconds) * 1000
                + Double(elapsed.attoseconds) / 1_000_000_000_000_000
            renderID &+= 1
        } catch {
            guard !Task.isCancelled else { return }
            statusText = "\(error)"
        }
    }

    /// Every RAW in the same folder, name-sorted, for the filmstrip. Best-effort:
    /// a non-sandboxed dev shell can list the directory freely.
    private static func listRawSiblings(of url: URL) -> [URL] {
        let directory = url.deletingLastPathComponent()
        let items = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        )) ?? []
        return items
            .filter { rawExtensions.contains($0.pathExtension.lowercased()) }
            .sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent)
                    == .orderedAscending
            }
    }

    /// Render the neutral recipe once so the compare gesture is instant. Runs
    /// off the render task so a later slider drag never cancels it.
    private func prepareBaseline() {
        guard hasRaw, baselineImage == nil else { return }
        let neutral = DevelopModel().recipeJSON
        baselineTask = Task {
            let rendered = try? await renderer.render(recipeJSON: neutral, edgeMax: 0)
            guard !Task.isCancelled else { return }
            baselineImage = rendered
        }
    }
}
