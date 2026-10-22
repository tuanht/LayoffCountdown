import Foundation
import LayoffCore
import WidgetKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings: LayoffSettings

    private let store = SettingsStore.make(appGroupID: AppGroup.current)
    private var didAutoOpenSettings = false

    init() {
        settings = store.load()
    }

    func state(at now: Date) -> CountdownState { .make(deadline: settings.layoffDate, now: now) }

    func update(_ s: LayoffSettings) {
        store.save(s)
        settings = s
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// True once per launch when no date set. Label `.task` reruns whenever status item rebuilds,
    /// so window must not pop again after user closed it.
    func claimFirstLaunchSettings() -> Bool {
        guard settings.layoffDate == nil, !didAutoOpenSettings else { return false }
        didAutoOpenSettings = true
        return true
    }
}
