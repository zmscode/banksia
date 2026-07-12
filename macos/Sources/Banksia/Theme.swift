import SwiftUI

/// Capture One's layout, Apple's Liquid Glass finish. The structure is a pro
/// RAW tool — viewer plus a stack of tool cards — but every surface is
/// translucent glass floating over a soft backdrop derived from the photograph,
/// so the chrome picks up the image's own colour.
enum Theme {
    /// The base the backdrop falls back to before a frame is loaded.
    static let base = Color(white: 0.10)

    static let field = Color.black.opacity(0.30)
    static let hairline = Color.white.opacity(0.08)

    static let textPrimary = Color(white: 0.92)
    static let textSecondary = Color(white: 0.62)
    static let textTertiary = Color(white: 0.45)

    /// Monochrome highlight for slider fills, selection, and "modified" state —
    /// a light neutral, no hue, so nothing tints blue.
    static let accent = Color(white: 0.78)

    static let card: CGFloat = 13
    static let fieldCorner: CGFloat = 4

    /// Zoom bounds for pixel-peeping: fit-to-window up to 8× actual pixels.
    static let zoomMin: CGFloat = 1
    static let zoomMax: CGFloat = 8
}

extension View {
    /// A Liquid Glass tool card — the per-tool surface of the tools column and
    /// the floating viewer toolbar. Interactive so it reacts to the pointer.
    func glassCard(cornerRadius: CGFloat = Theme.card, tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        // Frosted material over the blurred backdrop reads as Liquid Glass and
        // renders reliably on a real display.
        return self
            .background(.regularMaterial, in: shape)
            .overlay { if let tint { shape.fill(tint.opacity(0.20)) } }
            .overlay(shape.strokeBorder(.white.opacity(0.12)))
            .clipShape(shape)
    }

    /// A recessed numeric readout, like the value fields down the right of every
    /// Capture One slider — dark inset so it reads against the glass.
    func valueField(width: CGFloat = 54) -> some View {
        self
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Theme.textPrimary)
            .frame(width: width, height: 19)
            .background(
                RoundedRectangle(cornerRadius: Theme.fieldCorner)
                    .fill(Theme.field)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.fieldCorner)
                            .strokeBorder(Theme.hairline)
                    )
            )
    }
}
