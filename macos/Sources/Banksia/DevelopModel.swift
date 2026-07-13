import Foundation
import Observation

/// Value-semantic adjustment state owned by one asset. Keeping this separate
/// from the observable control model prevents selection changes from turning a
/// window-wide slider value into an implicit batch edit.
struct DevelopRecipeState: Equatable, Sendable {
    var ev: Double = 0
    var temperature: Double = 0
    var tint: Double = 0
    var contrast: Double = 0

    static let neutral = DevelopRecipeState()
}

/// Session-scoped recipe ownership. Catalog/session durability belongs to a
/// later phase, but identity and isolation are already explicit here.
struct AssetDevelopStore {
    private var statesByAsset: [URL: DevelopRecipeState] = [:]

    mutating func save(_ state: DevelopRecipeState, for url: URL) {
        statesByAsset[Self.key(for: url)] = state
    }

    func state(for url: URL) -> DevelopRecipeState {
        statesByAsset[Self.key(for: url)] ?? .neutral
    }

    private static func key(for url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }
}

/// The slider state and the canonical-form recipe JSON it becomes. The JSON
/// mirrors emu/recipe.zig's canonical serialization exactly — the engine
/// parses strictly, so field names and stack shape must match.
@Observable
final class DevelopModel {
    /// Exposure in stops.
    var ev: Double = 0
    /// Warm/cool: red gain up, blue gain down, exp2-scaled.
    var temperature: Double = 0
    /// Green/magenta: positive pulls green down.
    var tint: Double = 0
    /// 0 identity, 1 full S-curve; the baseline engine defines no negative contrast.
    var contrast: Double = 0

    init(state: DevelopRecipeState = .neutral) {
        ev = state.ev
        temperature = state.temperature
        tint = state.tint
        contrast = state.contrast
    }

    var state: DevelopRecipeState {
        DevelopRecipeState(
            ev: ev,
            temperature: temperature,
            tint: tint,
            contrast: contrast
        )
    }

    /// True when any slider is off its identity value — drives the reset
    /// affordance and the before/after compare being meaningful.
    var hasEdits: Bool {
        ev != 0 || temperature != 0 || tint != 0 || contrast != 0
    }

    /// Return every slider to identity. The neutral recipe this produces is
    /// exactly the "before" the compare gesture renders against.
    func reset() {
        ev = 0
        temperature = 0
        tint = 0
        contrast = 0
    }

    /// Two white_balance ops compose multiplicatively in the bayer domain:
    /// the camera's as-shot neutral first, the user's temperature/tint on
    /// top. That keeps "sliders at zero" looking like the camera intended.
    var recipeJSON: String {
        let gainR = format(exp2(temperature))
        let gainG = format(exp2(-tint))
        let gainB = format(exp2(-temperature))
        return "{\"engine_version\":3,\"ops\":["
            + "{\"black_point\":{}},"
            + "{\"white_balance\":{\"as_shot\":true,\"gain_r\":1,\"gain_g\":1,\"gain_b\":1}},"
            + "{\"white_balance\":{\"as_shot\":false"
            + ",\"gain_r\":\(gainR),\"gain_g\":\(gainG),\"gain_b\":\(gainB)}},"
            + "{\"demosaic\":{}},"
            + "{\"exposure\":{\"ev\":\(format(ev))}},"
            + "{\"tone_curve\":{\"contrast\":\(format(contrast))}},"
            + "{\"srgb_encode\":{}}]}"
    }

    /// Unlocalized fixed-point: recipe JSON must never grow a decimal comma.
    private func format(_ value: Double) -> String {
        String(format: "%.5f", value)
    }
}
