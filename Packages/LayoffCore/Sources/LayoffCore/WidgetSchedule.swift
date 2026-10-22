import Foundation

public enum WidgetSchedule {
    private static let day: TimeInterval = 86_400
    private static let horizon: TimeInterval = 48 * 3_600

    /// Next moment day digit drops. Widget shows `"\(days)d "` plus system timer counting down to it.
    /// Past deadline gives deadline itself.
    public static func dayBoundary(before deadline: Date, now: Date) -> Date {
        let days = CountdownFormatter.parts(deadline.timeIntervalSince(now)).days
        return deadline.addingTimeInterval(-Double(days) * day)
    }

    /// Timeline entry dates, sorted and unique: now, each day boundary and deadline within 48 h, next local midnight.
    public static func entryDates(now: Date, deadline: Date?, calendar: Calendar) -> [Date] {
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
            ?? now.addingTimeInterval(day)
        var dates: Set<Date> = [now, midnight]
        if let deadline, deadline > now {
            let end = now.addingTimeInterval(horizon)
            // Far-future deadline puts first boundary past end, so loop never runs.
            var boundary = dayBoundary(before: deadline, now: now)
            while boundary <= deadline, boundary <= end {
                if boundary > now { dates.insert(boundary) }
                boundary = boundary.addingTimeInterval(day)
            }
        }
        return dates.sorted()
    }
}
