import Foundation
import SwiftUI

/// The engine's tonal path drawn exactly, per channel: white-balance gain, then
/// exposure (×2^ev), then the smoothstep tone curve
/// `y = v + c·(v²(3−2v) − v)` on `v = clamp(x·gain·2^ev, 0, 1)`
/// (emu/pipeline.zig, in pipeline order). Three channels because temperature and
/// tint are per-channel gains — so every adjustment except the fixed sRGB encode
/// moves the curve. At defaults the three overlap into a white diagonal.
struct ToneCurveView: View {
    let ev: Double
    let contrast: Double
    let temperature: Double
    let tint: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.black.opacity(0.35))
            Canvas { context, size in draw(context, size) }
                .padding(7)
        }
        .frame(height: 108)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(.white.opacity(0.06))
        )
    }

    /// Per-channel multiplier: the user's white-balance gain times exposure. The
    /// gains mirror DevelopModel: r=2^temp, g=2^-tint, b=2^-temp.
    private var multipliers: [(gain: Double, color: Color)] {
        [
            (exp2(ev + temperature), .red),
            (exp2(ev - tint), .green),
            (exp2(ev - temperature), .blue),
        ]
    }

    private func draw(_ context: GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        var grid = Path()
        for i in 1...3 {
            let f = CGFloat(i) / 4
            grid.move(to: CGPoint(x: f * w, y: 0)); grid.addLine(to: CGPoint(x: f * w, y: h))
            grid.move(to: CGPoint(x: 0, y: f * h)); grid.addLine(to: CGPoint(x: w, y: f * h))
        }
        context.stroke(grid, with: .color(.white.opacity(0.07)), lineWidth: 0.5)

        var identity = Path()
        identity.move(to: CGPoint(x: 0, y: h)); identity.addLine(to: CGPoint(x: w, y: 0))
        context.stroke(identity, with: .color(.white.opacity(0.16)),
                       style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

        for channel in multipliers {
            let path = curvePath(gain: channel.gain, size: size)
            var layer = context
            layer.blendMode = .screen
            layer.stroke(path, with: .color(channel.color.opacity(0.85)), lineWidth: 1.5)
        }
    }

    private func curvePath(gain: Double, size: CGSize) -> Path {
        var path = Path()
        let steps = 72
        for i in 0...steps {
            let x = Double(i) / Double(steps)
            let v = min(max(x * gain, 0), 1)
            let s = v * v * (3 - 2 * v)
            let y = v + contrast * (s - v)
            let point = CGPoint(x: CGFloat(x) * size.width, y: CGFloat(1 - y) * size.height)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}
