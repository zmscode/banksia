import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        positionWindow()
        scheduleSelfShots()
    }

    /// Dev capture: an app may photograph its own on-screen window with no
    /// Screen Recording permission — the one path that works over a remote
    /// session. Opt in with BANKSIA_SELFSHOT=<path>; fires a few times so a shot
    /// lands after the async render settles.
    private func scheduleSelfShots() {
        guard let path = ProcessInfo.processInfo.environment["BANKSIA_SELFSHOT"] else { return }
        for delay in [3.0, 6.0, 9.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard let window = NSApp.windows.first(where: {
                    $0.styleMask.contains(.titled) && $0.contentView != nil
                }), let view = window.contentView,
                let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
                view.cacheDisplay(in: view.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?
                    .write(to: URL(fileURLWithPath: path))
            }
        }
    }

    /// SwiftUI creates its window a beat after `didFinishLaunching`, and frame
    /// restoration otherwise strands it off-screen between dev launches — so
    /// poll until the titled content window exists, then pin it centred at a
    /// known size.
    private func positionWindow(attempt: Int = 0) {
        if let window = NSApp.windows.first(where: {
            $0.styleMask.contains(.titled) && $0.contentView != nil
        }) {
            window.isRestorable = false
            window.setContentSize(NSSize(width: 1440, height: 860))
            window.center()
            window.makeKeyAndOrderFront(nil)
            return
        }
        guard attempt < 40 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.positionWindow(attempt: attempt + 1)
        }
    }
}

/// The inspection shell: a viewer and a tools column, so a human can watch the
/// engine work (plan.md, Phase 1).
@main
struct BanksiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("banksia") {
            ContentView()
        }
        .defaultSize(width: 1440, height: 860)
        .defaultPosition(.center)
    }
}
