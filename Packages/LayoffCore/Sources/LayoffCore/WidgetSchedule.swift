import Foundation

public enum WidgetSchedule {
    private static let day: TimeInterval = 86_400
    private static let horizon: TimeInterval = 48 * 3_600

    /// Moment day digit next drops; deadline itself on last day or when past.
    /// Widget shows `"\(days)d "` plus system timer counting down to it.
    public static func dayBoundary(before deadline: Date, now: Date) -> Date {
        let days = CountdownFormatter.parts(deadline.timeIntervalSince(now)).days
        return deadline.addingTimeInterval(-Double(days) * day)
    }

    /// Timeline entry dates, sorted and unique: now, 1 s after each day boundary within 48 h,
    /// deadline if within 48 h, next local midnight for joke change.
    public static func entryDates(now: Date, deadline: Date?, calendar: Calendar) -> [Date] {
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
            ?? now.addingTimeInterval(day)
        var dates: Set<Date> = [now]
        var boundaries: Set<Date> = []
        if let deadline, deadline > now {
            let end = now.addingTimeInterval(horizon)
            let days = CountdownFormatter.parts(deadline.timeIntervalSince(now)).days
            // Far-future deadline: first boundary already past end, loop exits at once.
            for k in stride(from: days, through: 0, by: -1) {
                let boundary = deadline.addingTimeInterval(-Double(k) * day)
                guard boundary <= end else { break }
                guard k > 0 else { dates.insert(deadline); break }
                boundaries.insert(boundary)
                // Entry exactly on boundary gets zero-length timer and freezes at `kd 0:00`.
                let entry = boundary.addingTimeInterval(1)
                if entry > now, entry <= end { dates.insert(entry) }
            }
        }
        // Midnight on boundary would freeze too; boundary + 1 s entry already changes joke.
        if !boundaries.contains(midnight) { dates.insert(midnight) }
        return dates.sorted()
    }
}
