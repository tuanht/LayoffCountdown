import LayoffCore
import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(CountdownFormatter.menuBarTitle(state: model.state,
                                             style: model.settings.menuBarStyle,
                                             emoji: model.settings.emoji))
            .monospacedDigit()
            .task {
                if model.claimFirstLaunchSettings() { openWindow.settings() }
            }
    }
}
