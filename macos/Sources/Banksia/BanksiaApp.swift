import SwiftUI

/// The inspection shell: a window, four sliders, an image. The engine does
/// the work; this exists so a human can watch it happen (plan.md, Phase 1).
@main
struct BanksiaApp: App {
    var body: some Scene {
        WindowGroup("banksia") {
            ContentView()
        }
    }
}
