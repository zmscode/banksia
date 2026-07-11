import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var controller = DevelopController()
    @State private var importing = false

    private static let rawTypes = ["dng", "cr2", "cr3"].compactMap {
        UTType(filenameExtension: $0, conformingTo: .image)
    }

    var body: some View {
        VStack(spacing: 0) {
            preview
            Divider()
            controls
                .padding()
        }
        .toolbar {
            ToolbarItem {
                Button("Open…") { importing = true }
                    .keyboardShortcut("o")
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: Self.rawTypes
        ) { result in
            if case .success(let url) = result {
                controller.open(url: url)
            }
        }
        .frame(minWidth: 800, minHeight: 560)
        .onOpenURL { url in
            controller.open(url: url)
        }
        .onAppear {
            // Dev loop: `Banksia <shot.raw>` skips the picker entirely.
            if let path = CommandLine.arguments.dropFirst().first {
                controller.open(url: URL(fileURLWithPath: path))
            }
        }
    }

    private var preview: some View {
        ZStack {
            Color(white: 0.1)
            if let image = controller.image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(8)
            } else {
                Text(controller.statusText)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controls: some View {
        Grid(alignment: .leading, verticalSpacing: 6) {
            sliderRow("EV", value: $controller.develop.ev, range: -3...3)
            sliderRow("Temp", value: $controller.develop.temperature, range: -1...1)
            sliderRow("Tint", value: $controller.develop.tint, range: -0.5...0.5)
            sliderRow("Contrast", value: $controller.develop.contrast, range: 0...1)
        }
    }

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        GridRow {
            Text(label)
                .gridColumnAlignment(.trailing)
            Slider(value: value, in: range) { editing in
                controller.isDragging = editing
                if !editing { controller.dragEnded() }
            }
            .onChange(of: value.wrappedValue) {
                controller.parameterChanged()
            }
            Text(String(format: "%+.2f", value.wrappedValue))
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}
