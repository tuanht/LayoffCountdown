import LayoffCore
import SwiftUI

struct MenuContent: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var ticker: Ticker
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let state = model.state(at: ticker.now)
        Text(countdown(state))
        if let date = model.settings.layoffDate {
            Text(date.formatted(.dateTime.weekday().day().month().year().hour().minute()))
        }
        Text(state == .done ? Jokes.farewell : Jokes.joke(for: ticker.now, calendar: .current))
        Divider()
        Button("Settings…") { openWindow.settings() }
            .keyboardShortcut(",")
        Button("Quit Layoff Countdown") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func countdown(_ state: CountdownState) -> String {
        switch state {
        case .notSet: return "Set date"
        case .done: return "Goodbye"
        case .counting(let remaining): return CountdownFormatter.full(remaining)
        }
    }
}
