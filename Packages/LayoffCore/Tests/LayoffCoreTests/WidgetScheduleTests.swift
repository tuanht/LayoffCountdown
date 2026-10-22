import XCTest
@testable import LayoffCore

final class WidgetScheduleTests: XCTestCase {
    let cal: Calendar = {
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
        // deadline = now + 1d 2h → entries 1 s after boundary now+2h (1d→0d), and at deadline
        let dates = WidgetSchedule.entryDates(now: now, deadline: now.addingTimeInterval(86_400 + 7_200), calendar: cal)
        XCTAssertTrue(dates.contains(now.addingTimeInterval(7_201)))
        XCTAssertTrue(dates.contains(now.addingTimeInterval(86_400 + 7_200)))
        XCTAssertEqual(dates, dates.sorted())
    }

    func testScheduleExactEntries() {
        let deadline = now.addingTimeInterval(86_400 + 7_200)
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: deadline, calendar: cal),
                       [now, now.addingTimeInterval(7_201), nextMidnight, deadline])
    }

    func testScheduleStopsAt48Hours() {
        let deadline = now.addingTimeInterval(10 * 86_400 + 100)
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: deadline, calendar: cal),
                       [now, now.addingTimeInterval(101), nextMidnight, now.addingTimeInterval(86_400 + 101)])
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

    func assertNoZeroLengthTimer(deadline: Date, file: StaticString = #filePath, line: UInt = #line) {
        let dates = WidgetSchedule.entryDates(now: now, deadline: deadline, calendar: cal)
        for d in dates where d < deadline {
            XCTAssertGreaterThan(WidgetSchedule.dayBoundary(before: deadline, now: d), d, "entry \(d)", file: file, line: line)
        }
    }

    func testNoEntryHasZeroLengthTimer() {
        assertNoZeroLengthTimer(deadline: now.addingTimeInterval(86_400 + 7_200))
        assertNoZeroLengthTimer(deadline: now.addingTimeInterval(10 * 86_400 + 100))
        assertNoZeroLengthTimer(deadline: now.addingTimeInterval(500))
    }

    func testDeadlineAtMidnightSkipsEntryOnBoundary() {
        // 2026-10-25 00:00: next midnight is exactly 2-day boundary.
        let deadline = nextMidnight.addingTimeInterval(2 * 86_400)
        assertNoZeroLengthTimer(deadline: deadline)
        XCTAssertEqual(WidgetSchedule.entryDates(now: now, deadline: deadline, calendar: cal),
                       [now, nextMidnight.addingTimeInterval(1), nextMidnight.addingTimeInterval(86_401)])
    }

    func testNextMidnightAcrossDST() throws {
        // Berlin leaves CEST 2026-10-25 03:00, so that day has 25 hours.
        let evening = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 22)))
        let midnight = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 10, day: 25)))
        XCTAssertEqual(WidgetSchedule.entryDates(now: evening, deadline: nil, calendar: cal), [evening, midnight])
    }
}
