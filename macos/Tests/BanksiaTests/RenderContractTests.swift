import XCTest
@testable import Banksia

final class RenderContractTests: XCTestCase {
    func testDevelopRecipesRemainIsolatedByCanonicalAssetURL() {
        let folder = URL(fileURLWithPath: "/tmp/banksia-recipe-isolation")
        let first = folder.appendingPathComponent("first.CR3")
        let equivalentFirst = folder
            .appendingPathComponent("nested")
            .appendingPathComponent("..")
            .appendingPathComponent("first.CR3")
        let second = folder.appendingPathComponent("second.CR3")
        let firstState = DevelopRecipeState(
            ev: 0.75,
            temperature: -0.25,
            tint: 0.2,
            contrast: 0.4
        )
        let secondState = DevelopRecipeState(
            ev: -1.0,
            temperature: 0.5,
            tint: -0.1,
            contrast: 0.05
        )

        var store = AssetDevelopStore()
        XCTAssertEqual(store.state(for: first), .neutral)
        XCTAssertEqual(store.state(for: second), .neutral)

        store.save(firstState, for: first)
        store.save(secondState, for: second)

        XCTAssertEqual(store.state(for: equivalentFirst), firstState)
        XCTAssertEqual(store.state(for: second), secondState)
        XCTAssertNotEqual(store.state(for: first), store.state(for: second))
    }

    func testDevelopModelSnapshotsAndRestoresEveryRecipeValue() {
        let state = DevelopRecipeState(
            ev: 1.25,
            temperature: 0.3,
            tint: -0.2,
            contrast: 0.8
        )
        let model = DevelopModel(state: state)

        XCTAssertEqual(model.state, state)
        XCTAssertTrue(model.hasEdits)

        model.reset()

        XCTAssertEqual(model.state, .neutral)
        XCTAssertFalse(model.hasEdits)
    }

    func testDevelopModelSelectsImmutableEngineV4NonlinearProfile() {
        let recipe = DevelopModel().recipeJSON

        XCTAssertTrue(recipe.contains("\"engine_version\":4"))
        XCTAssertTrue(recipe.contains("\"camera_profile\":\"resolved_nonlinear\""))
    }

    func testPreviewResolutionPolicyProgressesWithoutExceedingSource() {
        XCTAssertEqual(
            PreviewResolutionPolicy.edgeMax(
                sourceWidth: 3_648,
                sourceHeight: 5_472,
                fittedWidth: 456,
                fittedHeight: 684,
                zoomScale: 1,
                displayScale: 2
            ),
            1_440
        )
        XCTAssertEqual(
            PreviewResolutionPolicy.edgeMax(
                sourceWidth: 3_648,
                sourceHeight: 5_472,
                fittedWidth: 456,
                fittedHeight: 684,
                zoomScale: 1.5,
                displayScale: 2
            ),
            2_880
        )
        XCTAssertEqual(
            PreviewResolutionPolicy.edgeMax(
                sourceWidth: 3_648,
                sourceHeight: 5_472,
                fittedWidth: 456,
                fittedHeight: 684,
                zoomScale: 4,
                displayScale: 2
            ),
            4_096
        )
        XCTAssertEqual(
            PreviewResolutionPolicy.edgeMax(
                sourceWidth: 800,
                sourceHeight: 1_200,
                fittedWidth: 400,
                fittedHeight: 600,
                zoomScale: 8,
                displayScale: 2
            ),
            1_200
        )
    }

    func testPreviewResolutionPolicyWaitsForSourceAndLayout() {
        XCTAssertEqual(
            PreviewResolutionPolicy.edgeMax(
                sourceWidth: 0,
                sourceHeight: 0,
                fittedWidth: 0,
                fittedHeight: 0,
                zoomScale: 1,
                displayScale: 2
            ),
            0
        )
        XCTAssertEqual(
            PreviewResolutionPolicy.interactiveEdgeMax(requestedEdgeMax: 4_096),
            2_880
        )
        XCTAssertEqual(
            PreviewResolutionPolicy.interactiveEdgeMax(requestedEdgeMax: 1_440),
            1_440
        )
    }

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
        XCTAssertEqual(request.pipeline, .legacyV2)
    }

    func testCPUAndMetalIdentitiesCannotCollide() {
        let metal = RendererManifest(
            implementationID: "banksia.metal.candidate-f32.v1",
            engineVersion: 2,
            backend: .metalCandidate,
            precision: .float32
        )

        XCTAssertNotEqual(metal, .strictCPUV4)
        XCTAssertNotEqual(metal.implementationID, RendererManifest.strictCPUV4.implementationID)
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
            .strictCPUV4
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

    func testCalibrationDependenciesSeparateArtifactsAtFirstAffectedStage() {
        let first = pipeline(bundleID: "calibration.bundle.v1")
        let second = pipeline(bundleID: "calibration.bundle.v2")
        let keyOne = RenderArtifactKey(
            sourceIdentity: "sha256:source",
            recipeIdentity: "sha256:recipe",
            edgeMax: 1_440,
            pixelWidth: 960,
            pixelHeight: 1_440,
            execution: .strictCPULinearWorking,
            pipeline: first
        )
        let keyTwo = RenderArtifactKey(
            sourceIdentity: "sha256:source",
            recipeIdentity: "sha256:recipe",
            edgeMax: 1_440,
            pixelWidth: 960,
            pixelHeight: 1_440,
            execution: .strictCPULinearWorking,
            pipeline: second
        )

        XCTAssertNotEqual(keyOne, keyTwo)
        XCTAssertNotEqual(keyOne.firstAffectedStageKey, keyTwo.firstAffectedStageKey)
        XCTAssertEqual(keyOne.firstAffectedStageKey.stageID, "normalize")
    }

    func testMetalBurstAdmissionIsBoundedAndCoalescesNewestGeneration() {
        var admission = MetalFrameAdmissionState(limit: 2)
        XCTAssertEqual(admission.request(generation: 1), .admitted)
        XCTAssertEqual(admission.request(generation: 2), .admitted)
        for generation in 3...10_000 {
            XCTAssertEqual(admission.request(generation: UInt64(generation)), .coalesced)
            XCTAssertLessThanOrEqual(admission.inFlight, 2)
        }
        XCTAssertEqual(admission.retryGeneration, 10_000)
        XCTAssertEqual(admission.complete(), 10_000)
        XCTAssertEqual(admission.request(generation: 10_000), .admitted)
        XCTAssertLessThanOrEqual(admission.inFlight, 2)
    }

    func testMetalStaleGenerationIsNeverPublishable() {
        var admission = MetalFrameAdmissionState(limit: 2)
        XCTAssertEqual(admission.request(generation: 40), .admitted)
        XCTAssertTrue(admission.shouldPublish(generation: 40))
        XCTAssertEqual(admission.request(generation: 41), .admitted)
        XCTAssertFalse(admission.shouldPublish(generation: 40))
        XCTAssertTrue(admission.shouldPublish(generation: 41))
    }

    private func pipeline(bundleID: String) -> PipelineManifest {
        PipelineManifest(
            recipeSchemaID: "recipe.banksia.global.v2",
            activeGraphID: "graph.banksia.matrix.v2",
            targetGraphID: "graph.banksia.calibrated.v1",
            rendererID: "banksia.cpu.strict-f32.v2",
            backendID: "strict_cpu",
            precisionID: "float32",
            resolutionState: "resolved",
            cameraState: "resolved",
            isoState: "resolved",
            lensState: "resolved",
            bundleID: bundleID,
            cameraRecordID: "camera.canon.r3.v1",
            isoRecordIDs: ["camera.canon.r3.iso.100.v1"],
            inputProfileID: "profile.canon.r3.v1",
            filmCurveID: "curve.canon.r3.auto.v1",
            lensProfileID: "lens.canon.24-70.v1",
            firstAffectedStageID: "normalize",
            stages: []
        )
    }

    func testMetalAdmissionRemainsBoundedUnderSeededRandomBurst() {
        var admission = MetalFrameAdmissionState(limit: 2)
        var random: UInt64 = 0x2c6_5eed
        var generation: UInt64 = 0
        for _ in 0..<10_000 {
            random = random &* 6_364_136_223_846_793_005 &+ 1
            if admission.inFlight == 0 || random & 3 != 0 {
                generation += 1
                _ = admission.request(generation: generation)
            } else if let retry = admission.complete() {
                _ = admission.request(generation: retry)
            }
            XCTAssertLessThanOrEqual(admission.inFlight, admission.limit)
        }
    }
}
