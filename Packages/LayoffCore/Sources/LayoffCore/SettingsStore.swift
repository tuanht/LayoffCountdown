import Foundation

public final class SettingsStore {
    static let key = "layoffSettings.v1"

    public let usesAppGroup: Bool
    private let defaults: UserDefaults

    public convenience init(defaults: UserDefaults) {
        self.init(defaults: defaults, migratingFrom: nil)
    }

    /// Copies settings from `source` when `defaults` has none, so adding team later keeps user's date.
    init(defaults: UserDefaults, migratingFrom source: UserDefaults?, usesAppGroup: Bool = false) {
        self.defaults = defaults
        self.usesAppGroup = usesAppGroup
        if defaults.data(forKey: Self.key) == nil, let data = source?.data(forKey: Self.key) {
            defaults.set(data, forKey: Self.key)
        }
    }

    /// App Group when usable, else `.standard`, so menu bar app never depends on App Group.
    public static func make(appGroupID: String?) -> SettingsStore {
        // Real guard: `AppGroup.identifier` gives nil without team. On macOS `containerURL` returns URL
        // even for unentitled group, so container check only cheap extra.
        guard let appGroupID,
              FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil,
              let group = UserDefaults(suiteName: appGroupID)
        else { return SettingsStore(defaults: .standard) }
        return SettingsStore(defaults: group, migratingFrom: .standard, usesAppGroup: true)
    }

    /// Unreadable or corrupt data yields defaults, never crash.
    public func load() -> LayoffSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(LayoffSettings.self, from: data)
        else { return .default }
        return settings
    }

    public func save(_ settings: LayoffSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
