import SwiftUI

/// The right panel: the active controls — the histogram of what came back, then
/// the adjustment tools that drive the recipe. Capture One's tool stack, in
/// Liquid Glass.
struct ToolsColumn: View {
    let controller: DevelopController

    var body: some View {
        VStack(spacing: 10) {
            histogram
            whiteBalance
            exposure
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var histogram: some View {
        ToolCard("Histogram", systemImage: "waveform.path.ecg") {
            HistogramView(image: controller.image, renderID: controller.renderID)
        }
    }

    private var whiteBalance: some View {
        let edited = controller.develop.temperature != 0 || controller.develop.tint != 0
        return ToolCard("White Balance", systemImage: "thermometer.medium", trailing: {
            resetButton(enabled: edited) {
                controller.develop.temperature = 0
                controller.develop.tint = 0
            }
        }) {
            Text("As shot")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
            sliderRow("Temperature", \.temperature, -1...1)
            sliderRow("Tint", \.tint, -0.5...0.5)
        }
    }

    private var exposure: some View {
        let edited = controller.develop.ev != 0 || controller.develop.contrast != 0
        return ToolCard("Exposure", systemImage: "sun.max", trailing: {
            resetButton(enabled: edited) {
                controller.develop.ev = 0
                controller.develop.contrast = 0
            }
        }) {
            sliderRow("Exposure", \.ev, -3...3)
            sliderRow("Contrast", \.contrast, 0...1)
        }
    }

    // MARK: Building blocks

    private func resetButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.uturn.backward").font(.system(size: 10))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.textSecondary)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .help("Reset")
    }

    private func sliderRow(
        _ name: String,
        _ keyPath: ReferenceWritableKeyPath<DevelopModel, Double>,
        _ range: ClosedRange<Double>
    ) -> some View {
        let bipolar = range.lowerBound < 0
        let value = controller.develop[keyPath: keyPath]
        let text = String(format: bipolar ? "%+.2f" : "%.2f", value)
        return VStack(spacing: 3) {
            HStack {
                Text(name).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                Spacer()
                if value != 0 {
                    Button { controller.develop[keyPath: keyPath] = 0 } label: {
                        Text(text).valueField()
                    }
                    .buttonStyle(.plain)
                    .help("Reset \(name)")
                } else {
                    Text(text).valueField()
                }
            }
            Slider(value: binding(keyPath), in: range) { editing in
                controller.isDragging = editing
                if !editing { controller.dragEnded() }
            }
            .controlSize(.small)
            .tint(Theme.accent)
            .onChange(of: controller.develop[keyPath: keyPath]) {
                controller.parameterChanged()
            }
        }
    }

    private func binding(
        _ keyPath: ReferenceWritableKeyPath<DevelopModel, Double>
    ) -> Binding<Double> {
        Binding(
            get: { controller.develop[keyPath: keyPath] },
            set: { controller.develop[keyPath: keyPath] = $0 }
        )
    }
}
