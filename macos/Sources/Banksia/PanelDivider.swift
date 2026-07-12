import SwiftUI

/// A thin draggable gutter between a side panel and the viewer. `sign` is +1
/// when dragging right should widen the bound panel (left panel) and -1 when it
/// should narrow it (right panel).
///
/// The drag is measured in the `.global` space on purpose: resizing moves the
/// divider itself, so a `.local` translation would feed its own movement back
/// into the width and oscillate. Global translation is the raw mouse delta.
struct PanelDivider: View {
    @Binding var width: CGFloat
    let range: ClosedRange<CGFloat>
    let sign: CGFloat

    @State private var start: CGFloat?
    @State private var hovering = false

    private var active: Bool { hovering || start != nil }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10)
            .overlay(
                Capsule()
                    .fill(.white.opacity(active ? 0.35 : 0.10))
                    .frame(width: active ? 3 : 1)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 14)
            )
            .contentShape(Rectangle())
            .pointerStyle(.columnResize)
            .onHover { hovering = $0 }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        let base = start ?? width
                        if start == nil { start = width }
                        let next = base + sign * value.translation.width
                        width = min(max(next, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in start = nil }
            )
            .animation(.easeOut(duration: 0.12), value: active)
    }
}
