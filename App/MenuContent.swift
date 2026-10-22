import LayoffCore
import SwiftUI

struct MenuContent: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(countdown)
        if let date = model.settings.layoffDate {
            Text(date.formatted(.dateTime.weekday().day().month().year().hour().minute()))
        }
        Text(model.state == .done ? Jokes.farewell : Jokes.joke(for: model.now, calendar: .current))
        Divider()
        Button("Settings…") { openWindow.settings() }
            .keyboardShortcut(",")
        Button("Quit Layoff Countdown") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var countdown: String {
        switch model.state {
        case .notSet: return "Set date"
        case .done: return "Goodbye"
        case .counting(let remaining): return CountdownFormatter.full(remaining)
        }
    }
}
