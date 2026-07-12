import AppKit
import SwiftUI

/// A thin draggable gutter between a side panel and the viewer. `sign` is +1
/// when dragging right should widen the bound panel (left panel) and -1 when it
/// should narrow it (right panel).
struct PanelDivider: View {
    @Binding var width: CGFloat
    let range: ClosedRange<CGFloat>
    let sign: CGFloat

    @State private var start: CGFloat?
    @State private var hovering = false

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10)
            .overlay(
                Capsule()
                    .fill(.white.opacity(hovering ? 0.35 : 0.10))
                    .frame(width: hovering ? 3 : 1)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 14)
            )
            .contentShape(Rectangle())
            .onHover { inside in
                hovering = inside
                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let base = start ?? width
                        if start == nil { start = width }
                        width = min(max(base + sign * value.translation.width,
                                        range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in start = nil }
            )
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
