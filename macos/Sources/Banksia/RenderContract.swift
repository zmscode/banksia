import Foundation

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

/// Stable identity for numerical behavior. CPU and Metal requests deliberately
/// cannot share an identity or cache entry merely because their recipes match.
struct RendererManifest: Hashable, Sendable {
    let implementationID: String
    let engineVersion: UInt32
    let backend: RenderBackend
    let precision: RenderPrecision

    static let strictCPUV2 = RendererManifest(
        implementationID: "banksia.cpu.strict-f32.v2",
        engineVersion: 2,
        backend: .strictCPU,
        precision: .float32
    )

    static let metalLateDevelopV1 = RendererManifest(
        implementationID: "banksia.metal.late-develop-f32.v1",
        engineVersion: 2,
        backend: .metalCandidate,
        precision: .float32
    )
}

struct RenderExecutionContract: Hashable, Sendable {
    let renderer: RendererManifest
    let output: RenderOutputKind

    static let strictCPUDisplay = RenderExecutionContract(
        renderer: .strictCPUV2,
        output: .cpuRGBA8SRGB
    )

    static let strictCPULinearWorking = RenderExecutionContract(
        renderer: .strictCPUV2,
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
}

/// A complete immutable snapshot of work. Once issued, later UI mutations
/// create a new generation instead of changing this request under the actor.
struct RenderRequest: Equatable, Sendable {
    let generation: UInt64
    let recipeJSON: String
    let edgeMax: UInt32
    let intent: RenderIntent
    let execution: RenderExecutionContract
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
