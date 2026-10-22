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
    /// ~31.7M years: far past any real deadline, far below Int.max.
    private static let maxSeconds: TimeInterval = 1e15

    /// Day = 86,400 s, not calendar day, so menu bar and widget agree across DST.
    public static func parts(_ remaining: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        // Int(Double) traps on NaN, infinity and values past Int.max.
        guard remaining.isFinite, remaining > 0 else { return (0, 0, 0, 0) }
        let total = Int(min(remaining, maxSeconds).rounded(.down))
        return (total / 86_400, total % 86_400 / 3_600, total % 3_600 / 60, total % 60)
    }

    public static func short(_ remaining: TimeInterval) -> String {
        let p = parts(remaining)
        if p.days > 0 { return "\(p.days)d \(p.hours)h" }
        if p.hours > 0 { return "\(p.hours)h \(p.minutes)m" }
        return "\(p.minutes)m \(p.seconds)s"
    }

    /// Mirrors widget's system timer text: `H:MM:SS`, or `M:SS` when no hours left in current day.
    public static func full(_ remaining: TimeInterval) -> String {
        let p = parts(remaining)
        let clock = p.hours > 0
            ? String(format: "%ld:%02ld:%02ld", p.hours, p.minutes, p.seconds)
            : String(format: "%ld:%02ld", p.minutes, p.seconds)
        return "\(p.days)d \(clock)"
    }

    public static func menuBarTitle(state: CountdownState, style: MenuBarStyle, emoji: String) -> String {
        switch state {
        case .notSet: return "\(emoji) Set date"
        case .done: return "\(emoji) Goodbye"
        case .counting(let remaining):
            switch style {
            case .short: return "\(emoji) \(short(remaining))"
            case .full: return "\(emoji) \(full(remaining))"
            }
        }
    }
}
