import XCTest
@testable import Banksia

final class RenderContractTests: XCTestCase {
    func testOnlyNewestGenerationIsAccepted() {
        var clock = RenderGenerationClock()
        let first = clock.issue()
        XCTAssertTrue(clock.accepts(first))

        let second = clock.issue()
        XCTAssertFalse(clock.accepts(first))
        XCTAssertTrue(clock.accepts(second))
    }

    func testRequestSnapshotsRecipeIntentAndExecutionIdentity() {
        let request = RenderRequest(
            generation: 42,
            recipeJSON: "{\"engine_version\":2}",
            edgeMax: 1_024,
            intent: .interactivePreview,
            execution: .strictCPUDisplay
        )

        XCTAssertEqual(request.generation, 42)
        XCTAssertEqual(request.edgeMax, 1_024)
        XCTAssertEqual(request.intent, .interactivePreview)
        XCTAssertEqual(request.execution.renderer.backend, .strictCPU)
        XCTAssertEqual(request.execution.renderer.precision, .float32)
        XCTAssertEqual(request.execution.output, .cpuRGBA8SRGB)
    }

    func testCPUAndMetalIdentitiesCannotCollide() {
        let metal = RendererManifest(
            implementationID: "banksia.metal.candidate-f32.v1",
            engineVersion: 2,
            backend: .metalCandidate,
            precision: .float32
        )

        XCTAssertNotEqual(metal, .strictCPUV2)
        XCTAssertNotEqual(metal.implementationID, RendererManifest.strictCPUV2.implementationID)
    }

    func testLinearWorkingOutputHasItsOwnExecutionContract() {
        XCTAssertNotEqual(
            RenderExecutionContract.strictCPULinearWorking,
            .strictCPUDisplay
        )
        XCTAssertEqual(
            RenderExecutionContract.strictCPULinearWorking.output,
            .cpuRGBA32FloatLinearWorking
        )
        XCTAssertEqual(
            RenderExecutionContract.strictCPULinearWorking.renderer,
            .strictCPUV2
        )
    }

    func testStrictCPURendererRejectsMetalExecutionContract() async {
        let metal = RendererManifest(
            implementationID: "banksia.metal.candidate-f32.v1",
            engineVersion: 2,
            backend: .metalCandidate,
            precision: .float32
        )
        let request = RenderRequest(
            generation: 1,
            recipeJSON: "{\"engine_version\":2}",
            edgeMax: 1_024,
            intent: .interactivePreview,
            execution: RenderExecutionContract(
                renderer: metal,
                output: .platformGPUTexture
            )
        )

        do {
            _ = try await Renderer().render(request: request)
            XCTFail("strict CPU renderer accepted a Metal execution contract")
        } catch let error as EngineError {
            XCTAssertEqual(error.code, -1)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testArtifactKeysSeparateCPUAndMetalBackends() {
        func key(_ execution: RenderExecutionContract) -> RenderArtifactKey {
            RenderArtifactKey(
                sourceIdentity: "sha256:source",
                recipeIdentity: "sha256:recipe",
                edgeMax: 1_440,
                pixelWidth: 960,
                pixelHeight: 1_440,
                execution: execution
            )
        }

        let cpuLinear = key(.strictCPULinearWorking)
        let cpuDisplay = key(.strictCPUDisplay)
        let metal = key(.metalLateDevelop)
        XCTAssertEqual(Set([cpuLinear, cpuDisplay, metal]).count, 3)
        XCTAssertNotEqual(cpuLinear.execution.renderer, metal.execution.renderer)
        XCTAssertNotEqual(cpuDisplay.execution.output, metal.execution.output)
    }
}
