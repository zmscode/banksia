import Foundation
import Observation

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

    /// Two white_balance ops compose multiplicatively in the bayer domain:
    /// the camera's as-shot neutral first, the user's temperature/tint on
    /// top. That keeps "sliders at zero" looking like the camera intended.
    var recipeJSON: String {
        let gainR = format(exp2(temperature))
        let gainG = format(exp2(-tint))
        let gainB = format(exp2(-temperature))
        return "{\"engine_version\":2,\"ops\":["
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
