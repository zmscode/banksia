import CoreImage
import Metal
import XCTest
@testable import Banksia

final class MetalPresentationTests: XCTestCase {
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
        sourcePixels: [Float],
        exposureEV: Double,
        contrast: Double
    ) throws -> [UInt8] {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let commandBuffer = queue.makeCommandBuffer()
        else {
            throw XCTSkip("Metal is unavailable")
        }

        let sourceDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: width,
            height: height,
            mipmapped: false
        )
        sourceDescriptor.storageMode = .shared
        sourceDescriptor.usage = [.shaderRead]
        let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: width,
            height: height,
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

        var mutableSource = sourcePixels
        source.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: &mutableSource,
            bytesPerRow: width * 4 * MemoryLayout<Float>.stride
        )
        let pipeline = try MetalLateDevelopPipeline(device: device)
        XCTAssertTrue(pipeline.encode(
            source: source,
            destination: output,
            commandBuffer: commandBuffer,
            exposureEV: exposureEV,
            contrast: contrast
        ))
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        XCTAssertEqual(commandBuffer.status, .completed)

        var outputPixels = [UInt8](repeating: 0, count: width * height * 4)
        output.getBytes(
            &outputPixels,
            bytesPerRow: width * 4,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )
        return outputPixels
    }
}
