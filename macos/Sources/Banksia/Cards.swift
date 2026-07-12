import SwiftUI

/// A titled Liquid Glass tool card — the shared surface for both side panels,
/// so the left and right columns read as one system.
struct ToolCard<Content: View>: View {
    let title: String
    let systemImage: String
    let mock: Bool
    let trailing: AnyView?
    @ViewBuilder let content: () -> Content

    init(
        _ title: String, systemImage: String, mock: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.mock = mock
        self.trailing = nil
        self.content = content
    }

    init<Trailing: View>(
        _ title: String, systemImage: String, mock: Bool = false,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.mock = mock
        self.trailing = AnyView(trailing())
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 14)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                if mock { mockBadge }
                Spacer()
                trailing
            }
            content()
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .opacity(mock ? 0.9 : 1)
    }

    /// Marks a card whose controls aren't connected to the engine yet.
    private var mockBadge: some View {
        Image(systemName: "hammer.fill")
            .font(.system(size: 8))
            .foregroundStyle(Theme.textTertiary)
            .help("Mock-up — these controls aren't wired to the engine yet")
    }
}

/// A borderless icon button for card headers (reset, copy).
func cardIconButton(
    _ systemImage: String, help: String, action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Image(systemName: systemImage).font(.system(size: 11))
    }
    .buttonStyle(.plain)
    .foregroundStyle(Theme.textSecondary)
    .help(help)
}

/// A label/value row for the Info card.
func infoRow(_ label: String, _ value: String) -> some View {
    HStack {
        Text(label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        Spacer()
        Text(value)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Theme.textPrimary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}
