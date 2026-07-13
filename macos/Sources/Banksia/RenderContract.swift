import Foundation

enum PreviewResolutionPolicy {
    static let fastEdge: UInt32 = 1_440
    static let detailEdge: UInt32 = 2_880
    static let inspectionEdge: UInt32 = 4_096

    static func interactiveEdgeMax(requestedEdgeMax: UInt32) -> UInt32 {
        precondition(requestedEdgeMax > 0)
        return min(requestedEdgeMax, detailEdge)
    }

    static func edgeMax(
        sourceWidth: Int,
        sourceHeight: Int,
        fittedWidth: Double,
        fittedHeight: Double,
        zoomScale: Double,
        displayScale: Double
    ) -> UInt32 {
        guard sourceWidth > 0, sourceHeight > 0,
              fittedWidth > 0, fittedHeight > 0
        else { return 0 }
        precondition(zoomScale > 0)
        precondition(displayScale > 0)

        let sourceEdge = UInt32(clamping: max(sourceWidth, sourceHeight))
        let requiredEdge = max(fittedWidth, fittedHeight) * zoomScale * displayScale
        let tier: UInt32
        if requiredEdge <= Double(fastEdge) {
            tier = fastEdge
        } else if requiredEdge <= Double(detailEdge) {
            tier = detailEdge
        } else {
            tier = inspectionEdge
        }
        return min(sourceEdge, tier)
    }
}

/// Named colour/image domains prevent a future Metal backend from silently
/// interpreting one stage's pixels as another's. The current C ABI exposes
/// only the final display output; the remaining cases define the shared
/// vocabulary for the GPU surface work.
enum RenderDomain: String, Hashable, Sendable {
    case sensorCFA
    case cameraRGB
    case linearWorkingRGB
    case developedLinearRGB
    case displayEncodedRGB
}

enum RenderIntent: String, Hashable, Sendable {
    case interactivePreview
    case settledPreview
    case baseline
    case thumbnail
    case compatibility
}

enum RenderBackend: String, Hashable, Sendable {
    case strictCPU
    case metalCandidate
}

enum RenderPrecision: String, Hashable, Sendable {
    case float32
    case float16Candidate
}

enum RenderOutputKind: String, Hashable, Sendable {
    case cpuRGBA8SRGB
    case cpuRGBA32FloatLinearWorking
    case platformGPUTexture
}

struct PipelineStageManifest: Codable, Hashable, Sendable {
    let stageID: String
    let implementationID: String
    let inputDomain: String
    let outputDomain: String
    let neutralBehavior: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case stageID = "stage_id"
        case implementationID = "implementation_id"
        case inputDomain = "input_domain"
        case outputDomain = "output_domain"
        case neutralBehavior = "neutral_behavior"
        case status
    }
}

/// Complete immutable calibration and graph identity returned by the engine
/// after loading a RAW. Defaults live here, outside the user's adjustment
/// recipe, so changing a calibration cannot masquerade as the same artifact.
struct PipelineManifest: Codable, Hashable, Sendable {
    let recipeSchemaID: String
    let activeGraphID: String
    let targetGraphID: String
    let rendererID: String
    let backendID: String
    let precisionID: String
    let resolutionState: String
    let cameraState: String
    let isoState: String
    let lensState: String
    let bundleID: String
    let cameraRecordID: String?
    let isoRecordIDs: [String]
    let inputProfileID: String?
    let filmCurveID: String?
    let lensProfileID: String?
    let firstAffectedStageID: String
    let stages: [PipelineStageManifest]

    enum CodingKeys: String, CodingKey {
        case recipeSchemaID = "recipe_schema_id"
        case activeGraphID = "active_graph_id"
        case targetGraphID = "target_graph_id"
        case rendererID = "renderer_id"
        case backendID = "backend_id"
        case precisionID = "precision_id"
        case resolutionState = "resolution_state"
        case cameraState = "camera_state"
        case isoState = "iso_state"
        case lensState = "lens_state"
        case bundleID = "bundle_id"
        case cameraRecordID = "camera_record_id"
        case isoRecordIDs = "iso_record_ids"
        case inputProfileID = "input_profile_id"
        case filmCurveID = "film_curve_id"
        case lensProfileID = "lens_profile_id"
        case firstAffectedStageID = "first_affected_stage_id"
        case stages
    }

    static let legacyV2 = PipelineManifest(
        recipeSchemaID: "recipe.banksia.global.v2",
        activeGraphID: "graph.banksia.matrix.v2",
        targetGraphID: "graph.banksia.matrix.v2",
        rendererID: "banksia.cpu.strict-f32.v2",
        backendID: "strict_cpu",
        precisionID: "float32",
        resolutionState: "generic_fallback",
        cameraState: "capture_fact_missing",
        isoState: "iso_unavailable",
        lensState: "capture_fact_missing",
        bundleID: "calibration.none",
        cameraRecordID: nil,
        isoRecordIDs: [],
        inputProfileID: nil,
        filmCurveID: nil,
        lensProfileID: nil,
        firstAffectedStageID: "normalize",
        stages: []
    )
}

/// Stable identity for numerical behavior. CPU and Metal requests deliberately
/// cannot share an identity or cache entry merely because their recipes match.
struct RendererManifest: Hashable, Sendable {
    let implementationID: String
    let engineVersion: UInt32
    let backend: RenderBackend
    let precision: RenderPrecision

    static let strictCPUV4 = RendererManifest(
        implementationID: "banksia.cpu.strict-f32.v4",
        engineVersion: 4,
        backend: .strictCPU,
        precision: .float32
    )

    static let metalLateDevelopV1 = RendererManifest(
        implementationID: "banksia.metal.late-develop-f32.v1",
        engineVersion: 4,
        backend: .metalCandidate,
        precision: .float32
    )
}

struct RenderExecutionContract: Hashable, Sendable {
    let renderer: RendererManifest
    let output: RenderOutputKind

    static let strictCPUDisplay = RenderExecutionContract(
        renderer: .strictCPUV4,
        output: .cpuRGBA8SRGB
    )

    static let strictCPULinearWorking = RenderExecutionContract(
        renderer: .strictCPUV4,
        output: .cpuRGBA32FloatLinearWorking
    )

    static let metalLateDevelop = RenderExecutionContract(
        renderer: .metalLateDevelopV1,
        output: .platformGPUTexture
    )
}

struct RenderArtifactKey: Hashable, Sendable {
    let sourceIdentity: String
    let recipeIdentity: String
    let edgeMax: UInt32
    let pixelWidth: UInt32
    let pixelHeight: UInt32
    let execution: RenderExecutionContract
    let pipeline: PipelineManifest

    init(
        sourceIdentity: String,
        recipeIdentity: String,
        edgeMax: UInt32,
        pixelWidth: UInt32,
        pixelHeight: UInt32,
        execution: RenderExecutionContract,
        pipeline: PipelineManifest = .legacyV2
    ) {
        self.sourceIdentity = sourceIdentity
        self.recipeIdentity = recipeIdentity
        self.edgeMax = edgeMax
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.execution = execution
        self.pipeline = pipeline
    }

    var firstAffectedStageKey: PipelineStageArtifactKey {
        PipelineStageArtifactKey(
            sourceIdentity: sourceIdentity,
            recipeIdentity: recipeIdentity,
            stageID: pipeline.firstAffectedStageID,
            execution: execution,
            pipeline: pipeline
        )
    }
}

struct PipelineStageArtifactKey: Hashable, Sendable {
    let sourceIdentity: String
    let recipeIdentity: String
    let stageID: String
    let execution: RenderExecutionContract
    let pipeline: PipelineManifest
}

/// A complete immutable snapshot of work. Once issued, later UI mutations
/// create a new generation instead of changing this request under the actor.
struct RenderRequest: Equatable, Sendable {
    let generation: UInt64
    let recipeJSON: String
    let edgeMax: UInt32
    let intent: RenderIntent
    let execution: RenderExecutionContract
    let pipeline: PipelineManifest

    init(
        generation: UInt64,
        recipeJSON: String,
        edgeMax: UInt32,
        intent: RenderIntent,
        execution: RenderExecutionContract,
        pipeline: PipelineManifest = .legacyV2
    ) {
        self.generation = generation
        self.recipeJSON = recipeJSON
        self.edgeMax = edgeMax
        self.intent = intent
        self.execution = execution
        self.pipeline = pipeline
    }
}

/// Monotonic publication clock. Completion is publishable only while it is the
/// newest issued generation; opening another file also advances the clock and
/// invalidates every outstanding result.
struct RenderGenerationClock: Sendable {
    private(set) var latest: UInt64 = 0

    mutating func issue() -> UInt64 {
        precondition(latest < UInt64.max, "render generation exhausted")
        latest += 1
        return latest
    }

    func accepts(_ generation: UInt64) -> Bool {
        generation == latest
    }
}

enum MetalFrameAdmissionDecision: Equatable, Sendable {
    case admitted
    case coalesced
}

/// Pure admission state shared by tests and the viewer lock boundary. A burst
/// can occupy two drawable slots and retain only its newest rejected generation.
struct MetalFrameAdmissionState: Sendable {
    let limit: Int
    private(set) var inFlight = 0
    private(set) var newestGeneration: UInt64 = 0
    private(set) var retryGeneration: UInt64?

    init(limit: Int = 2) {
        precondition(limit > 0)
        self.limit = limit
    }

    mutating func request(generation: UInt64) -> MetalFrameAdmissionDecision {
        precondition(generation >= newestGeneration)
        newestGeneration = generation
        guard inFlight < limit else {
            retryGeneration = generation
            return .coalesced
        }
        inFlight += 1
        return .admitted
    }

    mutating func complete() -> UInt64? {
        precondition(inFlight > 0)
        inFlight -= 1
        defer { retryGeneration = nil }
        return retryGeneration
    }

    func shouldPublish(generation: UInt64) -> Bool {
        generation == newestGeneration
    }
}
