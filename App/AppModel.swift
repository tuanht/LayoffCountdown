import Foundation
import LayoffCore
import WidgetKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings: LayoffSettings
    @Published private(set) var now = Date.now

    private let store = SettingsStore.make(appGroupID: AppGroup.current)
    private var timer: Timer?

    var state: CountdownState { .make(deadline: settings.layoffDate, now: now) }

    init() {
        settings = store.load()
        startTicking()
    }

    func update(_ s: LayoffSettings) {
        store.save(s)
        settings = s
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Fires on whole seconds so label flips together with widget's system timer.
    /// `.common` mode keeps ticking while dropdown menu tracks.
    private func startTicking() {
        let nextSecond = Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.up))
        let timer = Timer(fire: nextSecond, interval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = .now }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
