import CoreImage
import Metal
import XCTest
@testable import Banksia

final class MetalPresentationTests: XCTestCase {
    func testMetalTimingUsesDeterministicTimestamps() {
        let timing = MetalTimingTimestamps(
            submittedAt: 10.010,
            gpuStartedAt: 10.012,
            gpuEndedAt: 10.015,
            presentedAt: 10.025,
            requestedAt: 10.000
        ).timing(
            uploadMS: 1.25,
            encodeMS: 0.75,
            drawableWidth: 2880,
            drawableHeight: 1800
        )
        XCTAssertEqual(timing.queueMS, 2, accuracy: 0.0001)
        XCTAssertEqual(timing.gpuMS, 3, accuracy: 0.0001)
        XCTAssertEqual(timing.presentWaitMS, 10, accuracy: 0.0001)
        XCTAssertEqual(timing.inputToPresentedMS, 25, accuracy: 0.0001)
        XCTAssertEqual(timing.uploadMS, 1.25)
        XCTAssertEqual(timing.encodeMS, 0.75)
    }

    func testDrawableSizingTracksNonRetinaAndRetinaBackingScale() {
        let points = CGSize(width: 1_003, height: 677)
        XCTAssertEqual(
            MetalDrawableSizing.pixels(points: points, backingScale: 1),
            CGSize(width: 1_003, height: 677)
        )
        XCTAssertEqual(
            MetalDrawableSizing.pixels(points: points, backingScale: 2),
            CGSize(width: 2_006, height: 1_354)
        )
    }

    func testMetalTimingSummaryUsesNearestRankPercentiles() throws {
        let samples = (1...20).map { value in
            MetalDevelopTiming(
                uploadMS: 0,
                encodeMS: Double(value) / 10,
                queueMS: Double(value) / 20,
                gpuMS: Double(value) / 40,
                presentWaitMS: Double(value),
                inputToPresentedMS: Double(value),
                drawableWidth: 1,
                drawableHeight: 1
            )
        }
        let summary = try XCTUnwrap(MetalTimingSummary.make(samples: samples))
        XCTAssertEqual(summary.sampleCount, 20)
        XCTAssertEqual(summary.inputToPresentedP50MS, 10)
        XCTAssertEqual(summary.inputToPresentedP95MS, 19)
        XCTAssertEqual(summary.inputToPresentedP99MS, 20)
        XCTAssertEqual(summary.encodeP50MS, 1)
        XCTAssertEqual(summary.gpuP50MS, 0.25)
    }

    func testCoreImagePopulatesMetalTexture() throws {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let commandBuffer = queue.makeCommandBuffer()
        else {
            throw XCTSkip("Metal is unavailable")
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: 4,
            height: 4,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderWrite, .shaderRead]
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            XCTFail("could not allocate validation texture")
            return
        }

        let context = CIContext(mtlCommandQueue: queue)
        let source = CIImage(color: CIColor(red: 1, green: 0, blue: 0, alpha: 1))
            .cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
        context.render(
            source,
            to: texture,
            commandBuffer: commandBuffer,
            bounds: source.extent,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        )
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        XCTAssertEqual(commandBuffer.status, .completed)

        var pixel = [UInt8](repeating: 0, count: 4)
        texture.getBytes(
            &pixel,
            bytesPerRow: 4,
            from: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0
        )
        XCTAssertGreaterThan(pixel[2], 240, "red channel")
        XCTAssertLessThan(pixel[1], 16, "green channel")
        XCTAssertLessThan(pixel[0], 16, "blue channel")
        XCTAssertGreaterThan(pixel[3], 240, "alpha channel")
    }

    func testCompiledLateDevelopHasStableImplementationID() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is unavailable")
        }
        _ = try MetalLateDevelopPipeline(device: device)
        XCTAssertEqual(
            MetalLateDevelopPipeline.implementationID,
            "banksia.metal.late-develop-f32.msl1"
        )
        XCTAssertEqual(MetalLateDevelopPipeline.passCount, 1)
        XCTAssertEqual(MetalLateDevelopPipeline.fusedOperations, [
            "scaling",
            "exposure",
            "tone",
            "working-to-output-matrix",
            "clipping",
            "display-encoding",
        ])
    }

    func testCompiledLateDevelopPresentsDirectTextureKnownVector() throws {
        let pixels = try renderCompiledLateDevelop(
            width: 1,
            height: 1,
            sourcePixels: [0.2, 0.2, 0.2, 1],
            exposureEV: 1,
            contrast: 0.5
        )

        // 0.2 -> 0.4 after exposure, then 0.376 after the contrast curve.
        // The sRGB render target encodes that linear value to about byte 165.
        XCTAssertEqual(pixels[0], 165, accuracy: 3, "blue")
        XCTAssertEqual(pixels[1], 165, accuracy: 3, "green")
        XCTAssertEqual(pixels[2], 165, accuracy: 3, "red")
        XCTAssertEqual(pixels[3], 255, accuracy: 1, "alpha")
    }

    func testCompiledLateDevelopPresentsTopRowFirstTextureUpright() throws {
        let pixels = try renderCompiledLateDevelop(
            width: 1,
            height: 2,
            sourcePixels: [
                1, 0, 0, 1, // engine top row
                0, 0, 1, 1, // engine bottom row
            ],
            exposureEV: 0,
            contrast: 0
        )

        // BGRA output row zero is the drawable's top row.
        XCTAssertGreaterThan(pixels[2], 240, "top row red")
        XCTAssertLessThan(pixels[0], 16, "top row not blue")
        XCTAssertGreaterThan(pixels[4], 240, "bottom row blue")
        XCTAssertLessThan(pixels[6], 16, "bottom row not red")
    }

    func testEveryMetalFailureStageSelectsStrictCPUFallback() {
        for stage in MetalFailureStage.allCases {
            let failure = MetalFailure(stage: stage, message: "injected")
            XCTAssertEqual(failure.fallbackExecution, .strictCPUDisplay, stage.rawValue)
            XCTAssertEqual(
                MetalFailureInjection.injectedStage(value: stage.rawValue),
                stage
            )
        }
        XCTAssertEqual(MetalFailureInjection.injectedStage(value: "1"), .initialization)
        XCTAssertNil(MetalFailureInjection.injectedStage(value: "unknown"))
    }

    @MainActor
    func testEveryMetalFailureStageCompletesStrictCPUFallback() async throws {
        let file = repositoryRoot.appendingPathComponent(
            "tests/corpus/phase2b/canon-r3-black-fabric.dng"
        )
        for stage in MetalFailureStage.allCases {
            let controller = DevelopController()
            controller.open(url: file)
            try await waitUntil(timeoutSeconds: 10) {
                controller.linearPreview != nil
            }
            controller.handleMetalFailure(MetalFailure(
                stage: stage,
                message: "injected integration test"
            ))
            try await waitUntil(timeoutSeconds: 10) {
                controller.useCPUFallback && controller.image != nil
            }
            XCTAssertTrue(controller.useCPUFallback, stage.rawValue)
            XCTAssertNotNil(controller.image, stage.rawValue)
            let firstRenderID = controller.renderID
            controller.develop.ev = Double(MetalFailureStage.allCases.firstIndex(of: stage) ?? 0) * 0.1
            controller.parameterChanged(.late)
            try await waitUntil(timeoutSeconds: 10) {
                controller.renderID > firstRenderID
            }
        }
    }

    @MainActor
    func testControllerRestoresOnlyTheSelectedAssetsDevelopRecipe() async throws {
        let corpus = repositoryRoot.appendingPathComponent(
            "tests/corpus/phase2b",
            isDirectory: true
        )
        let first = corpus.appendingPathComponent("canon-r3-black-fabric.dng")
        let second = corpus.appendingPathComponent("canon-r3-emerald-fabric.dng")
        let firstState = DevelopRecipeState(
            ev: 0.6,
            temperature: -0.2,
            tint: 0.3,
            contrast: 0.45
        )
        let secondState = DevelopRecipeState(
            ev: -0.5,
            temperature: 0.15,
            tint: -0.1,
            contrast: 0.2
        )
        let controller = DevelopController()

        controller.open(url: first)
        try await waitUntil(timeoutSeconds: 10) { controller.linearPreview != nil }
        controller.develop = DevelopModel(state: firstState)
        controller.parameterChanged(.early)

        controller.open(url: second)
        XCTAssertEqual(controller.develop.state, .neutral)
        try await waitUntil(timeoutSeconds: 10) { controller.linearPreview != nil }
        controller.develop = DevelopModel(state: secondState)
        controller.parameterChanged(.late)

        controller.open(url: first)
        XCTAssertEqual(controller.develop.state, firstState)
        try await waitUntil(timeoutSeconds: 10) { controller.linearPreview != nil }

        controller.open(url: second)
        XCTAssertEqual(controller.develop.state, secondState)
        try await waitUntil(timeoutSeconds: 10) { controller.linearPreview != nil }
        XCTAssertEqual(controller.currentURL, second)
    }

    func testRepeatedTextureAllocationAndMemoryPressureReleaseIsBounded() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is unavailable")
        }
        let baseline = device.currentAllocatedSize
        for iteration in 0..<256 {
            autoreleasepool {
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .rgba32Float,
                    width: 257 + iteration % 11,
                    height: 193 + iteration % 7,
                    mipmapped: false
                )
                descriptor.storageMode = .shared
                descriptor.usage = [.shaderRead]
                XCTAssertNotNil(device.makeTexture(descriptor: descriptor))
            }
        }
        let growth = device.currentAllocatedSize > baseline
            ? device.currentAllocatedSize - baseline
            : 0
        XCTAssertLessThan(growth, 64 * 1_024 * 1_024)
    }

    func testAdversarialOddImageMatchesCPUReferenceAndRemainsFinite() throws {
        let width = 17
        let height = 13
        let source = adversarialLinearPixels(width: width, height: height)
        let actualBGRA = try renderCompiledLateDevelop(
            width: width,
            height: height,
            sourcePixels: source,
            exposureEV: 0.75,
            contrast: 0.65
        )
        let actual = bgraToRGBA(actualBGRA)
        let reference = cpuLateDevelop(
            sourcePixels: source,
            exposureEV: 0.75,
            contrast: 0.65
        )
        let metrics = try XCTUnwrap(PerceptualMetrics.compare(
            actualRGBA: actual,
            referenceRGBA: reference
        ))
        XCTAssertTrue(metrics.finiteOutput)
        XCTAssertLessThanOrEqual(metrics.deltaE00Mean, 0.20)
        XCTAssertLessThanOrEqual(metrics.deltaE00P95, 0.60)
        XCTAssertLessThanOrEqual(metrics.deltaE00Maximum, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.ssim, 0.9999)
    }

    func testRGBA16FloatCandidateAgainstRGBA32FloatEvidence() throws {
        let width = 257
        let height = 5
        let source = adversarialLinearPixels(width: width, height: height)
        let output32 = bgraToRGBA(try renderCompiledLateDevelop(
            width: width,
            height: height,
            sourcePixels: source,
            exposureEV: -1.25,
            contrast: 0.4,
            sourceFormat: .rgba32Float
        ))
        let output16 = bgraToRGBA(try renderCompiledLateDevelop(
            width: width,
            height: height,
            sourcePixels: source,
            exposureEV: -1.25,
            contrast: 0.4,
            sourceFormat: .rgba16Float
        ))
        let metrics = try XCTUnwrap(PerceptualMetrics.compare(
            actualRGBA: output16,
            referenceRGBA: output32
        ))
        XCTAssertTrue(metrics.finiteOutput)
        XCTAssertLessThanOrEqual(metrics.deltaE00Mean, 0.10)
        XCTAssertLessThanOrEqual(metrics.deltaE00P95, 0.35)
        XCTAssertLessThanOrEqual(metrics.deltaE00Maximum, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.ssim, 0.9999)
        print(String(format:
            "metal-precision rgba16-vs-rgba32 de_mean=%.4f de_median=%.4f "
                + "de_p95=%.4f de_max=%.4f ssim=%.7f finite=%@",
            metrics.deltaE00Mean,
            metrics.deltaE00Median,
            metrics.deltaE00P95,
            metrics.deltaE00Maximum,
            metrics.ssim,
            metrics.finiteOutput.description
        ))
    }

    func testRepeatedOddResizeRenderLoopCompletesWithoutDeadlock() throws {
        let sourceWidth = 17
        let sourceHeight = 13
        let source = adversarialLinearPixels(width: sourceWidth, height: sourceHeight)
        for iteration in 0..<64 {
            let outputWidth = 19 + (iteration % 11) * 2
            let outputHeight = 15 + (iteration % 7) * 2
            let pixels = try renderCompiledLateDevelop(
                width: sourceWidth,
                height: sourceHeight,
                outputWidth: outputWidth,
                outputHeight: outputHeight,
                sourcePixels: source,
                exposureEV: Double(iteration % 5) * 0.1,
                contrast: Double(iteration % 7) * 0.1,
                nearestSampling: iteration.isMultiple(of: 2)
            )
            XCTAssertEqual(pixels.count, outputWidth * outputHeight * 4)
        }
    }

    func testMandatoryPhase2BCorpusCPUAndMetalConformance() async throws {
        let corpus = repositoryRoot
            .appendingPathComponent("tests/corpus/phase2b", isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(
            at: corpus,
            includingPropertiesForKeys: nil
        )
            .filter { $0.pathExtension.lowercased() == "dng" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        XCTAssertEqual(files.count, 8)

        let renderer = Renderer()
        var aggregateDeltas: [Double] = []
        var minimumSSIM = 1.0
        for (index, file) in files.enumerated() {
            try await renderer.load(path: file.path)
            let pipeline = await renderer.currentPipelineManifest()
            let model = DevelopModel()
            model.ev = 0.5
            model.contrast = 0.35
            let cpuRequest = RenderRequest(
                generation: UInt64(index * 2 + 1),
                recipeJSON: model.recipeJSON,
                edgeMax: 512,
                intent: .compatibility,
                execution: .strictCPUDisplay,
                pipeline: pipeline
            )
            let linearRequest = RenderRequest(
                generation: UInt64(index * 2 + 2),
                recipeJSON: model.recipeJSON,
                edgeMax: 512,
                intent: .compatibility,
                execution: .strictCPULinearWorking,
                pipeline: pipeline
            )
            let cpu = try await renderer.render(request: cpuRequest)
            let linear = try await renderer.renderLinearPreview(request: linearRequest)
            XCTAssertEqual(cpu.image.width, linear.preview.width)
            XCTAssertEqual(cpu.image.height, linear.preview.height)
            let source = linear.preview.rgba32Float.withUnsafeBytes {
                Array($0.bindMemory(to: Float.self))
            }
            let metal = bgraToRGBA(try renderCompiledLateDevelop(
                width: linear.preview.width,
                height: linear.preview.height,
                sourcePixels: source,
                exposureEV: model.ev,
                contrast: model.contrast
            ))
            let reference = try rgbaBytes(cpu.image)
            let metrics = try XCTUnwrap(PerceptualMetrics.compare(
                actualRGBA: metal,
                referenceRGBA: reference
            ))
            print(String(format:
                "metal-conformance file=%@ samples=%d de_mean=%.4f de_median=%.4f "
                    + "de_p95=%.4f de_max=%.4f ssim=%.7f finite=%@",
                file.lastPathComponent,
                metrics.sampleCount,
                metrics.deltaE00Mean,
                metrics.deltaE00Median,
                metrics.deltaE00P95,
                metrics.deltaE00Maximum,
                metrics.ssim,
                metrics.finiteOutput.description
            ))
            aggregateDeltas.append(metrics.deltaE00Mean)
            minimumSSIM = min(minimumSSIM, metrics.ssim)
            XCTAssertTrue(metrics.finiteOutput, file.lastPathComponent)
            XCTAssertLessThanOrEqual(metrics.deltaE00Mean, 0.5, file.lastPathComponent)
            XCTAssertGreaterThanOrEqual(metrics.ssim, 0.995, file.lastPathComponent)
        }
        XCTAssertLessThanOrEqual(aggregateDeltas.reduce(0, +) / 8, 0.5)
        XCTAssertGreaterThanOrEqual(minimumSSIM, 0.995)
    }

    func testLinearLateDevelopMatchesKnownVector() throws {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let commandBuffer = queue.makeCommandBuffer()
        else {
            throw XCTSkip("Metal is unavailable")
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: 1,
            height: 1,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead, .shaderWrite]
        guard let sourceTexture = device.makeTexture(descriptor: descriptor),
              let outputTexture = device.makeTexture(descriptor: descriptor)
        else {
            XCTFail("could not allocate linear validation textures")
            return
        }

        var sourcePixel: [Float] = [0.2, 0.3, 0.4, 1]
        sourceTexture.replace(
            region: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0,
            withBytes: &sourcePixel,
            bytesPerRow: MemoryLayout<Float>.stride * 4
        )

        let linearRec2020 = CGColorSpace(
            name: CGColorSpace.extendedLinearITUR_2020
        )!
        guard let source = CIImage(
            mtlTexture: sourceTexture,
            options: [.colorSpace: linearRec2020]
        ) else {
            XCTFail("could not wrap the linear source texture")
            return
        }
        let developed = MetalLateDevelop.apply(
            to: source,
            exposureEV: 1,
            contrast: 0.5
        )
        let context = CIContext(
            mtlCommandQueue: queue,
            options: [
                .cacheIntermediates: false,
                .workingColorSpace: linearRec2020,
            ]
        )
        context.render(
            developed,
            to: outputTexture,
            commandBuffer: commandBuffer,
            bounds: developed.extent,
            colorSpace: linearRec2020
        )
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        XCTAssertEqual(commandBuffer.status, .completed)

        var outputPixel = [Float](repeating: 0, count: 4)
        outputTexture.getBytes(
            &outputPixel,
            bytesPerRow: MemoryLayout<Float>.stride * 4,
            from: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0
        )

        // Exposure doubles RGB. Contrast then mixes identity with smoothstep:
        // y = (1-c)x + 3cx² - 2cx³, while alpha remains unchanged.
        let expected: [Float] = [0.376, 0.624, 0.848, 1]
        for channel in outputPixel.indices {
            XCTAssertEqual(
                outputPixel[channel],
                expected[channel],
                accuracy: 0.0005,
                "channel \(channel)"
            )
        }
    }

    func testTopRowFirstInputIsFlippedOnceForCoreImage() throws {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let commandBuffer = queue.makeCommandBuffer()
        else {
            throw XCTSkip("Metal is unavailable")
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: 1,
            height: 2,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead, .shaderWrite]
        guard let sourceTexture = device.makeTexture(descriptor: descriptor),
              let outputTexture = device.makeTexture(descriptor: descriptor)
        else {
            XCTFail("could not allocate orientation validation textures")
            return
        }

        // Engine memory order: red is the top row, blue is the bottom row.
        var sourcePixels: [Float] = [
            1, 0, 0, 1,
            0, 0, 1, 1,
        ]
        sourceTexture.replace(
            region: MTLRegionMake2D(0, 0, 1, 2),
            mipmapLevel: 0,
            withBytes: &sourcePixels,
            bytesPerRow: MemoryLayout<Float>.stride * 4
        )

        let linearRec2020 = CGColorSpace(
            name: CGColorSpace.extendedLinearITUR_2020
        )!
        guard let corrected = MetalTextureInput.linearImage(
            texture: sourceTexture,
            colorSpace: linearRec2020
        ) else {
            XCTFail("could not wrap the orientation source texture")
            return
        }
        let context = CIContext(
            mtlCommandQueue: queue,
            options: [.workingColorSpace: linearRec2020]
        )
        context.render(
            corrected,
            to: outputTexture,
            commandBuffer: commandBuffer,
            bounds: corrected.extent,
            colorSpace: linearRec2020
        )
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        XCTAssertEqual(commandBuffer.status, .completed)

        var outputPixels = [Float](repeating: 0, count: 8)
        outputTexture.getBytes(
            &outputPixels,
            bytesPerRow: MemoryLayout<Float>.stride * 4,
            from: MTLRegionMake2D(0, 0, 1, 2),
            mipmapLevel: 0
        )
        // Rendering the corrected Core Image recipe back to a Metal texture
        // swaps the physical rows exactly once. CAMetalLayer then presents the
        // top-row-first engine input upright rather than upside down.
        XCTAssertLessThan(outputPixels[0], 0.01, "first texture row is not red")
        XCTAssertGreaterThan(outputPixels[2], 0.99, "first texture row is blue")
        XCTAssertGreaterThan(outputPixels[4], 0.99, "second texture row is red")
        XCTAssertLessThan(outputPixels[6], 0.01, "second texture row is not blue")
    }


    private func renderCompiledLateDevelop(
        width: Int,
        height: Int,
        outputWidth: Int? = nil,
        outputHeight: Int? = nil,
        sourcePixels: [Float],
        exposureEV: Double,
        contrast: Double,
        sourceFormat: MTLPixelFormat = .rgba32Float,
        nearestSampling: Bool = false
    ) throws -> [UInt8] {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let commandBuffer = queue.makeCommandBuffer()
        else {
            throw XCTSkip("Metal is unavailable")
        }

        let sourceDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: sourceFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        sourceDescriptor.storageMode = .shared
        sourceDescriptor.usage = [.shaderRead]
        let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: outputWidth ?? width,
            height: outputHeight ?? height,
            mipmapped: false
        )
        outputDescriptor.storageMode = .shared
        outputDescriptor.usage = [.renderTarget]
        guard let source = device.makeTexture(descriptor: sourceDescriptor),
              let output = device.makeTexture(descriptor: outputDescriptor)
        else {
            XCTFail("could not allocate direct Metal validation textures")
            return []
        }

        if sourceFormat == .rgba16Float {
            var mutableSource = sourcePixels.map(Float16.init)
            source.replace(
                region: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0,
                withBytes: &mutableSource,
                bytesPerRow: width * 4 * MemoryLayout<Float16>.stride
            )
        } else {
            var mutableSource = sourcePixels
            source.replace(
                region: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0,
                withBytes: &mutableSource,
                bytesPerRow: width * 4 * MemoryLayout<Float>.stride
            )
        }
        let pipeline = try MetalLateDevelopPipeline(device: device)
        XCTAssertTrue(pipeline.encode(
            source: source,
            destination: output,
            commandBuffer: commandBuffer,
            exposureEV: exposureEV,
            contrast: contrast,
            nearestSampling: nearestSampling
        ))
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        XCTAssertEqual(commandBuffer.status, .completed)

        let resolvedOutputWidth = outputWidth ?? width
        let resolvedOutputHeight = outputHeight ?? height
        var outputPixels = [UInt8](
            repeating: 0,
            count: resolvedOutputWidth * resolvedOutputHeight * 4
        )
        output.getBytes(
            &outputPixels,
            bytesPerRow: resolvedOutputWidth * 4,
            from: MTLRegionMake2D(0, 0, resolvedOutputWidth, resolvedOutputHeight),
            mipmapLevel: 0
        )
        return outputPixels
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    @MainActor
    private func waitUntil(
        timeoutSeconds: Double,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(timeoutSeconds))
        while !condition() {
            if ContinuousClock.now >= deadline {
                throw NSError(
                    domain: "BanksiaTests.AsyncRenderTimeout",
                    code: 1
                )
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    private func rgbaBytes(_ image: CGImage) throws -> [UInt8] {
        let data = try XCTUnwrap(image.dataProvider?.data)
        let pointer = try XCTUnwrap(CFDataGetBytePtr(data))
        return Array(UnsafeBufferPointer(
            start: pointer,
            count: image.width * image.height * 4
        ))
    }

    private func bgraToRGBA(_ bytes: [UInt8]) -> [UInt8] {
        var rgba = bytes
        for offset in stride(from: 0, to: bytes.count, by: 4) {
            rgba[offset] = bytes[offset + 2]
            rgba[offset + 2] = bytes[offset]
        }
        return rgba
    }

    private func adversarialLinearPixels(width: Int, height: Int) -> [Float] {
        var pixels = [Float](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let gradient = Float(x) / Float(max(1, width - 1))
                let border = x == 0 || y == 0 || x == width - 1 || y == height - 1
                pixels[offset] = border ? -0.25 : gradient * 1.5
                pixels[offset + 1] = Float(y) / Float(max(1, height - 1)) * 0.01
                pixels[offset + 2] = x.isMultiple(of: 3) ? 2.0 : gradient
                pixels[offset + 3] = 1
            }
        }
        return pixels
    }

    private func cpuLateDevelop(
        sourcePixels: [Float],
        exposureEV: Double,
        contrast: Double
    ) -> [UInt8] {
        let gain = Float(exp2(exposureEV))
        var output = [UInt8](repeating: 0, count: sourcePixels.count)
        for offset in stride(from: 0, to: sourcePixels.count, by: 4) {
            var red = sourcePixels[offset] * gain
            var green = sourcePixels[offset + 1] * gain
            var blue = sourcePixels[offset + 2] * gain
            if contrast > 0 {
                red = tone(red, contrast)
                green = tone(green, contrast)
                blue = tone(blue, contrast)
            }
            let linearRed = 1.660491 * red - 0.587641 * green - 0.072850 * blue
            let linearGreen = -0.124550 * red + 1.132900 * green - 0.008349 * blue
            let linearBlue = -0.018151 * red - 0.100579 * green + 1.118730 * blue
            output[offset] = srgb(linearRed)
            output[offset + 1] = srgb(linearGreen)
            output[offset + 2] = srgb(linearBlue)
            output[offset + 3] = 255
        }
        return output
    }

    private func tone(_ value: Float, _ contrast: Double) -> Float {
        let clamped = min(1, max(0, value))
        let smooth = clamped * clamped * (3 - 2 * clamped)
        return clamped + Float(contrast) * (smooth - clamped)
    }

    private func srgb(_ value: Float) -> UInt8 {
        let clamped = min(1, max(0, value))
        let encoded = clamped <= 0.0031308
            ? 12.92 * clamped
            : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        return UInt8(min(255, max(0, round(encoded * 255))))
    }
}
