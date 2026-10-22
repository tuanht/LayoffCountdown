import XCTest
@testable import LayoffCore

final class WidgetScheduleTests: XCTestCase {
    var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }()
    // 2026-10-22 10:00 Berlin (CEST, UTC+2).
    let now = Date(timeIntervalSince1970: 1_792_656_000)
    // 2026-10-23 00:00 Berlin.
    let nextMidnight = Date(timeIntervalSince1970: 1_792_706_400)

    func testFixturesMatchCalendar() {
        XCTAssertEqual(cal.dateComponents([.year, .month, .day, .hour], from: now),
                       DateComponents(year: 2026, month: 10, day: 22, hour: 10))
        XCTAssertEqual(nextMidnight, cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)))
    }

    func testScheduleHasEntryAtEachDayBoundary() {
        // deadline = now + 1d 2h → boundaries at now+2h (1d→0d) and deadline
        let dates = WidgetSchedule.entryDates(now: now, deadline: now.addingTimeInterval(86_400 + 7_200), calendar: cal)
        XCTAssertTrue(dates.contains(now.addingTimeInterval(7_200)))
        XCTAssertTrue(dates.contains(now.addingTimeInterval(86_400 + 7_200)))
        XCTAssertEqual(dates, dates.sorted())
    }

    func testScheduleExactEntries() {
        let deadline = now.addingTimeInterval(86_400 + 7_200)
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: deadline, calendar: cal),
                       [now, now.addingTimeInterval(7_200), nextMidnight, deadline])
    }

    func testScheduleStopsAt48Hours() {
        let deadline = now.addingTimeInterval(10 * 86_400 + 100)
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: deadline, calendar: cal),
                       [now, now.addingTimeInterval(100), nextMidnight, now.addingTimeInterval(86_400 + 100)])
    }

    func testDayBoundaryMatchesFormatter() {
        // just after the boundary, formatter shows one fewer day
        let dl = now.addingTimeInterval(3*86_400 + 100)
        let b = WidgetSchedule.dayBoundary(before: dl, now: now)
        XCTAssertEqual(b, now.addingTimeInterval(100))
        XCTAssertEqual(CountdownFormatter.parts(dl.timeIntervalSince(b.addingTimeInterval(1))).days, 2)
    }

    func testDayBoundaryOnLastDayIsDeadline() {
        let dl = now.addingTimeInterval(500)
        XCTAssertEqual(WidgetSchedule.dayBoundary(before: dl, now: now), dl)
    }

    func testScheduleWithoutDeadline() {
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: nil, calendar: cal), [now, nextMidnight])
    }

    func testScheduleWithPastDeadline() {
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: now.addingTimeInterval(-5), calendar: cal), [now, nextMidnight])
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: now, calendar: cal), [now, nextMidnight])
        XCTAssertEqual(WidgetSchedule.dayBoundary(before: now.addingTimeInterval(-5), now: now), now.addingTimeInterval(-5))
    }

    func testFarFutureDeadlineDoesNotTrap() {
        let far = Date(timeIntervalSinceReferenceDate: 1e300)
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: far, calendar: cal), [now, nextMidnight])
        _ = WidgetSchedule.dayBoundary(before: far, now: now)
    }
}
