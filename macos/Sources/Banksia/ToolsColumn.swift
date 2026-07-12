import SwiftUI

/// The right panel: the histogram of what came back, the adjustment tools that
/// drive the recipe, and the engine's live tone curve. Capture One's tool stack,
/// in Liquid Glass.
struct ToolsColumn: View {
    let controller: DevelopController

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                histogram
                whiteBalance
                exposure
                LightMock()
                curve
                DetailMock()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .background(OverlayScrollers())
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeFade()
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
            sliderRow("Temperature", \.temperature, -1...1, domain: .early)
            sliderRow("Tint", \.tint, -0.5...0.5, domain: .early)
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
            sliderRow("Exposure", \.ev, -3...3, domain: .late)
            sliderRow("Contrast", \.contrast, 0...1, domain: .late)
        }
    }

    private var curve: some View {
        ToolCard("Tone Curve", systemImage: "point.topleft.down.to.point.bottomright.curvepath") {
            ToneCurveView(
                ev: controller.develop.ev,
                contrast: controller.develop.contrast,
                temperature: controller.develop.temperature,
                tint: controller.develop.tint
            )
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
        _ range: ClosedRange<Double>,
        domain: DevelopChangeDomain
    ) -> some View {
        let bipolar = range.lowerBound < 0
        let value = controller.develop[keyPath: keyPath]
        let edited = value != 0
        let text = String(format: bipolar ? "%+.2f" : "%.2f", value)
        return VStack(spacing: 3) {
            HStack {
                // Double-click the name to reset just this slider, once it's off
                // zero; brightness (not colour) marks it modified.
                Text(name)
                    .font(.system(size: 11))
                    .foregroundStyle(edited ? Theme.textPrimary : Theme.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        if edited { controller.develop[keyPath: keyPath] = 0 }
                    }
                    .help(edited ? "Double-click to reset \(name)" : "")
                Spacer()
                if edited {
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
                if !editing { controller.dragEnded(domain) }
            }
            .controlSize(.small)
            .tint(Theme.accent)
            .onChange(of: controller.develop[keyPath: keyPath]) {
                controller.parameterChanged(domain)
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
