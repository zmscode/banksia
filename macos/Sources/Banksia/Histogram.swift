import CoreGraphics
import SwiftUI
import os.signpost

/// A 256-bin count per channel, read straight off a rendered frame. This is the
/// shell earning its keep: a picture is easy to eyeball, but clipping and colour
/// casts show up in the histogram first.
struct Histogram: Equatable {
    var red = [Int](repeating: 0, count: 256)
    var green = [Int](repeating: 0, count: 256)
    var blue = [Int](repeating: 0, count: 256)

    /// Sample the RGBA8 frame into per-channel bins. Capped at ~200k samples so
    /// a full-resolution frame costs the same as a preview — this runs off the
    /// main actor but should never be the reason a drag stutters.
    static func make(from image: CGImage) -> Histogram {
        var hist = Histogram()
        guard let data = image.dataProvider?.data,
              let base = CFDataGetBytePtr(data) else { return hist }

        let width = image.width
        let height = image.height
        let rowStride = image.bytesPerRow
        guard width > 0, height > 0 else { return hist }

        // Stride both axes so the sample count stays bounded regardless of size.
        let target = 200_000
        let step = max(1, Int((Double(width * height) / Double(target)).squareRoot()))

        var y = 0
        while y < height {
            let row = base + y * rowStride
            var x = 0
            while x < width {
                let p = row + x * 4          // R, G, B, skip — matches Renderer's layout.
                hist.red[Int(p[0])] += 1
                hist.green[Int(p[1])] += 1
                hist.blue[Int(p[2])] += 1
                x += step
            }
            y += step
        }
        return hist
    }

    /// The tallest bin across all channels, used to normalise the plot.
    var peak: Int {
        max(red.max() ?? 0, green.max() ?? 0, blue.max() ?? 0, 1)
    }
}

/// Overlaid RGB channels on a dark strip, additive so overlaps read white — the
/// shape every photo editor draws. Recomputes only when a new frame lands.
struct HistogramView: View {
    let image: CGImage?
    let renderID: UInt

    @State private var histogram = Histogram()
    private static let performanceLog = OSLog(
        subsystem: "codes.zms.banksia",
        category: .pointsOfInterest
    )

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.black.opacity(0.35))

            if image == nil {
                Text("no frame")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Canvas { context, size in
                    draw(.red, values: histogram.red, in: context, size: size)
                    draw(.green, values: histogram.green, in: context, size: size)
                    draw(.blue, values: histogram.blue, in: context, size: size)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 4)
                .drawingGroup()
            }
        }
        .frame(height: 96)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(.white.opacity(0.06))
        )
        .task(id: renderID) {
            guard let image else { return }
            // Off the main actor: the sample loop shouldn't touch UI cadence.
            let signpostID = OSSignpostID(log: Self.performanceLog)
            os_signpost(
                .begin,
                log: Self.performanceLog,
                name: "Histogram analysis",
                signpostID: signpostID
            )
            let next = await Task.detached(priority: .utility) {
                Histogram.make(from: image)
            }.value
            os_signpost(
                .end,
                log: Self.performanceLog,
                name: "Histogram analysis",
                signpostID: signpostID
            )
            withAnimation(.easeOut(duration: 0.12)) { histogram = next }
        }
    }

    private func draw(
        _ color: Color,
        values: [Int],
        in context: GraphicsContext,
        size: CGSize
    ) {
        let peak = Double(histogram.peak)
        let bins = values.count
        let step = size.width / CGFloat(bins - 1)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        for (i, count) in values.enumerated() {
            // sqrt keeps faint shadow/highlight detail visible next to a spike.
            let norm = (Double(count) / peak).squareRoot()
            let x = CGFloat(i) * step
            let y = size.height * (1 - CGFloat(norm))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()

        var layer = context
        layer.blendMode = .screen
        layer.fill(path, with: .color(color.opacity(0.55)))
        layer.stroke(path, with: .color(color.opacity(0.9)), lineWidth: 1)
    }
}
