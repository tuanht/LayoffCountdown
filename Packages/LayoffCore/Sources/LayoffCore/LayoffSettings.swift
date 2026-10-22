import Foundation

public struct LayoffSettings: Codable, Equatable, Sendable {
    public static let defaultEmoji = "💀"
    public static let `default` = LayoffSettings()

    public var layoffDate: Date?
    public var startDate: Date?
    public var emoji: String
    public var menuBarStyle: MenuBarStyle

    public init(layoffDate: Date? = nil, startDate: Date? = nil,
                emoji: String = defaultEmoji, menuBarStyle: MenuBarStyle = .short) {
        self.layoffDate = layoffDate
        self.startDate = startDate
        self.emoji = emoji
        self.menuBarStyle = menuBarStyle
    }

    private enum CodingKeys: String, CodingKey {
        case layoffDate, startDate, emoji, menuBarStyle
    }

    /// Missing or unreadable emoji/style (e.g. unknown style from newer build) fall back to defaults, so stored date survives.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        layoffDate = try c.decodeIfPresent(Date.self, forKey: .layoffDate)
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate)
        emoji = (try? c.decodeIfPresent(String.self, forKey: .emoji)) ?? Self.defaultEmoji
        menuBarStyle = (try? c.decodeIfPresent(MenuBarStyle.self, forKey: .menuBarStyle)) ?? .short
    }

    /// Keeps first grapheme only, so pasted sentence or ZWJ sequence still fits menu bar.
    public static func sanitizedEmoji(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? defaultEmoji
    }

    /// Start date defaults to first save of layoff date (notice period start for progress bar).
    public func settingLayoffDate(_ date: Date, now: Date) -> LayoffSettings {
        var copy = self
        copy.layoffDate = date
        if copy.startDate == nil { copy.startDate = now }
        return copy
    }

    /// 17:00 local, 30 days after start of today.
    public static func defaultLayoffDate(now: Date, calendar: Calendar) -> Date {
        let today = calendar.startOfDay(for: now)
        guard let day = calendar.date(byAdding: .day, value: 30, to: today),
              let moment = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day)
        else { return now.addingTimeInterval(30 * 86_400) }
        return moment
    }
}
