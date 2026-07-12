import CBanksia
import CoreGraphics
import Foundation

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
    private var engine: OpaquePointer?

    deinit {
        if let engine { bk_engine_destroy(engine) }
    }

    func load(path: String) throws {
        let engine = try handle()
        try check(bk_load_raw(engine, path), engine)
    }

    /// Render through the current recipe; `edgeMax` bounds the longest
    /// output edge (0 = full resolution). Returns a CGImage backed by a
    /// *copy* of the engine buffer: the original is only valid until the
    /// next render on this handle, and a displayed image must never alias
    /// memory the engine is about to free.
    func render(recipeJSON: String, edgeMax: UInt32) throws -> CGImage {
        let engine = try handle()
        try check(bk_set_recipe_json(engine, recipeJSON), engine)

        var width: UInt32 = 0
        var height: UInt32 = 0
        guard let pixels = bk_render(engine, edgeMax, &width, &height) else {
            throw lastError(engine, code: BK_ERR_RENDER)
        }
        let data = Data(bytes: pixels, count: Int(width) * Int(height) * 4)

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
            throw EngineError(code: BK_ERR_RENDER, message: "CGImage construction failed")
        }
        return image
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
}
