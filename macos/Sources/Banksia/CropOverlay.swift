import SwiftUI

/// A functionless crop tool: a draggable crop rectangle with corner handles, a
/// rule-of-thirds grid, dimmed surroundings, and a straighten slider. Marked as
/// a mock — it never touches the render (real crop/straighten is an engine op).
struct CropOverlay: View {
    @Binding var rect: CGRect     // normalized [0,1] within the viewer
    @Binding var angle: Double    // degrees, mock
    var onDone: () -> Void

    @State private var moveStart: CGRect?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let frame = CGRect(x: rect.minX * w, y: rect.minY * h,
                               width: rect.width * w, height: rect.height * h)
            ZStack {
                dimOutside(frame)
                thirds(frame)
                Rectangle()
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .gesture(moveGesture(size: geo.size))
                ForEach(0..<4, id: \.self) { i in
                    corner(i, frame: frame, size: geo.size)
                }
                controls.position(x: w / 2, y: 32)
            }
            .coordinateSpace(name: "crop")
        }
    }

    private func dimOutside(_ frame: CGRect) -> some View {
        Rectangle().fill(.black.opacity(0.5))
            .mask {
                ZStack {
                    Rectangle()
                    Rectangle()
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            }
            .allowsHitTesting(false)
    }

    private func thirds(_ frame: CGRect) -> some View {
        Path { p in
            for i in 1...2 {
                let fx = frame.minX + frame.width * CGFloat(i) / 3
                p.move(to: CGPoint(x: fx, y: frame.minY)); p.addLine(to: CGPoint(x: fx, y: frame.maxY))
                let fy = frame.minY + frame.height * CGFloat(i) / 3
                p.move(to: CGPoint(x: frame.minX, y: fy)); p.addLine(to: CGPoint(x: frame.maxX, y: fy))
            }
        }
        .stroke(.white.opacity(0.3), lineWidth: 0.5)
        .allowsHitTesting(false)
    }

    private func corner(_ i: Int, frame: CGRect, size: CGSize) -> some View {
        Circle().fill(.white)
            .frame(width: 12, height: 12)
            .overlay(Circle().strokeBorder(.black.opacity(0.3), lineWidth: 0.5))
            .position(cornerPoint(i, frame))
            .gesture(
                DragGesture(coordinateSpace: .named("crop"))
                    .onChanged { value in setCorner(i, location: value.location, size: size) }
            )
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 9)).foregroundStyle(.white.opacity(0.55))
                .help("Mock-up — crop isn't wired to the engine yet")
            Image(systemName: "angle").font(.caption2).foregroundStyle(.white)
            Slider(value: $angle, in: -45...45).frame(width: 130).controlSize(.mini).tint(Theme.accent)
            Text("\(Int(angle.rounded()))°")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white).frame(width: 30)
            Button("Done", action: onDone).controlSize(.small)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .glassCard(cornerRadius: 18)
    }

    private func cornerPoint(_ i: Int, _ f: CGRect) -> CGPoint {
        switch i {
        case 0: CGPoint(x: f.minX, y: f.minY)
        case 1: CGPoint(x: f.maxX, y: f.minY)
        case 2: CGPoint(x: f.minX, y: f.maxY)
        default: CGPoint(x: f.maxX, y: f.maxY)
        }
    }

    private func setCorner(_ i: Int, location: CGPoint, size: CGSize) {
        let nx = min(max(location.x / size.width, 0), 1)
        let ny = min(max(location.y / size.height, 0), 1)
        var x0 = rect.minX, y0 = rect.minY, x1 = rect.maxX, y1 = rect.maxY
        switch i {
        case 0: x0 = nx; y0 = ny
        case 1: x1 = nx; y0 = ny
        case 2: x0 = nx; y1 = ny
        default: x1 = nx; y1 = ny
        }
        let m: CGFloat = 0.08
        if x1 - x0 < m { if i == 0 || i == 2 { x0 = x1 - m } else { x1 = x0 + m } }
        if y1 - y0 < m { if i == 0 || i == 1 { y0 = y1 - m } else { y1 = y0 + m } }
        rect = CGRect(x: max(0, x0), y: max(0, y0),
                      width: min(1, x1) - max(0, x0), height: min(1, y1) - max(0, y0))
    }

    private func moveGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = moveStart ?? rect
                if moveStart == nil { moveStart = rect }
                let dx = value.translation.width / size.width
                let dy = value.translation.height / size.height
                let nx = min(max(start.minX + dx, 0), 1 - start.width)
                let ny = min(max(start.minY + dy, 0), 1 - start.height)
                rect = CGRect(x: nx, y: ny, width: start.width, height: start.height)
            }
            .onEnded { _ in moveStart = nil }
    }
}
