import SwiftUI

@main
struct LayoffCountdownApp: App {
    var body: some Scene {
        MenuBarExtra("💀") {
            Button("Quit") { NSApp.terminate(nil) }
        }
    }
}
