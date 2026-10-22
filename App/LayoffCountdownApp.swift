import SwiftUI

@main
struct LayoffCountdownApp: App {
    @StateObject private var model: AppModel
    @StateObject private var ticker: Ticker
    @StateObject private var clock: MenuClock

    init() {
        let model = AppModel()
        let ticker = Ticker()
        _model = StateObject(wrappedValue: model)
        _ticker = StateObject(wrappedValue: ticker)
        _clock = StateObject(wrappedValue: MenuClock(ticker: ticker))
    }

    var body: some Scene {
        // MenuBarExtra first: SwiftUI auto-opens first window scene at launch, settings window must not.
        MenuBarExtra {
            MenuContent()
                .environmentObject(model)
                .environmentObject(clock)
        } label: {
            MenuBarLabel()
                .environmentObject(model)
                .environmentObject(ticker)
        }
        .menuBarExtraStyle(.menu)

        Window("Layoff Countdown Settings", id: OpenWindowAction.settingsID) {
            SettingsView()
                .environmentObject(model)
                .environmentObject(ticker)
                .background(NonRestorableWindow())
        }
        .windowResizability(.contentSize)
    }
}

extension OpenWindowAction {
    static let settingsID = "settings"

    /// Menu bar only app is never frontmost on its own, so window would open behind other apps.
    @MainActor func settings() {
        self(id: Self.settingsID)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Restored settings window would pop on relaunch when "Close windows when quitting an app" is off.
/// `restorationBehavior(.disabled)` needs macOS 15, and `NSQuitAlwaysKeepsWindows` registered default
/// loses to the global setting, so opt out per window.
private struct NonRestorableWindow: NSViewRepresentable {
    final class HostView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.isRestorable = false
        }
    }

    func makeNSView(context: Context) -> HostView { HostView() }
    func updateNSView(_ nsView: HostView, context: Context) {}
}
