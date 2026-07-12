import MetalKit
import SwiftUI
import os

private enum MetalSurfaceSystem {
    static let device = MTLCreateSystemDefaultDevice()
    static let commandQueue: (any MTLCommandQueue)? = {
        let queue = device?.makeCommandQueue()
        queue?.label = "Banksia viewer queue"
        return queue
    }()
}

/// Opt-in Phase 2C drawable proof. It deliberately renders only on demand: no
/// display link and therefore no idle 60/120 fps GPU work for a still editor.
struct MetalSurfaceProof: View {
    var body: some View {
        if let device = MetalSurfaceSystem.device,
           let commandQueue = MetalSurfaceSystem.commandQueue {
            MetalSurfaceView(
                device: device,
                commandQueue: commandQueue
            )
                .overlay(alignment: .top) {
                    Text("Metal on-demand surface · \(device.name)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(12)
                }
        } else {
            ContentUnavailableView(
                "Metal unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("The strict CPU viewer remains available.")
            )
        }
    }
}

private struct MetalSurfaceView: NSViewRepresentable {
    let device: any MTLDevice
    let commandQueue: any MTLCommandQueue

    func makeCoordinator() -> MetalSurfaceRenderer {
        MetalSurfaceRenderer(device: device, commandQueue: commandQueue)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: device)
        view.delegate = context.coordinator
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .invalid
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.clearColor = MTLClearColor(red: 0.035, green: 0.055, blue: 0.075, alpha: 1)
        (view.layer as? CAMetalLayer)?.maximumDrawableCount = 2
        view.setNeedsDisplay(view.bounds)
        return view
    }

    func updateNSView(_ view: MTKView, context: Context) {
        // State changes will explicitly invalidate the view once this proof
        // consumes a developed texture. Static content does no recurring work.
    }
}

private final class MetalSurfaceRenderer: NSObject, MTKViewDelegate {
    private static let log = Logger(
        subsystem: "codes.zms.banksia",
        category: "metal-surface"
    )

    let device: any MTLDevice
    private let commandQueue: any MTLCommandQueue
    private let inFlightLock = NSLock()
    private var inFlightCount = 0

    init(device: any MTLDevice, commandQueue: any MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // MTKView supplies pixel dimensions here, not SwiftUI point bounds.
        guard size.width > 0, size.height > 0 else { return }
        view.setNeedsDisplay(view.bounds)
    }

    func draw(in view: MTKView) {
        guard admitFrame(),
              view.drawableSize.width > 0,
              view.drawableSize.height > 0,
              let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            releaseFrame()
            return
        }

        commandBuffer.label = "Banksia on-demand surface proof"
        encoder.label = "Banksia drawable clear"
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { buffer in
            self.releaseFrame()
            if let error = buffer.error {
                Self.log.error("Metal surface command failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        commandBuffer.commit()
    }

    private func admitFrame() -> Bool {
        inFlightLock.lock()
        defer { inFlightLock.unlock() }
        guard inFlightCount < 2 else { return false }
        inFlightCount += 1
        return true
    }

    private func releaseFrame() {
        inFlightLock.lock()
        inFlightCount -= 1
        inFlightLock.unlock()
    }
}
