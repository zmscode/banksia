import AppKit
import SwiftUI

/// Forces the enclosing NSScrollView to thin overlay scrollers that appear only
/// while scrolling — regardless of the "Show scroll bars" setting or a mouse
/// being attached, which otherwise forces wide, persistent legacy scrollers.
/// Place it as a background of the scroll content so its superview chain reaches
/// the scroll view.
struct OverlayScrollers: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        apply(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func apply(from view: NSView, attempt: Int = 0) {
        DispatchQueue.main.async {
            var parent = view.superview
            while let candidate = parent, !(candidate is NSScrollView) {
                parent = candidate.superview
            }
            if let scroll = parent as? NSScrollView {
                scroll.scrollerStyle = .overlay
                scroll.verticalScroller?.controlSize = .mini
            } else if attempt < 12 {
                apply(from: view, attempt: attempt + 1)
            }
        }
    }
}

/// Fades a scroll view's top and/or bottom edge, but only on the side where
/// content is actually clipped — so the first and last cards are fully visible
/// (unfaded) when you scroll to them.
struct ScrollEdgeFade: ViewModifier {
    @State private var fadeTop = false
    @State private var fadeBottom = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Edges.self) { geo in
                let maxOffset = geo.contentSize.height - geo.containerSize.height
                let scrollable = maxOffset > 1
                let y = geo.contentOffset.y
                return Edges(top: scrollable && y > 1,
                             bottom: scrollable && y < maxOffset - 1)
            } action: { _, edges in
                fadeTop = edges.top
                fadeBottom = edges.bottom
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: fadeTop ? .clear : .black, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: fadeBottom ? .clear : .black, location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }

    private struct Edges: Equatable {
        var top: Bool
        var bottom: Bool
    }
}

extension View {
    func scrollEdgeFade() -> some View { modifier(ScrollEdgeFade()) }
}
