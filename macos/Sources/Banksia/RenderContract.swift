import Foundation

/// Named colour/image domains prevent a future Metal backend from silently
/// interpreting one stage's pixels as another's. The current C ABI exposes
/// only the final display output; the remaining cases define the shared
/// vocabulary for the GPU surface work.
enum RenderDomain: String, Sendable {
    case sensorCFA
    case cameraRGB
    case linearWorkingRGB
    case developedLinearRGB
    case displayEncodedRGB
}

enum RenderIntent: String, Sendable {
    case interactivePreview
    case settledPreview
    case baseline
    case thumbnail
    case compatibility
}

enum RenderBackend: String, Sendable {
    case strictCPU
    case metalCandidate
}

enum RenderPrecision: String, Sendable {
    case float32
    case float16Candidate
}

enum RenderOutputKind: String, Sendable {
    case cpuRGBA8SRGB
    case platformGPUTexture
}

/// Stable identity for numerical behavior. CPU and Metal requests deliberately
/// cannot share an identity or cache entry merely because their recipes match.
struct RendererManifest: Equatable, Sendable {
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
}

struct RenderExecutionContract: Equatable, Sendable {
    let renderer: RendererManifest
    let output: RenderOutputKind

    static let strictCPUDisplay = RenderExecutionContract(
        renderer: .strictCPUV2,
        output: .cpuRGBA8SRGB
    )
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
