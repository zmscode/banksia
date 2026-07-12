import AppKit
import SwiftUI

/// Mouse/trackpad interaction for the viewer, in AppKit because SwiftUI has no
/// scroll-wheel gesture. Reports intent up; the SwiftUI view owns scale/offset.
/// Not registered for dragging types, so file drops fall through to the
/// SwiftUI drop target beneath it.
///
/// In split mode left-drag moves the before/after seam instead of panning, but
/// middle-drag still pans and the wheel still zooms — so you can reposition
/// while comparing.
struct ViewerInteraction: NSViewRepresentable {
    var splitActive: Bool = false
    var onScroll: (_ deltaY: CGFloat, _ location: CGPoint) -> Void
    var onPan: (_ translation: CGSize) -> Void
    var onPanEnded: () -> Void
    var onMagnify: (_ magnification: CGFloat) -> Void
    var onMagnifyEnded: () -> Void
    var onDoubleClick: () -> Void
    var onSplit: (_ fraction: CGFloat) -> Void = { _ in }

    func makeNSView(context: Context) -> Catcher {
        let view = Catcher()
        view.host = self
        return view
    }

    func updateNSView(_ nsView: Catcher, context: Context) {
        nsView.host = self
    }

    final class Catcher: NSView {
        var host: ViewerInteraction?
        private var dragOrigin: NSPoint?

        // Top-left origin, y down — matches SwiftUI's coordinate space.
        override var isFlipped: Bool { true }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        private var splitting: Bool { host?.splitActive == true }

        override func scrollWheel(with event: NSEvent) {
            let location = convert(event.locationInWindow, from: nil)
            let delta = event.hasPreciseScrollingDeltas
                ? event.scrollingDeltaY
                : event.deltaY * 40
            host?.onScroll(delta, location)
        }

        override func mouseDown(with event: NSEvent) {
            if splitting {
                reportSplit(event)
                return
            }
            if event.clickCount == 2 {
                host?.onDoubleClick()
                dragOrigin = nil
                return
            }
            dragOrigin = convert(event.locationInWindow, from: nil)
        }

        override func mouseDragged(with event: NSEvent) {
            if splitting {
                reportSplit(event)
                return
            }
            guard let origin = dragOrigin else { return }
            let p = convert(event.locationInWindow, from: nil)
            host?.onPan(CGSize(width: p.x - origin.x, height: p.y - origin.y))
        }

        override func mouseUp(with event: NSEvent) {
            if !splitting, dragOrigin != nil { host?.onPanEnded() }
            dragOrigin = nil
        }

        // Middle button (the scroll wheel pressed) always pans, split or not —
        // the CAD/3D idiom, and the way to pan while the seam owns left-drag.
        override func otherMouseDown(with event: NSEvent) {
            dragOrigin = convert(event.locationInWindow, from: nil)
        }

        override func otherMouseDragged(with event: NSEvent) {
            guard let origin = dragOrigin else { return }
            let p = convert(event.locationInWindow, from: nil)
            host?.onPan(CGSize(width: p.x - origin.x, height: p.y - origin.y))
        }

        override func otherMouseUp(with event: NSEvent) {
            if dragOrigin != nil { host?.onPanEnded() }
            dragOrigin = nil
        }

        override func magnify(with event: NSEvent) {
            if event.phase == .ended || event.phase == .cancelled {
                host?.onMagnifyEnded()
            } else {
                host?.onMagnify(event.magnification)
            }
        }

        private func reportSplit(_ event: NSEvent) {
            let p = convert(event.locationInWindow, from: nil)
            host?.onSplit(max(0, min(1, p.x / max(bounds.width, 1))))
        }
    }
}
