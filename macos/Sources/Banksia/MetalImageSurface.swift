import CoreImage
import MetalKit
import SwiftUI
import os
import os.signpost

enum MetalFailureStage: String, CaseIterable, Sendable {
    case initialization
    case allocation
    case shader
    case commandBuffer
    case drawable
    case completion
}

struct MetalFailure: Error, Equatable, Sendable {
    let stage: MetalFailureStage
    let message: String

    var fallbackExecution: RenderExecutionContract { .strictCPUDisplay }
}

private enum MetalPresentationResourcesState {
    case ready(MetalPresentationResources)
    case failed(MetalFailure)
}

private enum MetalPresentationTuning {
    static let displaySyncEnabled =
        ProcessInfo.processInfo.environment["BANKSIA_METAL_DISPLAY_SYNC"] != "0"
}

enum MetalFailureInjection {
    static func requested(_ stage: MetalFailureStage) -> Bool {
        let value = ProcessInfo.processInfo.environment["BANKSIA_INJECT_METAL_FAILURE"]
        return injectedStage(value: value) == stage
    }

    static func injectedStage(value: String?) -> MetalFailureStage? {
        if value == "1" { return .initialization }
        guard let value else { return nil }
        return MetalFailureStage(rawValue: value)
    }
}

private struct MetalPresentationResources {
    let device: any MTLDevice
    let commandQueue: any MTLCommandQueue
    let displayContext: CIContext
    let lateDevelopPipeline: MetalLateDevelopPipeline

    static let linearWorkingColorSpace = CGColorSpace(
        name: CGColorSpace.extendedLinearITUR_2020
    )!

    static let shared: MetalPresentationResourcesState = {
        guard !MetalFailureInjection.requested(.initialization) else {
            return .failed(MetalFailure(
                stage: .initialization,
                message: "injected Metal initialization failure"
            ))
        }
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else {
            return .failed(MetalFailure(
                stage: .initialization,
                message: "Metal device or command queue is unavailable"
            ))
        }
        commandQueue.label = "Banksia viewer queue"
        do {
            if MetalFailureInjection.requested(.shader) {
                throw MetalFailure(
                    stage: .shader,
                    message: "injected Metal shader failure"
                )
            }
            return .ready(MetalPresentationResources(
                device: device,
                commandQueue: commandQueue,
                displayContext: CIContext(
                    mtlCommandQueue: commandQueue,
                    options: [.cacheIntermediates: false]
                ),
                lateDevelopPipeline: try MetalLateDevelopPipeline(device: device)
            ))
        } catch let failure as MetalFailure {
            return .failed(failure)
        } catch {
            return .failed(MetalFailure(
                stage: .shader,
                message: "Metal shader pipeline failed: \(error.localizedDescription)"
            ))
        }
    }()
}

struct LateDevelopUniforms {
    var exposureEV: Float
    var contrast: Float
}

final class MetalLateDevelopPipeline {
    static let implementationID = "banksia.metal.late-develop-f32.msl1"
    static let passCount = 1
    static let fusedOperations = [
        "scaling",
        "exposure",
        "tone",
        "working-to-output-matrix",
        "clipping",
        "display-encoding",
    ]

    let pipelineState: any MTLRenderPipelineState
    let linearSamplerState: any MTLSamplerState
    let nearestSamplerState: any MTLSamplerState

    init(device: any MTLDevice) throws {
        guard let libraryURL = Bundle.module.url(
            forResource: "LateDevelop",
            withExtension: "metallib"
        ) else {
            throw EngineError(code: -5, message: "compiled Metal library is missing")
        }
        let library = try device.makeLibrary(URL: libraryURL)
        guard let vertex = library.makeFunction(name: "banksia_fullscreen_vertex"),
              let fragment = library.makeFunction(name: "banksia_late_develop_fragment")
        else {
            throw EngineError(code: -5, message: "compiled Metal functions are missing")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = Self.implementationID
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)

        let linearDescriptor = MTLSamplerDescriptor()
        linearDescriptor.minFilter = .linear
        linearDescriptor.magFilter = .linear
        linearDescriptor.sAddressMode = .clampToEdge
        linearDescriptor.tAddressMode = .clampToEdge
        let nearestDescriptor = MTLSamplerDescriptor()
        nearestDescriptor.minFilter = .nearest
        nearestDescriptor.magFilter = .nearest
        nearestDescriptor.sAddressMode = .clampToEdge
        nearestDescriptor.tAddressMode = .clampToEdge
        guard let linearSampler = device.makeSamplerState(descriptor: linearDescriptor),
              let nearestSampler = device.makeSamplerState(descriptor: nearestDescriptor)
        else {
            throw EngineError(code: -7, message: "Metal sampler allocation failed")
        }
        linearSamplerState = linearSampler
        nearestSamplerState = nearestSampler
    }

    func encode(
        source: any MTLTexture,
        destination: any MTLTexture,
        commandBuffer: any MTLCommandBuffer,
        exposureEV: Double,
        contrast: Double,
        nearestSampling: Bool = false
    ) -> Bool {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = destination
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else {
            return false
        }
        encoder.label = Self.implementationID
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(source, index: 0)
        encoder.setFragmentSamplerState(
            nearestSampling ? nearestSamplerState : linearSamplerState,
            index: 0
        )
        var uniforms = LateDevelopUniforms(
            exposureEV: Float(exposureEV),
            contrast: Float(contrast)
        )
        encoder.setFragmentBytes(
            &uniforms,
            length: MemoryLayout<LateDevelopUniforms>.stride,
            index: 0
        )
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        return true
    }
}

struct MetalDevelopTiming: Sendable {
    let uploadMS: Double
    let encodeMS: Double
    let queueMS: Double
    let gpuMS: Double
    let presentWaitMS: Double
    let inputToPresentedMS: Double
    let drawableWidth: Int
    let drawableHeight: Int
}

struct MetalTimingTimestamps: Sendable {
    let submittedAt: CFTimeInterval
    let gpuStartedAt: CFTimeInterval
    let gpuEndedAt: CFTimeInterval
    let presentedAt: CFTimeInterval
    let requestedAt: CFTimeInterval

    func timing(
        uploadMS: Double,
        encodeMS: Double,
        drawableWidth: Int,
        drawableHeight: Int
    ) -> MetalDevelopTiming {
        MetalDevelopTiming(
            uploadMS: uploadMS,
            encodeMS: encodeMS,
            queueMS: max(0, gpuStartedAt - submittedAt) * 1_000,
            gpuMS: max(0, gpuEndedAt - gpuStartedAt) * 1_000,
            presentWaitMS: max(0, presentedAt - gpuEndedAt) * 1_000,
            inputToPresentedMS: max(0, presentedAt - requestedAt) * 1_000,
            drawableWidth: drawableWidth,
            drawableHeight: drawableHeight
        )
    }
}

enum MetalDrawableSizing {
    static func pixels(points: CGSize, backingScale: CGFloat) -> CGSize {
        CGSize(
            width: max(0, points.width * backingScale).rounded(.toNearestOrAwayFromZero),
            height: max(0, points.height * backingScale).rounded(.toNearestOrAwayFromZero)
        )
    }
}

struct MetalTimingSummary: Sendable, Equatable {
    let sampleCount: Int
    let inputToPresentedP50MS: Double
    let inputToPresentedP95MS: Double
    let inputToPresentedP99MS: Double
    let encodeP50MS: Double
    let queueP50MS: Double
    let gpuP50MS: Double
    let presentWaitP50MS: Double

    static func make(samples: [MetalDevelopTiming]) -> MetalTimingSummary? {
        guard !samples.isEmpty else { return nil }
        return MetalTimingSummary(
            sampleCount: samples.count,
            inputToPresentedP50MS: percentile(samples.map(\.inputToPresentedMS), 0.50),
            inputToPresentedP95MS: percentile(samples.map(\.inputToPresentedMS), 0.95),
            inputToPresentedP99MS: percentile(samples.map(\.inputToPresentedMS), 0.99),
            encodeP50MS: percentile(samples.map(\.encodeMS), 0.50),
            queueP50MS: percentile(samples.map(\.queueMS), 0.50),
            gpuP50MS: percentile(samples.map(\.gpuMS), 0.50),
            presentWaitP50MS: percentile(samples.map(\.presentWaitMS), 0.50)
        )
    }

    private static func percentile(_ values: [Double], _ quantile: Double) -> Double {
        let sorted = values.sorted()
        let rank = max(1, Int(ceil(quantile * Double(sorted.count))))
        return sorted[rank - 1]
    }
}

private final class MetalFrameTimingCollector: @unchecked Sendable {
    private let lock = NSLock()
    private let uploadMS: Double
    private let encodeMS: Double
    private let submittedAt: CFTimeInterval
    private let requestedAt: CFTimeInterval
    private let drawableWidth: Int
    private let drawableHeight: Int
    private let onTiming: @MainActor (MetalDevelopTiming) -> Void
    private var gpuTimes: (start: CFTimeInterval, end: CFTimeInterval)?
    private var presentedAt: CFTimeInterval?
    private var reported = false

    init(
        uploadMS: Double,
        encodeMS: Double,
        submittedAt: CFTimeInterval,
        requestedAt: CFTimeInterval,
        drawableWidth: Int,
        drawableHeight: Int,
        onTiming: @escaping @MainActor (MetalDevelopTiming) -> Void
    ) {
        self.uploadMS = uploadMS
        self.encodeMS = encodeMS
        self.submittedAt = submittedAt
        self.requestedAt = requestedAt
        self.drawableWidth = drawableWidth
        self.drawableHeight = drawableHeight
        self.onTiming = onTiming
    }

    func commandCompleted(_ buffer: any MTLCommandBuffer) {
        lock.lock()
        gpuTimes = (buffer.gpuStartTime, buffer.gpuEndTime)
        let timing = makeTimingIfReady()
        lock.unlock()
        publish(timing)
    }

    func drawablePresented(at time: CFTimeInterval) {
        lock.lock()
        presentedAt = time
        let timing = makeTimingIfReady()
        lock.unlock()
        publish(timing)
    }

    private func makeTimingIfReady() -> MetalDevelopTiming? {
        guard !reported, let gpuTimes, let presentedAt else { return nil }
        reported = true
        return MetalTimingTimestamps(
            submittedAt: submittedAt,
            gpuStartedAt: gpuTimes.start,
            gpuEndedAt: gpuTimes.end,
            presentedAt: presentedAt,
            requestedAt: requestedAt
        ).timing(
            uploadMS: uploadMS,
            encodeMS: encodeMS,
            drawableWidth: drawableWidth,
            drawableHeight: drawableHeight
        )
    }

    private func publish(_ timing: MetalDevelopTiming?) {
        guard let timing else { return }
        Task { @MainActor in onTiming(timing) }
    }
}

enum MetalLateDevelop {
    static func apply(
        to source: CIImage,
        exposureEV: Double,
        contrast: Double
    ) -> CIImage {
        var developed = source
        if exposureEV != 0 {
            developed = developed.applyingFilter(
                "CIExposureAdjust",
                parameters: [kCIInputEVKey: exposureEV]
            )
        }
        if contrast > 0 {
            developed = developed.applyingFilter("CIColorClamp", parameters: [
                "inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1),
            ])
            let coefficients = CIVector(
                x: 0,
                y: 1 - contrast,
                z: 3 * contrast,
                w: -2 * contrast
            )
            developed = developed.applyingFilter("CIColorPolynomial", parameters: [
                "inputRedCoefficients": coefficients,
                "inputGreenCoefficients": coefficients,
                "inputBlueCoefficients": coefficients,
                "inputAlphaCoefficients": CIVector(x: 0, y: 1, z: 0, w: 0),
            ])
        }
        return developed
    }
}

enum MetalTextureInput {
    static func linearImage(
        texture: any MTLTexture,
        colorSpace: CGColorSpace
    ) -> CIImage? {
        // Engine buffers are top-row-first. Core Image's image space is
        // bottom-left-origin, so correct the origin exactly once when wrapping
        // the Metal texture. Down-mirrored is a vertical flip without rotation.
        CIImage(
            mtlTexture: texture,
            options: [.colorSpace: colorSpace]
        )?.oriented(.downMirrored)
    }
}

private struct MetalUnavailableView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "Metal render unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .foregroundStyle(.secondary)
    }
}

/// GPU-resident late-develop path. The RGBA32F linear-Rec.2020 base uploads
/// only when its generation changes; exposure and contrast update the retained
/// texture through a compiled Metal shader before hardware sRGB output.
struct MetalLinearImageSurface: View {
    let preview: LinearPreview
    let previewGeneration: UInt64
    let exposureEV: Double
    let contrast: Double
    let nearestSampling: Bool
    let onTiming: @MainActor (MetalDevelopTiming) -> Void
    let onFailure: @MainActor (MetalFailure) -> Void

    @State private var metalFailed = false

    @ViewBuilder
    var body: some View {
        if case .ready(let resources) = MetalPresentationResources.shared, !metalFailed {
            MetalLinearImageView(
                preview: preview,
                previewGeneration: previewGeneration,
                exposureEV: exposureEV,
                contrast: contrast,
                nearestSampling: nearestSampling,
                resources: resources,
                onTiming: onTiming,
                onFailure: { failure in
                    metalFailed = true
                    onFailure(failure)
                }
            )
        } else {
            MetalUnavailableView(
                message: "Preparing CPU fallback…"
            )
            .task {
                if case .failed(let failure) = MetalPresentationResources.shared {
                    onFailure(failure)
                }
            }
        }
    }
}

private struct MetalLinearImageView: NSViewRepresentable {
    let preview: LinearPreview
    let previewGeneration: UInt64
    let exposureEV: Double
    let contrast: Double
    let nearestSampling: Bool
    let resources: MetalPresentationResources
    let onTiming: @MainActor (MetalDevelopTiming) -> Void
    let onFailure: @MainActor (MetalFailure) -> Void

    func makeCoordinator() -> MetalLinearImageRenderer {
        MetalLinearImageRenderer(
            preview: preview,
            previewGeneration: previewGeneration,
            exposureEV: exposureEV,
            contrast: contrast,
            resources: resources,
            onTiming: onTiming,
            onFailure: onFailure
        )
    }

    func makeNSView(context: Context) -> DisplayLinkedMetalView {
        let view = DisplayLinkedMetalView(
            frame: .zero,
            device: resources.device,
            renderer: context.coordinator
        )
        view.nearestSampling = nearestSampling
        view.requestFrame()
        return view
    }

    func updateNSView(_ view: DisplayLinkedMetalView, context: Context) {
        context.coordinator.update(
            preview: preview,
            previewGeneration: previewGeneration,
            exposureEV: exposureEV,
            contrast: contrast
        )
        view.nearestSampling = nearestSampling
        view.requestFrame()
    }
}

/// A CAMetalDisplayLink-backed surface for interactive late develops. Unlike
/// MTKView's on-demand draw scheduling, the display link provides the next
/// display drawable in time for its target presentation interval. This avoids
/// the extra-frame tail that an asynchronous main-queue `draw()` can add.
private final class DisplayLinkedMetalView: NSView, CAMetalDisplayLinkDelegate {
    private let device: any MTLDevice
    private let renderer: MetalLinearImageRenderer
    private var displayLink: CAMetalDisplayLink?
    private var framePending = true
    private var drawableSizeNeedsUpdate = true

    var nearestSampling = false

    init(
        frame: NSRect,
        device: any MTLDevice,
        renderer: MetalLinearImageRenderer
    ) {
        self.device = device
        self.renderer = renderer
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        CAMetalLayer()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else {
            displayLink?.invalidate()
            displayLink = nil
            return
        }
        configureLayer()
        updateDrawableSize()
        startDisplayLinkIfNeeded()
        requestFrame()
    }

    override func layout() {
        super.layout()
        drawableSizeNeedsUpdate = true
        requestFrame()
    }

    func requestFrame() {
        framePending = true
        guard let window,
              window.occlusionState.contains(.visible),
              NSApp.isActive,
              bounds.width > 0,
              bounds.height > 0
        else { return }
        displayLink?.isPaused = false
    }

    func metalDisplayLink(
        _ link: CAMetalDisplayLink,
        needsUpdate update: CAMetalDisplayLink.Update
    ) {
        guard framePending,
              let window,
              window.occlusionState.contains(.visible),
              NSApp.isActive
        else {
            link.isPaused = true
            return
        }
        guard metalLayer.drawableSize.width > 0, metalLayer.drawableSize.height > 0 else {
            link.isPaused = true
            return
        }
        framePending = false
        link.isPaused = true
        renderer.draw(
            drawable: update.drawable,
            drawableSize: metalLayer.drawableSize,
            nearestSampling: nearestSampling,
            requestRetry: { [weak self] in self?.requestFrame() },
            presentationCompleted: { [weak self] in
                self?.applyPendingDrawableSizeAfterPresentation()
            }
        )
    }

    private var metalLayer: CAMetalLayer {
        guard let layer = layer as? CAMetalLayer else {
            preconditionFailure("DisplayLinkedMetalView must use CAMetalLayer")
        }
        return layer
    }

    private func configureLayer() {
        let layer = metalLayer
        layer.device = device
        layer.pixelFormat = .bgra8Unorm_srgb
        layer.framebufferOnly = true
        layer.isOpaque = true
        layer.maximumDrawableCount = 2
        layer.displaySyncEnabled = MetalPresentationTuning.displaySyncEnabled
        layer.allowsNextDrawableTimeout = true
        layer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        layer.presentsWithTransaction = false
        layer.magnificationFilter = nearestSampling ? .nearest : .linear
        drawableSizeNeedsUpdate = true
    }

    private func startDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }
        let link = CAMetalDisplayLink(metalLayer: metalLayer)
        link.delegate = self
        link.preferredFrameLatency = 1
        link.isPaused = true
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func updateDrawableSize() {
        let backingScale = window?.backingScaleFactor ?? 1
        metalLayer.drawableSize = MetalDrawableSizing.pixels(
            points: bounds.size,
            backingScale: backingScale
        )
        drawableSizeNeedsUpdate = false
    }

    private func applyPendingDrawableSizeAfterPresentation() {
        guard drawableSizeNeedsUpdate else { return }
        updateDrawableSize()
        requestFrame()
    }
}

/// Banksia's normal image presenter. The strict CPU renderer still supplies the
/// correctness-oracle CGImage for now, but display scaling, colour conversion,
/// compositing, and presentation go through an on-demand Metal drawable. If
/// Metal cannot initialize or a submitted command fails, this view replaces
/// itself with the previous SwiftUI/CGImage presentation path.
struct MetalImageSurface: View {
    let image: CGImage
    let nearestSampling: Bool

    @State private var metalFailed = false

    var body: some View {
        if case .ready(let resources) = MetalPresentationResources.shared, !metalFailed {
            MetalImageView(
                image: image,
                nearestSampling: nearestSampling,
                resources: resources,
                onFailure: { metalFailed = true }
            )
        } else {
            MetalUnavailableView(
                message: "CPU presentation fallback is disabled for Phase 2C testing."
            )
        }
    }
}

private struct MetalImageView: NSViewRepresentable {
    let image: CGImage
    let nearestSampling: Bool
    let resources: MetalPresentationResources
    let onFailure: @MainActor () -> Void

    func makeCoordinator() -> MetalImageRenderer {
        MetalImageRenderer(
            image: image,
            resources: resources,
            onFailure: onFailure
        )
    }

    func makeNSView(context: Context) -> OnDemandMTKView {
        let view = OnDemandMTKView(frame: .zero, device: resources.device)
        view.delegate = context.coordinator
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .invalid
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.preferredFramesPerSecond = 0
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.layer?.isOpaque = true
        view.layer?.magnificationFilter = nearestSampling ? .nearest : .linear
        if let layer = view.layer as? CAMetalLayer {
            layer.maximumDrawableCount = 2
            layer.displaySyncEnabled = MetalPresentationTuning.displaySyncEnabled
            layer.allowsNextDrawableTimeout = true
            layer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
            layer.presentsWithTransaction = false
        }
        view.requestFrame()
        return view
    }

    func updateNSView(_ view: OnDemandMTKView, context: Context) {
        context.coordinator.update(image: image)
        view.layer?.magnificationFilter = nearestSampling ? .nearest : .linear
        view.requestFrame()
    }
}

final class OnDemandMTKView: MTKView {
    private var framePending = true
    private var drawScheduled = false

    func requestFrame() {
        framePending = true
        scheduleDrawIfReady()
    }

    override func layout() {
        super.layout()
        scheduleDrawIfReady()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NotificationCenter.default.removeObserver(self)
        if let window {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowOcclusionDidChange),
                name: NSWindow.didChangeOcclusionStateNotification,
                object: window
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(displayConfigurationDidChange),
                name: NSWindow.didChangeBackingPropertiesNotification,
                object: window
            )
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowOcclusionDidChange),
            name: NSApplication.didBecomeActiveNotification,
            object: NSApp
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowOcclusionDidChange),
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: NSApp
        )
        scheduleDrawIfReady()
    }

    @objc private func displayConfigurationDidChange() {
        if let window {
            drawableSize = MetalDrawableSizing.pixels(
                points: bounds.size,
                backingScale: window.backingScaleFactor
            )
        }
        requestFrame()
    }

    @objc private func windowOcclusionDidChange() {
        scheduleDrawIfReady()
    }

    private func scheduleDrawIfReady() {
        guard framePending, !drawScheduled,
              let window,
              window.occlusionState.contains(.visible),
              NSApp.isActive,
              bounds.width > 0, bounds.height > 0
        else { return }
        drawScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.drawScheduled = false
            guard self.framePending,
                  let window = self.window,
                  window.occlusionState.contains(.visible),
                  NSApp.isActive,
                  self.drawableSize.width > 0,
                  self.drawableSize.height > 0
            else { return }
            self.framePending = false
            self.draw()
        }
    }
}

private final class MetalImageRenderer: NSObject, MTKViewDelegate {
    private static let log = Logger(
        subsystem: "codes.zms.banksia",
        category: "metal-presentation"
    )
    private static let performanceLog = OSLog(
        subsystem: "codes.zms.banksia",
        category: .pointsOfInterest
    )
    private static let outputColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private let resources: MetalPresentationResources
    private let onFailure: @MainActor () -> Void
    private let inFlightLock = NSLock()
    private var inFlightCount = 0
    private var retryNewestFrame = false
    private var image: CIImage

    init(
        image: CGImage,
        resources: MetalPresentationResources,
        onFailure: @escaping @MainActor () -> Void
    ) {
        self.image = CIImage(cgImage: image)
        self.resources = resources
        self.onFailure = onFailure
        super.init()
    }

    func update(image: CGImage) {
        self.image = CIImage(cgImage: image)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        (view as? OnDemandMTKView)?.requestFrame()
    }

    func draw(in view: MTKView) {
        guard view.drawableSize.width > 0, view.drawableSize.height > 0 else { return }
        guard admitFrame() else { return }
        guard let drawable = view.currentDrawable else {
            _ = releaseFrame()
            return
        }
        guard let commandBuffer = resources.commandQueue.makeCommandBuffer() else {
            _ = releaseFrame()
            reportFailure("Metal command-buffer creation failed")
            return
        }

        let output = CGRect(
            x: 0,
            y: 0,
            width: view.drawableSize.width,
            height: view.drawableSize.height
        )
        let source = image.extent
        guard source.width > 0, source.height > 0 else {
            _ = releaseFrame()
            return
        }
        let normalized = image.transformed(by: CGAffineTransform(
            translationX: -source.minX,
            y: -source.minY
        ))
        let scaled = normalized.transformed(by: CGAffineTransform(
            scaleX: output.width / source.width,
            y: output.height / source.height
        ))

        let signpostID = OSSignpostID(log: Self.performanceLog)
        os_signpost(
            .begin,
            log: Self.performanceLog,
            name: "Metal image presentation",
            signpostID: signpostID
        )
        commandBuffer.label = "Banksia image presentation"
        resources.displayContext.render(
            scaled,
            to: drawable.texture,
            commandBuffer: commandBuffer,
            bounds: output,
            colorSpace: Self.outputColorSpace
        )
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { buffer in
            os_signpost(
                .end,
                log: Self.performanceLog,
                name: "Metal image presentation",
                signpostID: signpostID
            )
            let retry = self.releaseFrame()
            if retry {
                Task { @MainActor [weak view] in
                    (view as? OnDemandMTKView)?.requestFrame()
                }
            }
            if let error = buffer.error {
                self.reportFailure("Metal image presentation failed: \(error.localizedDescription)")
            }
        }
        commandBuffer.commit()
    }

    private func admitFrame() -> Bool {
        inFlightLock.lock()
        defer { inFlightLock.unlock() }
        guard inFlightCount < 2 else {
            retryNewestFrame = true
            return false
        }
        inFlightCount += 1
        return true
    }

    private func releaseFrame() -> Bool {
        inFlightLock.lock()
        defer { inFlightLock.unlock() }
        inFlightCount -= 1
        let retry = retryNewestFrame
        retryNewestFrame = false
        return retry
    }

    private func reportFailure(_ message: String) {
        Self.log.error("\(message, privacy: .public)")
        Task { @MainActor in onFailure() }
    }
}

private final class MetalLinearImageRenderer: NSObject {
    private static let log = Logger(
        subsystem: "codes.zms.banksia",
        category: "metal-linear-develop"
    )
    private static let performanceLog = OSLog(
        subsystem: "codes.zms.banksia",
        category: .pointsOfInterest
    )
    private let resources: MetalPresentationResources
    private let onTiming: @MainActor (MetalDevelopTiming) -> Void
    private let onFailure: @MainActor (MetalFailure) -> Void
    private let inFlightLock = NSLock()
    private var admission = MetalFrameAdmissionState()
    private var previewGeneration: UInt64
    private var texture: (any MTLTexture)?
    private var exposureEV: Double
    private var contrast: Double
    private var requestedAt = CACurrentMediaTime()
    private var pendingUploadMS = 0.0
    private var consecutiveNilDrawables = 0
    private var frameGeneration: UInt64 = 1

    init(
        preview: LinearPreview,
        previewGeneration: UInt64,
        exposureEV: Double,
        contrast: Double,
        resources: MetalPresentationResources,
        onTiming: @escaping @MainActor (MetalDevelopTiming) -> Void,
        onFailure: @escaping @MainActor (MetalFailure) -> Void
    ) {
        self.previewGeneration = previewGeneration
        self.exposureEV = exposureEV
        self.contrast = contrast
        self.resources = resources
        self.onTiming = onTiming
        self.onFailure = onFailure
        super.init()
        upload(preview)
    }

    func update(
        preview: LinearPreview,
        previewGeneration: UInt64,
        exposureEV: Double,
        contrast: Double
    ) {
        let changed = previewGeneration != self.previewGeneration
            || exposureEV != self.exposureEV
            || contrast != self.contrast
        if changed {
            requestedAt = CACurrentMediaTime()
            frameGeneration &+= 1
        }
        if previewGeneration != self.previewGeneration {
            self.previewGeneration = previewGeneration
            upload(preview)
        }
        self.exposureEV = exposureEV
        self.contrast = contrast
    }

    func draw(
        drawable: any CAMetalDrawable,
        drawableSize: CGSize,
        nearestSampling: Bool,
        requestRetry: @escaping @MainActor () -> Void,
        presentationCompleted: @escaping @MainActor () -> Void
    ) {
        let encodeStartedAt = CACurrentMediaTime()
        guard let texture,
              drawableSize.width > 0,
              drawableSize.height > 0
        else { return }
        guard admitFrame(generation: frameGeneration) else { return }
        if MetalFailureInjection.requested(.drawable) {
            _ = releaseFrame()
            reportFailure(MetalFailure(
                stage: .drawable,
                message: "injected Metal drawable failure"
            ))
            return
        }
        consecutiveNilDrawables = 0
        if MetalFailureInjection.requested(.commandBuffer) {
            _ = releaseFrame()
            reportFailure(MetalFailure(
                stage: .commandBuffer,
                message: "injected Metal command-buffer failure"
            ))
            return
        }
        guard let commandBuffer = resources.commandQueue.makeCommandBuffer() else {
            _ = releaseFrame()
            reportFailure(MetalFailure(
                stage: .commandBuffer,
                message: "Metal command-buffer creation failed"
            ))
            return
        }

        let signpostID = OSSignpostID(log: Self.performanceLog)
        os_signpost(
            .begin,
            log: Self.performanceLog,
            name: "Metal late develop",
            signpostID: signpostID
        )
        os_signpost(
            .begin,
            log: Self.performanceLog,
            name: "Metal late-develop encode",
            signpostID: signpostID
        )
        commandBuffer.label = "Banksia linear late develop"
        guard resources.lateDevelopPipeline.encode(
            source: texture,
            destination: drawable.texture,
            commandBuffer: commandBuffer,
            exposureEV: exposureEV,
            contrast: contrast,
            nearestSampling: nearestSampling
        ) else {
            _ = releaseFrame()
            reportFailure(MetalFailure(
                stage: .commandBuffer,
                message: "Metal late-develop command encoding failed"
            ))
            return
        }
        commandBuffer.present(drawable)
        os_signpost(
            .end,
            log: Self.performanceLog,
            name: "Metal late-develop encode",
            signpostID: signpostID
        )
        let encodedAt = CACurrentMediaTime()
        let requestAt = requestedAt
        let uploadMS = pendingUploadMS
        pendingUploadMS = 0
        let drawableWidth = Int(drawableSize.width)
        let drawableHeight = Int(drawableSize.height)
        let submittedGeneration = frameGeneration
        let timingCollector = MetalFrameTimingCollector(
            uploadMS: uploadMS,
            encodeMS: max(0, encodedAt - encodeStartedAt) * 1_000,
            submittedAt: encodedAt,
            requestedAt: requestAt,
            drawableWidth: drawableWidth,
            drawableHeight: drawableHeight,
            onTiming: { [weak self] timing in
                guard let self, self.frameGeneration == submittedGeneration else { return }
                self.onTiming(timing)
            }
        )
        drawable.addPresentedHandler {
            timingCollector.drawablePresented(at: $0.presentedTime)
            Task { @MainActor in presentationCompleted() }
        }
        commandBuffer.addCompletedHandler { buffer in
            timingCollector.commandCompleted(buffer)
            os_signpost(
                .end,
                log: Self.performanceLog,
                name: "Metal late develop",
                signpostID: signpostID
            )
            let retry = self.releaseFrame()
            if retry {
                Task { @MainActor in requestRetry() }
            }
            if MetalFailureInjection.requested(.completion) {
                self.reportFailure(MetalFailure(
                    stage: .completion,
                    message: "injected Metal command completion failure"
                ))
            } else if let error = buffer.error {
                self.reportFailure(MetalFailure(
                    stage: .completion,
                    message: "Metal late develop failed: \(error.localizedDescription)"
                ))
            }
        }
        commandBuffer.commit()
    }

    private func upload(_ preview: LinearPreview) {
        let uploadStartedAt = CACurrentMediaTime()
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: preview.width,
            height: preview.height,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead]
        if MetalFailureInjection.requested(.allocation) {
            reportFailure(MetalFailure(
                stage: .allocation,
                message: "injected Metal texture allocation failure"
            ))
            return
        }
        guard let texture = resources.device.makeTexture(descriptor: descriptor) else {
            reportFailure(MetalFailure(
                stage: .allocation,
                message: "RGBA32F linear preview texture allocation failed"
            ))
            return
        }
        texture.label = "Banksia linear Rec.2020 preview"

        os_signpost(.begin, log: Self.performanceLog, name: "Linear texture upload")
        preview.rgba32Float.withUnsafeBytes { bytes in
            guard let address = bytes.baseAddress else { return }
            texture.replace(
                region: MTLRegionMake2D(0, 0, preview.width, preview.height),
                mipmapLevel: 0,
                withBytes: address,
                bytesPerRow: preview.bytesPerRow
            )
        }
        os_signpost(.end, log: Self.performanceLog, name: "Linear texture upload")
        pendingUploadMS = max(0, CACurrentMediaTime() - uploadStartedAt) * 1_000

        self.texture = texture
    }

    private func admitFrame(generation: UInt64) -> Bool {
        inFlightLock.lock()
        defer { inFlightLock.unlock() }
        return admission.request(generation: generation) == .admitted
    }

    private func releaseFrame() -> Bool {
        inFlightLock.lock()
        defer { inFlightLock.unlock() }
        return admission.complete() != nil
    }

    private func reportFailure(_ failure: MetalFailure) {
        Self.log.error("\(failure.message, privacy: .public)")
        Task { @MainActor in onFailure(failure) }
    }
}
