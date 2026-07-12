import CBanksia
import CoreGraphics
import Foundation
import os.signpost

struct LoadTiming: Sendable {
    let coreLoadDecodeMS: Double
}

struct RenderTiming: Sendable {
    let recipeMS: Double
    let coreRenderMS: Double
    let pixelCopyMS: Double
    let imageBuildMS: Double
    let rendererTotalMS: Double
}

struct MeasuredRender {
    let request: RenderRequest
    let image: CGImage
    let timing: RenderTiming
}

/// A failure reported across the C ABI: the returned code plus the message
/// the engine left in bk_last_error.
struct EngineError: Error, CustomStringConvertible {
    let code: Int32
    let message: String
    var description: String { "engine error \(code): \(message)" }
}

/// Owns the engine handle. The engine is single-threaded per handle with no
/// internal locking, so every bk_* call funnels through this actor — the
/// serialization point banksia.h requires. Renders run on the actor, never
/// on the main thread.
actor Renderer {
    private static let performanceLog = OSLog(
        subsystem: "codes.zms.banksia",
        category: .pointsOfInterest
    )
    private var engine: OpaquePointer?

    deinit {
        if let engine { bk_engine_destroy(engine) }
    }

    func load(path: String) throws {
        _ = try loadMeasured(path: path)
    }

    @discardableResult
    func loadMeasured(path: String) throws -> LoadTiming {
        let engine = try handle()
        let clock = ContinuousClock()
        let start = clock.now
        os_signpost(.begin, log: Self.performanceLog, name: "RAW load and decode")
        defer {
            os_signpost(.end, log: Self.performanceLog, name: "RAW load and decode")
        }
        try check(bk_load_raw(engine, path), engine)
        return LoadTiming(coreLoadDecodeMS: milliseconds(start.duration(to: clock.now)))
    }

    /// Render through the current recipe; `edgeMax` bounds the longest
    /// output edge (0 = full resolution). Returns a CGImage backed by a
    /// *copy* of the engine buffer: the original is only valid until the
    /// next render on this handle, and a displayed image must never alias
    /// memory the engine is about to free.
    func render(recipeJSON: String, edgeMax: UInt32) throws -> CGImage {
        try renderMeasured(recipeJSON: recipeJSON, edgeMax: edgeMax).image
    }

    func renderMeasured(recipeJSON: String, edgeMax: UInt32) throws -> MeasuredRender {
        try render(request: RenderRequest(
            generation: 0,
            recipeJSON: recipeJSON,
            edgeMax: edgeMax,
            intent: .compatibility,
            execution: .strictCPUDisplay
        ))
    }

    func render(request: RenderRequest) throws -> MeasuredRender {
        guard request.execution == .strictCPUDisplay else {
            throw EngineError(
                code: BK_ERR_INVALID_ARGUMENT,
                message: "strict CPU renderer received an incompatible execution contract"
            )
        }
        let engine = try handle()

        let clock = ContinuousClock()
        let totalStart = clock.now
        let recipeStart = clock.now
        do {
            os_signpost(.begin, log: Self.performanceLog, name: "Recipe update")
            defer {
                os_signpost(.end, log: Self.performanceLog, name: "Recipe update")
            }
            try check(bk_set_recipe_json(engine, request.recipeJSON), engine)
        }
        let recipeMS = milliseconds(recipeStart.duration(to: clock.now))

        var width: UInt32 = 0
        var height: UInt32 = 0
        let renderStart = clock.now
        os_signpost(.begin, log: Self.performanceLog, name: "Core render")
        guard let pixels = bk_render(engine, request.edgeMax, &width, &height) else {
            os_signpost(.end, log: Self.performanceLog, name: "Core render")
            throw lastError(engine, code: BK_ERR_RENDER)
        }
        os_signpost(.end, log: Self.performanceLog, name: "Core render")
        let coreRenderMS = milliseconds(renderStart.duration(to: clock.now))

        let copyStart = clock.now
        os_signpost(.begin, log: Self.performanceLog, name: "Engine pixel copy")
        let data = Data(bytes: pixels, count: Int(width) * Int(height) * 4)
        os_signpost(.end, log: Self.performanceLog, name: "Engine pixel copy")
        let pixelCopyMS = milliseconds(copyStart.duration(to: clock.now))

        let imageStart = clock.now
        os_signpost(.begin, log: Self.performanceLog, name: "CGImage construction")
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                  width: Int(width),
                  height: Int(height),
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: Int(width) * 4,
                  space: space,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              )
        else {
            os_signpost(.end, log: Self.performanceLog, name: "CGImage construction")
            throw EngineError(code: BK_ERR_RENDER, message: "CGImage construction failed")
        }
        os_signpost(.end, log: Self.performanceLog, name: "CGImage construction")
        let imageBuildMS = milliseconds(imageStart.duration(to: clock.now))

        return MeasuredRender(
            request: request,
            image: image,
            timing: RenderTiming(
                recipeMS: recipeMS,
                coreRenderMS: coreRenderMS,
                pixelCopyMS: pixelCopyMS,
                imageBuildMS: imageBuildMS,
                rendererTotalMS: milliseconds(totalStart.duration(to: clock.now))
            )
        )
    }

    /// Load and render in one actor-isolated step. There is no `await` between
    /// the load and the render, so concurrent callers can't interleave a load
    /// between another caller's load and its render — each call renders its own
    /// raw. The filmstrip relies on this to thumbnail many files on one handle.
    func loadAndRender(path: String, recipeJSON: String, edgeMax: UInt32) throws -> CGImage {
        try load(path: path)
        return try render(recipeJSON: recipeJSON, edgeMax: edgeMax)
    }

    private func handle() throws -> OpaquePointer {
        if let engine { return engine }
        guard let created = bk_engine_create() else {
            throw EngineError(code: BK_ERR_OUT_OF_MEMORY, message: "bk_engine_create failed")
        }
        engine = created
        return created
    }

    private func check(_ code: Int32, _ engine: OpaquePointer) throws {
        guard code == BK_OK else { throw lastError(engine, code: code) }
    }

    private func lastError(_ engine: OpaquePointer, code: Int32) -> EngineError {
        EngineError(code: code, message: String(cString: bk_last_error(engine)))
    }

    private func milliseconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) * 1_000
            + Double(components.attoseconds) / 1_000_000_000_000_000
    }
}
