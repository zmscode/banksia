import SwiftUI

/// Functionless preview panels: the UI for develop/culling features the engine
/// doesn't expose yet. Each card carries the mock badge; the controls move and
/// feel real but change nothing until the corresponding op or catalog lands.

struct LightMock: View {
    var body: some View {
        ToolCard("Light", systemImage: "circle.lefthalf.filled", mock: true) {
            MockSlider("Highlights", range: -1...1)
            MockSlider("Shadows", range: -1...1)
            MockSlider("Whites", range: -1...1)
            MockSlider("Blacks", range: -1...1)
        }
    }
}

struct DetailMock: View {
    var body: some View {
        ToolCard("Detail", systemImage: "wand.and.rays", mock: true) {
            MockSlider("Sharpening", range: 0...1)
            MockSlider("Noise Reduction", range: 0...1)
        }
    }
}

/// A slider that looks like the real ones but holds its own dead-end value.
struct MockSlider: View {
    let name: String
    let range: ClosedRange<Double>
    @State private var value: Double = 0

    init(_ name: String, range: ClosedRange<Double>) {
        self.name = name
        self.range = range
    }

    var body: some View {
        let bipolar = range.lowerBound < 0
        VStack(spacing: 3) {
            HStack {
                Text(name).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(String(format: bipolar ? "%+.2f" : "%.2f", value)).valueField()
            }
            Slider(value: $value, in: range)
                .controlSize(.small)
                .tint(Theme.accent)
        }
    }
}

/// Star rating, pick/reject flags, and colour labels — culling UI with no
/// catalog behind it, so nothing persists.
struct RatingMock: View {
    @State private var rating = 0
    @State private var flag = 0
    @State private var label = 0

    private let labelColors: [Color] = [.red, .orange, .yellow, .green, .blue]

    var body: some View {
        ToolCard("Rating & Labels", systemImage: "star", mock: true) {
            HStack(spacing: 5) {
                ForEach(1...5, id: \.self) { i in
                    iconButton(i <= rating ? "star.fill" : "star",
                               on: i <= rating) { rating = rating == i ? 0 : i }
                }
                Spacer()
                iconButton("flag.fill", on: flag == 1, tint: .green) { flag = flag == 1 ? 0 : 1 }
                iconButton("flag.slash", on: flag == -1, tint: .red) { flag = flag == -1 ? 0 : -1 }
            }
            HStack(spacing: 7) {
                ForEach(Array(labelColors.enumerated()), id: \.offset) { index, color in
                    Button { label = label == index + 1 ? 0 : index + 1 } label: {
                        Circle().fill(color).frame(width: 15, height: 15)
                            .overlay(
                                Circle().strokeBorder(
                                    .white.opacity(label == index + 1 ? 0.9 : 0.15),
                                    lineWidth: label == index + 1 ? 2 : 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    private func iconButton(
        _ systemImage: String, on: Bool, tint: Color = Theme.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(on ? tint : Theme.textTertiary)
        }
        .buttonStyle(.plain)
    }
}
