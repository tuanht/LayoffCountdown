import SwiftUI

@main
struct LayoffCountdownApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        // MenuBarExtra first: SwiftUI auto-opens first window scene at launch, settings window must not.
        MenuBarExtra {
            MenuContent()
                .environmentObject(model)
        } label: {
            MenuBarLabel()
                .environmentObject(model)
        }
        .menuBarExtraStyle(.menu)

        Window("Layoff Countdown Settings", id: OpenWindowAction.settingsID) {
            SettingsView()
                .environmentObject(model)
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
