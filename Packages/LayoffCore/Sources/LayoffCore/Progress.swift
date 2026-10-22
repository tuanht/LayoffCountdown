import Foundation

public enum NoticeProgress {
    /// Elapsed share of notice period, clamped to 0...1.
    /// Missing or invalid start (on/after deadline) counts as full, never NaN.
    public static func fraction(start: Date?, deadline: Date, now: Date) -> Double {
        guard let start, start < deadline else { return 1.0 }
        let elapsed = now.timeIntervalSince(start) / deadline.timeIntervalSince(start)
        return min(max(elapsed, 0), 1)
    }
}
