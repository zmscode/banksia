import CoreGraphics
import SwiftUI

/// The viewer. The image letterboxes via `scaledToFit` (no manual measuring, so
/// it can't blow up); zoom/pan live in a shared `ViewerState` so the Navigator
/// can mirror them. Scroll zooms toward the pointer, drag pans at any zoom, and
/// a split handle wipes between the neutral develop and the current one.
struct PreviewCanvas: View {
    let controller: DevelopController
    let viewer: ViewerState
    var onOpen: () -> Void

    @State private var settledScale: CGFloat = 1
    @State private var settledOffset: CGSize = .zero
    @State private var splitEnabled = false
    @State private var splitFraction: CGFloat = 0.5
    @State private var isDropTargeted = false
    @State private var showClipping = false
    @State private var clipOverlay: CGImage?
    @State private var hoverPoint: CGPoint?
    @State private var commandHeld = false
    @State private var cropEnabled = false
    @State private var cropRect = CGRect(x: 0.12, y: 0.12, width: 0.76, height: 0.76)
    @State private var cropAngle: Double = 0

    private static let rawExtensions: Set<String> = ["dng", "cr2", "cr3"]
    // 1 = fit; below 1 pulls back for breathing room, above 1 pixel-peeps.
    private static let minScale: CGFloat = 0.33
    private static let maxScale: CGFloat = 10

    var body: some View {
        ZStack {
            Color(white: 0.10)
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(sizeReader)
        .background(zoomShortcuts)
        .contentShape(Rectangle())
        .overlay(alignment: .topLeading) { renderingPill }
        .overlay { loupeOverlay }
        .overlay(alignment: .bottom) { toolbar }
        .dropDestination(for: URL.self) { urls, _ in
            openDropped(urls)
        } isTargeted: { isDropTargeted = $0 }
        .onChange(of: controller.fileName) { resetView() }
        .onChange(of: controller.pixelWidth) {
            viewer.imageSize = CGSize(width: controller.pixelWidth, height: controller.pixelHeight)
        }
        .onChange(of: viewer.viewSize) { snapFitIfNeeded() }
        .onChange(of: viewer.insetLeading) { snapFitIfNeeded() }
        .task(id: ClipKey(on: showClipping, render: controller.renderID)) {
            guard showClipping, let image = controller.image else {
                clipOverlay = nil
                return
            }
            clipOverlay = await Task.detached(priority: .utility) {
                makeClippingOverlay(from: image)
            }.value
        }
    }

    private struct ClipKey: Hashable {
        let on: Bool
        let render: UInt
    }

    private var sizeReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { viewer.viewSize = geo.size }
                .onChange(of: geo.size) { viewer.viewSize = geo.size }
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if controller.linearPreview != nil || controller.displayImage != nil {
            imageStage(controller.displayImage)
        } else if controller.fileName != nil, controller.isRendering {
            loadingState
        } else if controller.fileName != nil {
            errorState
        } else {
            emptyState
        }
    }

    private func imageStage(_ image: CGImage?) -> some View {
        ZStack {
            primaryTransformed(fallback: image)
            if splitEnabled, let before = controller.baselineImage {
                transformed(before)
                    .mask(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle().frame(
                                width: geo.size.width * splitFraction,
                                height: geo.size.height
                            )
                        }
                    }
            }
            if showClipping, let overlay = clipOverlay {
                transformed(overlay).allowsHitTesting(false)
            }
            if splitEnabled, controller.baselineImage != nil {
                splitControls
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .overlay { if !cropEnabled { interaction } }
        .overlay { if cropEnabled { CropOverlay(rect: $cropRect, angle: $cropAngle) { cropEnabled = false } } }
        .shadow(color: .black.opacity(0.5), radius: 18, y: 6)
        .animation(.interactiveSpring(response: 0.26, dampingFraction: 0.85), value: viewer.scale)
    }

    @ViewBuilder
    private func primaryTransformed(fallback: CGImage?) -> some View {
        if controller.useCPUFallback, let fallback {
            transformedCPU(fallback)
        } else if !controller.showBaseline, let preview = controller.linearPreview {
            transformedLinear(preview)
        } else if controller.showBaseline, let fallback {
            transformed(fallback)
        } else if controller.isRendering {
            loadingState
        }
    }

    private func transformedLinear(_ preview: LinearPreview) -> some View {
        let fitted = viewer.fittedSize()
        return MetalLinearImageSurface(
            preview: preview,
            previewGeneration: controller.linearPreviewGeneration,
            exposureEV: controller.develop.ev,
            contrast: controller.develop.contrast,
            nearestSampling: viewer.scale > 3,
            onTiming: controller.recordMetalTiming,
            onFailure: controller.handleMetalFailure
        )
        .frame(width: fitted.width, height: fitted.height)
        .scaleEffect(viewer.scale)
        .offset(viewer.offset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func transformed(_ cg: CGImage) -> some View {
        // Size to the inset-aware fitted size (not scaledToFit on the whole
        // frame), so Fit lands in the clear region between the panels.
        let fitted = viewer.fittedSize()
        return MetalImageSurface(
            image: cg,
            nearestSampling: viewer.scale > 3
        )
            .frame(width: fitted.width, height: fitted.height)
            .scaleEffect(viewer.scale)
            .offset(viewer.offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func transformedCPU(_ cg: CGImage) -> some View {
        let fitted = viewer.fittedSize()
        return Image(decorative: cg, scale: 1, orientation: .up)
            .resizable()
            .interpolation(viewer.scale > 3 ? .none : .high)
            .frame(width: fitted.width, height: fitted.height)
            .scaleEffect(viewer.scale)
            .offset(viewer.offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var interaction: some View {
        ViewerInteraction(
            splitActive: splitEnabled,
            onScroll: { delta, location in zoom(by: exp(delta * 0.002), toward: location) },
            onPan: { translation in panBy(translation) },
            onPanEnded: { settledOffset = viewer.offset },
            onMagnify: { magnification in zoom(by: 1 + magnification, toward: nil) },
            onMagnifyEnded: {
                settledScale = viewer.scale
                settledOffset = viewer.offset
            },
            onDoubleClick: { toggleZoom() },
            onSplit: { fraction in splitFraction = min(max(fraction, 0.04), 0.96) },
            onPointer: { location, command in
                hoverPoint = location
                commandHeld = command
            }
        )
    }

    // MARK: Pixel loupe (hold ⌘)

    @ViewBuilder
    private var loupeOverlay: some View {
        if commandHeld, let point = hoverPoint, let image = controller.displayImage,
           let coord = imageCoord(at: point, image: image) {
            loupe(image: image, at: point, coord: coord)
        }
    }

    private func loupe(image: CGImage, at point: CGPoint, coord: CGPoint) -> some View {
        let size: CGFloat = 132
        let region = 18
        let px = Int(coord.x)
        let py = Int(coord.y)
        let rgb = pixelRGB(image, px, py)
        let cropX = max(0, min(image.width - region, px - region / 2))
        let cropY = max(0, min(image.height - region, py - region / 2))
        let crop = image.cropping(to: CGRect(x: cropX, y: cropY, width: region, height: region))
        return VStack(spacing: 5) {
            ZStack {
                if let crop {
                    Image(decorative: crop, scale: 1).resizable().interpolation(.none)
                }
                Rectangle().fill(.white.opacity(0.6)).frame(width: 1)
                Rectangle().fill(.white.opacity(0.6)).frame(height: 1)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 6)
            if let rgb {
                Text("R \(rgb.0)   G \(rgb.1)   B \(rgb.2)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: Capsule())
            }
        }
        .position(
            x: min(max(point.x, size / 2), max(size / 2, viewer.viewSize.width - size / 2)),
            y: max(point.y - size / 2 - 34, size / 2 + 8)
        )
        .allowsHitTesting(false)
    }

    /// Map a viewer point to the pixel under it, or nil if off the image.
    private func imageCoord(at point: CGPoint, image: CGImage) -> CGPoint? {
        let size = viewer.viewSize
        guard size.width > 0, viewer.imageSize.width > 0 else { return nil }
        let fitted = viewer.fittedSize()
        let displayWidth = fitted.width * viewer.scale
        let displayHeight = fitted.height * viewer.scale
        let u = 0.5 + (point.x - (size.width / 2 + viewer.offset.width)) / displayWidth
        let v = 0.5 + (point.y - (size.height / 2 + viewer.offset.height)) / displayHeight
        guard u >= 0, u <= 1, v >= 0, v <= 1 else { return nil }
        return CGPoint(x: u * CGFloat(image.width), y: v * CGFloat(image.height))
    }

    private func pixelRGB(_ image: CGImage, _ x: Int, _ y: Int) -> (Int, Int, Int)? {
        guard x >= 0, y >= 0, x < image.width, y < image.height,
              let data = image.dataProvider?.data,
              let src = CFDataGetBytePtr(data) else { return nil }
        let p = y * image.bytesPerRow + x * 4
        return (Int(src[p]), Int(src[p + 1]), Int(src[p + 2]))
    }

    // MARK: Split

    private var splitControls: some View {
        GeometryReader { geo in
            let x = geo.size.width * splitFraction
            // Seam dragging is handled by the interaction layer (left-drag);
            // these are just the visuals.
            ZStack(alignment: .topLeading) {
                Rectangle().fill(.white.opacity(0.85))
                    .frame(width: 1.5, height: geo.size.height)
                    .position(x: x, y: geo.size.height / 2)
                Circle().fill(.white).frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.black)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 4)
                    .position(x: x, y: geo.size.height / 2)
                splitLabel("BEFORE").position(x: 48, y: 22)
                splitLabel("AFTER").position(x: geo.size.width - 42, y: 22)
            }
        }
    }

    private func splitLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold)).kerning(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.black.opacity(0.4), in: Capsule())
    }

    // MARK: States

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(Theme.textSecondary)
            Text("Drop a RAW file to develop")
                .font(.title3.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            Text("DNG, CR2, or CR3 — or press ⌘O")
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
            Button(action: onOpen) {
                Label("Open…", systemImage: "folder")
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(52)
        .background(dropOutline)
        .scaleEffect(isDropTargeted ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDropTargeted)
    }

    private var dropOutline: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(
                isDropTargeted ? Theme.accent : Color.white.opacity(0.12),
                style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: [9, 7])
            )
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Developing \(controller.fileName ?? "")…")
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
        }
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.orange)
            Text("Couldn't open this file")
                .font(.title3.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
            Text(controller.statusText)
                .font(.callout.monospaced())
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .frame(maxWidth: 440)
            Button(action: onOpen) { Label("Open another…", systemImage: "folder") }
                .buttonStyle(.bordered)
                .padding(.top, 2)
        }
        .padding(36)
    }

    // MARK: Floating glass

    @ViewBuilder
    private var renderingPill: some View {
        if controller.isRendering, controller.displayImage != nil {
            HStack(spacing: 7) {
                ProgressView().controlSize(.small)
                Text("Rendering").font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .glassCard(cornerRadius: 20)
            .padding(12)
        }
    }

    @ViewBuilder
    private var toolbar: some View {
        if controller.displayImage != nil {
            HStack(spacing: 10) {
                readout
                divider
                zoomControls
                divider
                compareButton
                splitButton
                clippingButton
                cropButton
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .glassCard(cornerRadius: 22)
            .padding(.bottom, 14)
        }
    }

    private var divider: some View {
        Divider().frame(height: 16).overlay(Theme.hairline)
    }

    private var readout: some View {
        HStack(spacing: 8) {
            Text(controller.fileName ?? "—")
                .foregroundStyle(Theme.textPrimary).lineLimit(1).fontWeight(.medium)
            if controller.pixelWidth > 0 {
                Text("\(controller.pixelWidth)×\(controller.pixelHeight)")
                    .foregroundStyle(Theme.textSecondary)
            }
            if let ms = controller.lastRenderMS {
                Text("\(Int(ms.rounded())) ms").foregroundStyle(Theme.textSecondary)
            }
        }
        .font(.caption.monospacedDigit())
    }

    private var zoomControls: some View {
        HStack(spacing: 6) {
            Button { setScale(viewer.scale / 1.5) } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            Text(zoomLabel)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 42)
            Button { setScale(viewer.scale * 1.5) } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            Button { toggleZoom() } label: {
                Image(systemName: viewer.isFit
                    ? "arrow.up.left.and.arrow.down.right"
                    : "arrow.down.right.and.arrow.up.left")
            }
            .help(viewer.isFit ? "Zoom in" : "Fit")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Theme.textPrimary)
        .labelStyle(.iconOnly)
    }

    private var compareButton: some View {
        // Press-and-hold to flash the neutral develop — the standard photo-tool
        // gesture, wired through a zero-distance drag so down/up bracket the hold.
        Image(systemName: "rectangle.righthalf.filled")
            .font(.caption)
            .frame(width: 24, height: 20)
            .contentShape(Rectangle())
            .foregroundStyle(controller.showBaseline ? Theme.accent : Theme.textPrimary)
            .help("Hold to compare with the neutral develop")
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !controller.showBaseline { controller.showBaseline = true }
                    }
                    .onEnded { _ in controller.showBaseline = false }
            )
    }

    private var splitButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { splitEnabled.toggle() }
        } label: {
            Image(systemName: "rectangle.split.2x1")
                .font(.caption)
                .frame(width: 24, height: 20)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(splitEnabled ? Theme.accent : Theme.textPrimary)
        .disabled(controller.baselineImage == nil)
        .help("Before / after split")
    }

    private var clippingButton: some View {
        Button { showClipping.toggle() } label: {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .frame(width: 24, height: 20)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(showClipping ? Theme.accent : Theme.textPrimary)
        .help("Clipping warnings — highlights red, shadows blue")
    }

    private var cropButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { cropEnabled.toggle() }
        } label: {
            Image(systemName: "crop").font(.caption).frame(width: 24, height: 20)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(cropEnabled ? Theme.accent : Theme.textPrimary)
        .help("Crop & straighten — mock, not wired to the engine")
    }

    /// Invisible buttons that register the zoom keyboard shortcuts on the window.
    private var zoomShortcuts: some View {
        ZStack {
            Button("") { setScale(viewer.scale * 1.5) }
                .keyboardShortcut("=", modifiers: .command)
            Button("") { setScale(viewer.scale / 1.5) }
                .keyboardShortcut("-", modifiers: .command)
            Button("") { fitZoom() }
                .keyboardShortcut("0", modifiers: .command)
            Button("") { actualPixels() }
                .keyboardShortcut("1", modifiers: .command)
        }
        .opacity(0)
    }

    // MARK: Zoom & pan

    private var zoomLabel: String {
        abs(viewer.scale - 1) < 0.01 ? "Fit" : String(format: "%.1f×", viewer.scale)
    }

    /// Multiply the zoom by `factor`, keeping the point under `location` fixed
    /// (pointer for scroll, centre for pinch/buttons).
    private func zoom(by factor: CGFloat, toward location: CGPoint?) {
        let old = viewer.scale
        let newScale = clampScale(old * factor)
        guard newScale != old, viewer.viewSize.width > 0 else { return }
        let centerX = viewer.viewSize.width / 2
        let centerY = viewer.viewSize.height / 2
        let focalX = location?.x ?? centerX
        let focalY = location?.y ?? centerY
        let k = newScale / old
        let inv = 1 - k
        let off = viewer.offset
        let offsetX: CGFloat = (focalX - centerX) * inv + off.width * k
        let offsetY: CGFloat = (focalY - centerY) * inv + off.height * k
        viewer.scale = newScale
        let clamped = clampOffset(CGSize(width: offsetX, height: offsetY))
        viewer.offset = clamped
        settledScale = newScale
        settledOffset = clamped
    }

    private func panBy(_ translation: CGSize) {
        viewer.offset = clampOffset(CGSize(
            width: settledOffset.width + translation.width,
            height: settledOffset.height + translation.height
        ))
    }

    private func setScale(_ target: CGFloat) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewer.scale = clampScale(target)
            viewer.offset = clampOffset(viewer.offset)
            settledScale = viewer.scale
            settledOffset = viewer.offset
        }
    }

    private func toggleZoom() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            viewer.scale = viewer.isFit ? 2 : 1
            viewer.offset = clampOffset(viewer.fitOffset)
            settledScale = viewer.scale
            settledOffset = viewer.offset
        }
    }

    private func fitZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewer.scale = 1
            viewer.offset = viewer.fitOffset
            settledScale = 1
            settledOffset = viewer.fitOffset
        }
    }

    /// Keep Fit centred in the clear region as the window or panels change.
    private func snapFitIfNeeded() {
        guard viewer.isFit else { return }
        viewer.offset = viewer.fitOffset
        settledOffset = viewer.fitOffset
    }

    /// Zoom to true 1:1 — one image pixel per screen point.
    private func actualPixels() {
        let fitted = viewer.fittedSize()
        guard fitted.width > 0 else { return }
        setScale(viewer.imageSize.width / fitted.width)
    }

    private func resetView() {
        viewer.reset()
        settledScale = 1
        settledOffset = viewer.fitOffset
        splitEnabled = false
        splitFraction = 0.5
    }

    private func clampScale(_ value: CGFloat) -> CGFloat {
        min(max(value, Self.minScale), Self.maxScale)
    }

    /// Clamp pan so a zoomed image can't be dragged past its edges, while still
    /// allowing free repositioning up to half a viewport at fit.
    private func clampOffset(_ value: CGSize) -> CGSize {
        let size = viewer.viewSize
        guard size.width > 0 else { return value }
        let fitted = viewer.fittedSize()
        let scale = viewer.scale
        let overflowX: CGFloat = (fitted.width * scale - size.width) / 2
        let overflowY: CGFloat = (fitted.height * scale - size.height) / 2
        let maxX: CGFloat = max(size.width * 0.5, overflowX)
        let maxY: CGFloat = max(size.height * 0.5, overflowY)
        let clampedX: CGFloat = min(max(value.width, -maxX), maxX)
        let clampedY: CGFloat = min(max(value.height, -maxY), maxY)
        return CGSize(width: clampedX, height: clampedY)
    }

    private func openDropped(_ urls: [URL]) -> Bool {
        guard let url = urls.first(where: {
            Self.rawExtensions.contains($0.pathExtension.lowercased())
        }) else { return false }
        controller.open(url: url)
        return true
    }
}
