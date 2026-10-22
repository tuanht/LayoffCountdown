import Foundation

public enum MenuBarStyle: String, Codable, CaseIterable {
    case short, full
}

public enum CountdownState: Equatable {
    case notSet
    case counting(remaining: TimeInterval)
    case done

    public static func make(deadline: Date?, now: Date) -> CountdownState {
        guard let deadline else { return .notSet }
        let remaining = deadline.timeIntervalSince(now)
        return remaining <= 0 ? .done : .counting(remaining: remaining)
    }
}

public enum CountdownFormatter {
    /// Day = 86,400 s, not calendar day, so menu bar and widget agree across DST.
    public static func parts(_ remaining: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let total = max(0, Int(remaining.rounded(.down)))
        return (total / 86_400, total % 86_400 / 3_600, total % 3_600 / 60, total % 60)
    }

    public static func short(_ remaining: TimeInterval) -> String {
        let p = parts(remaining)
        if p.days > 0 { return "\(p.days)d \(p.hours)h" }
        if p.hours > 0 { return "\(p.hours)h \(p.minutes)m" }
        return "\(p.minutes)m \(p.seconds)s"
    }

    public static func full(_ remaining: TimeInterval) -> String {
        let p = parts(remaining)
        return "\(p.days)d " + String(format: "%02d:%02d:%02d", p.hours, p.minutes, p.seconds)
    }

    public static func menuBarTitle(state: CountdownState, style: MenuBarStyle, emoji: String) -> String {
        switch state {
        case .notSet: return "\(emoji) Set date"
        case .done: return "\(emoji) Goodbye"
        case .counting(let remaining):
            return "\(emoji) " + (style == .short ? short(remaining) : full(remaining))
        }
    }
}
