import AppKit
import LayoffCore
import SwiftUI

struct MenuContent: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var clock: MenuClock
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let now = clock.openedAt
        let state = model.state(at: now)
        Text(Self.countdown(state))
        if let date = model.settings.layoffDate {
            Text(date.formatted(.dateTime.weekday().day().month().year().hour().minute()))
        }
        Text(state == .done ? Jokes.farewell : Jokes.joke(for: now, calendar: .current))
        Divider()
        Button("Settings…") { openWindow.settings() }
            .keyboardShortcut(",")
        Button("Quit Layoff Countdown") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    static func countdown(_ state: CountdownState) -> String {
        switch state {
        case .notSet: return "Set date"
        case .done: return "Goodbye"
        case .counting(let remaining): return CountdownFormatter.full(remaining)
        }
    }
}

/// SwiftUI replaces a dropdown item whose text changes, and replacing one while the menu is open
/// moves the hover highlight onto the row above. So the dropdown doesn't observe `Ticker`: it shows
/// the time the menu opened at, while the menu bar label keeps ticking.
@MainActor
final class MenuClock: ObservableObject {
    @Published private(set) var openedAt = Date.now
    private var observer: NSObjectProtocol?

    init(ticker: Ticker) {
        // Queue nil: must land before SwiftUI fills the menu, which happens synchronously after begin.
        observer = NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: nil) { [weak self] _ in
            MainActor.assumeIsolated { self?.openedAt = ticker.now }
        }
    }
}
