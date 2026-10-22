import LayoffCore
import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var ticker: Ticker
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuBarTitle(state: model.state(at: ticker.now),
                     style: model.settings.menuBarStyle,
                     emoji: model.settings.emoji)
            .task {
                if model.claimFirstLaunchSettings() { openWindow.settings() }
            }
    }
}

struct MenuBarTitle: View {
    let state: CountdownState
    let style: MenuBarStyle
    let emoji: String

    var body: some View {
        Text(CountdownFormatter.menuBarTitle(state: state, style: style, emoji: emoji))
            .monospacedDigit()
    }
}
