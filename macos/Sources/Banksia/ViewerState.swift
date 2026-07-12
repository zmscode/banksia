import SwiftUI

/// Shared viewer transform: the viewer owns it (writes scale/offset), the
/// Navigator reads it to outline the visible region. `scale` is a multiplier
/// over the fit size; 1 = the whole frame visible.
@MainActor
@Observable
final class ViewerState {
    var scale: CGFloat = 1
    var offset: CGSize = .zero
    var viewSize: CGSize = .zero
    var imageSize: CGSize = .zero

    var isZoomed: Bool { scale > 1.01 }

    func reset() {
        scale = 1
        offset = .zero
    }

    /// The fit-scaled image size inside the current viewport.
    func fittedSize() -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0,
              viewSize.width > 0, viewSize.height > 0 else { return viewSize }
        let s = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        return CGSize(width: imageSize.width * s, height: imageSize.height * s)
    }

    /// Visible region of the image in normalized [0,1] coordinates, or nil when
    /// the whole frame is on screen (nothing to outline).
    var visibleRect: CGRect? {
        guard isZoomed, viewSize.width > 0, imageSize.width > 0 else { return nil }
        let fitted = fittedSize()
        let displayWidth = fitted.width * scale
        let displayHeight = fitted.height * scale
        let left = 0.5 - (viewSize.width / 2 + offset.width) / displayWidth
        let right = 0.5 + (viewSize.width / 2 - offset.width) / displayWidth
        let top = 0.5 - (viewSize.height / 2 + offset.height) / displayHeight
        let bottom = 0.5 + (viewSize.height / 2 - offset.height) / displayHeight
        let x = max(0, left)
        let y = max(0, top)
        let width = min(1, right) - x
        let height = min(1, bottom) - y
        guard width > 0, height > 0 else { return nil }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
