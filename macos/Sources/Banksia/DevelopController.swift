import CoreGraphics
import CBanksia
import Foundation
import Observation

enum DevelopChangeDomain {
    case early
    case late
}

/// Orchestration on the main actor: early slider changes coalesce into linear
/// base renders on the Renderer actor; late changes update the retained Metal
/// texture directly. Timing and dimensions let the shell show the boundary.
@MainActor
@Observable
final class DevelopController {
    var develop = DevelopModel()
    private(set) var image: CGImage?
    /// Reserved for an explicitly requested strict-CPU oracle. The GPU-only
    /// Phase 2C viewer does not populate or present it automatically.
    private(set) var baselineImage: CGImage?
    /// Metal remains the primary viewer. This becomes true only after a Metal
    /// initialization or execution failure and selects the strict CPU display
    /// renderer for the remainder of the current file.
    private(set) var useCPUFallback = false
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
    private(set) var linearPreview: LinearPreview?
    private(set) var linearPreviewGeneration: UInt64 = 0
    private(set) var lastLinearPreviewTiming: LinearPreviewTiming?
    private(set) var lastMetalTiming: MetalDevelopTiming?
    private(set) var metalBenchmarkSummary: MetalTimingSummary?
    private(set) var isMetalBenchmarking = false
    private(set) var pixelWidth = 0
    private(set) var pixelHeight = 0
    /// CPU analysis generation, dormant while automatic CPU rendering is off.
    private(set) var renderID: UInt = 0

    /// Set by the sliders while a drag is in flight: renders are bounded to
    /// `previewEdgeMax` until release.
    var isDragging = false
    /// Held true while the compare control is pressed; the canvas shows the
    /// baseline instead of the live image.
    var showBaseline = false

    /// Explicit CPU oracle selection; never used as automatic GPU fallback.
    var displayImage: CGImage? {
        showBaseline ? (baselineImage ?? image) : image
    }

    private let renderer = Renderer()
    private var loadTask: Task<Void, Never>?
    private var renderTask: Task<Void, Never>?
    private var benchmarkTask: Task<Void, Never>?
    private var cpuFallbackTask: Task<Void, Never>?
    private var hasRaw = false

    /// A linear-base render is queued: a burst of early changes replaces the
    /// queued immutable snapshot rather than accumulating work.
    private var requestedLinearRender: RenderRequest?
    private var generationClock = RenderGenerationClock()
    private var metalBenchmarkSamples: [MetalDevelopTiming] = []
    private var metalFrameContinuation: CheckedContinuation<Void, Never>?
    private var benchmarkWhenReady = false
    private var applicationActive = true

    static let linearPreviewEdgeMax: UInt32 = 1440

    func open(url: URL) {
        loadTask?.cancel()
        renderTask?.cancel()
        benchmarkTask?.cancel()
        cpuFallbackTask?.cancel()
        benchmarkTask = nil
        metalFrameContinuation?.resume()
        metalFrameContinuation = nil
        isMetalBenchmarking = false
        metalBenchmarkSummary = nil
        renderTask = nil
        requestedLinearRender = nil
        _ = generationClock.issue()
        baselineImage = nil
        image = nil
        useCPUFallback = false
        linearPreview = nil
        lastRenderMS = nil
        lastLoadTiming = nil
        lastRenderTiming = nil
        lastLinearPreviewTiming = nil
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
                await renderLinearNow(makeRequest(
                    edgeMax: Self.linearPreviewEdgeMax,
                    intent: .settledPreview,
                    execution: .strictCPULinearWorking
                ))
                isRendering = false
            } catch {
                hasRaw = false
                image = nil
                isRendering = false
                statusText = "\(error)"
            }
        }
    }

    /// Early controls rebuild the linear base; late controls need no CPU work.
    func parameterChanged(_ domain: DevelopChangeDomain) {
        if useCPUFallback {
            requestCPUFallbackRender()
            return
        }
        if domain == .early {
            linearPreview = nil
            requestLinearRender()
        }
        // Late controls are rendered directly from the retained Metal texture.
        // No strict-CPU display render is produced in the Phase 2C viewer.
    }

    /// A completed early drag guarantees the newest linear base is queued.
    func dragEnded(_ domain: DevelopChangeDomain) {
        isDragging = false
        if useCPUFallback {
            requestCPUFallbackRender()
            return
        }
        if domain == .early {
            requestLinearRender()
        }
    }

    /// Reset every adjustment and rebuild the linear GPU source.
    func resetAdjustments() {
        guard develop.hasEdits else { return }
        develop.reset()
        if useCPUFallback {
            requestCPUFallbackRender()
        } else {
            linearPreview = nil
            requestLinearRender()
        }
    }

    /// Switches to the strict CPU presenter only after the Metal surface has
    /// reported a real capability or execution failure.
    func handleMetalFailure(_ message: String) {
        guard hasRaw, !useCPUFallback else { return }
        benchmarkTask?.cancel()
        benchmarkTask = nil
        isMetalBenchmarking = false
        useCPUFallback = true
        statusText = "Metal unavailable; using CPU fallback (\(message))"
        requestCPUFallbackRender()
    }

    func recordMetalTiming(_ timing: MetalDevelopTiming) {
        lastMetalTiming = timing
        guard isMetalBenchmarking else { return }
        metalBenchmarkSamples.append(timing)
        metalFrameContinuation?.resume()
        metalFrameContinuation = nil
    }

    func setApplicationActive(_ active: Bool) {
        guard applicationActive != active else { return }
        applicationActive = active
        if active {
            if useCPUFallback {
                requestCPUFallbackRender()
            } else {
                startRenderLoopIfNeeded()
            }
        } else if useCPUFallback {
            cpuFallbackTask?.cancel()
        } else {
            requestedLinearRender = makeRequest(
                edgeMax: Self.linearPreviewEdgeMax,
                intent: .settledPreview,
                execution: .strictCPULinearWorking
            )
            renderTask?.cancel()
        }
    }

    func runMetalBenchmark() {
        guard !isMetalBenchmarking else { return }
        guard linearPreview != nil else {
            benchmarkWhenReady = true
            return
        }
        benchmarkWhenReady = false
        benchmarkTask?.cancel()
        let originalExposure = develop.ev
        metalBenchmarkSamples.removeAll(keepingCapacity: true)
        metalBenchmarkSummary = nil
        isMetalBenchmarking = true
        benchmarkTask = Task {
            for index in 0..<31 where !Task.isCancelled {
                var exposure = (index.isMultiple(of: 2) ? -0.75 : 0.75)
                    + Double(index) * 0.001
                if exposure == develop.ev { exposure += 0.125 }
                await withCheckedContinuation { continuation in
                    metalFrameContinuation = continuation
                    develop.ev = exposure
                }
            }
            guard !Task.isCancelled else { return }
            metalBenchmarkSummary = MetalTimingSummary.make(samples: metalBenchmarkSamples)
            if let summary = metalBenchmarkSummary {
                print(String(format:
                    "metal-benchmark samples=%d visible_p50=%.3f visible_p95=%.3f "
                    + "visible_p99=%.3f encode_p50=%.3f queue_p50=%.3f "
                    + "gpu_p50=%.3f present_p50=%.3f",
                    summary.sampleCount,
                    summary.inputToPresentedP50MS,
                    summary.inputToPresentedP95MS,
                    summary.inputToPresentedP99MS,
                    summary.encodeP50MS,
                    summary.queueP50MS,
                    summary.gpuP50MS,
                    summary.presentWaitP50MS
                ))
            }
            isMetalBenchmarking = false
            benchmarkTask = nil
            develop.ev = originalExposure
        }
    }

    /// Coalescing linear render loop: one render may execute and only the newest
    /// immutable request waits behind it.
    private func requestLinearRender() {
        guard hasRaw else { return }
        requestedLinearRender = makeRequest(
            edgeMax: Self.linearPreviewEdgeMax,
            intent: isDragging ? .interactivePreview : .settledPreview,
            execution: .strictCPULinearWorking
        )
        startRenderLoopIfNeeded()
    }

    private func startRenderLoopIfNeeded() {
        guard applicationActive, requestedLinearRender != nil, renderTask == nil else { return }
        renderTask = Task { await renderLoop() }
    }

    private func renderLoop() async {
        isRendering = true
        while let request = requestedLinearRender, !Task.isCancelled {
            requestedLinearRender = nil
            await renderLinearNow(request)
        }
        isRendering = false
        renderTask = nil
        startRenderLoopIfNeeded()
    }

    private func makeRequest(
        edgeMax: UInt32,
        intent: RenderIntent,
        execution: RenderExecutionContract = .strictCPUDisplay
    ) -> RenderRequest {
        RenderRequest(
            generation: generationClock.issue(),
            recipeJSON: develop.recipeJSON,
            edgeMax: edgeMax,
            intent: intent,
            execution: execution
        )
    }

    private func renderLinearNow(_ request: RenderRequest) async {
        do {
            let rendered = try await renderer.renderLinearPreview(request: request)
            guard !Task.isCancelled,
                  generationClock.accepts(rendered.request.generation)
            else { return }
            linearPreview = rendered.preview
            linearPreviewGeneration = rendered.request.generation
            lastLinearPreviewTiming = rendered.timing
            lastRenderMS = rendered.timing.totalMS
            pixelWidth = rendered.preview.width
            pixelHeight = rendered.preview.height
            if benchmarkWhenReady { runMetalBenchmark() }
        } catch {
            guard !Task.isCancelled, generationClock.accepts(request.generation) else { return }
            if let engineError = error as? EngineError, engineError.code == BK_ERR_CANCELLED {
                return
            }
            // GPU-only mode has no automatic CPU presentation fallback.
            if image == nil { statusText = "\(error)" }
        }
    }

    private func requestCPUFallbackRender() {
        guard hasRaw, applicationActive else { return }
        cpuFallbackTask?.cancel()
        let request = makeRequest(
            edgeMax: Self.linearPreviewEdgeMax,
            intent: isDragging ? .interactivePreview : .settledPreview,
            execution: .strictCPUDisplay
        )
        isRendering = true
        cpuFallbackTask = Task {
            do {
                let rendered = try await renderer.render(request: request)
                guard !Task.isCancelled,
                      generationClock.accepts(rendered.request.generation)
                else { return }
                image = rendered.image
                renderID &+= 1
                lastRenderTiming = rendered.timing
                lastRenderMS = rendered.timing.rendererTotalMS
                pixelWidth = rendered.image.width
                pixelHeight = rendered.image.height
                statusText = "\(fileName ?? "RAW") — CPU fallback"
                isRendering = false
                cpuFallbackTask = nil
            } catch {
                guard !Task.isCancelled,
                      generationClock.accepts(request.generation)
                else { return }
                statusText = "CPU fallback failed: \(error)"
                isRendering = false
                cpuFallbackTask = nil
            }
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

}
