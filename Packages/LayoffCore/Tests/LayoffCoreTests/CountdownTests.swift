import XCTest
@testable import LayoffCore

final class CountdownTests: XCTestCase {
    let d = 86_400.0, h = 3_600.0, m = 60.0

    func testShort() {
        XCTAssertEqual(CountdownFormatter.short(23*d + 4*h + 17*m + 52), "23d 4h")
        XCTAssertEqual(CountdownFormatter.short(4*h + 17*m + 52), "4h 17m")
        XCTAssertEqual(CountdownFormatter.short(17*m + 52), "17m 52s")
        XCTAssertEqual(CountdownFormatter.short(0.4), "0m 0s")
    }

    func testFull() {
        XCTAssertEqual(CountdownFormatter.full(23*d + 4*h + 17*m + 52), "23d 4:17:52")
        XCTAssertEqual(CountdownFormatter.full(4*h + 17*m + 52), "0d 4:17:52")
        XCTAssertEqual(CountdownFormatter.full(2*d + 17*m + 52), "2d 17:52")
        XCTAssertEqual(CountdownFormatter.full(5), "0d 0:05")
    }

    func testRemainingIsFloored() {
        XCTAssertEqual(CountdownFormatter.short(23*d + 4*h + 59*m + 59.9), "23d 4h")
        XCTAssertEqual(CountdownFormatter.full(59.9), "0d 0:59")
    }

    func testPastDeadlineIsDone() {
        let now = Date()
        XCTAssertEqual(CountdownState.make(deadline: now.addingTimeInterval(-5), now: now), .done)
        XCTAssertEqual(CountdownState.make(deadline: nil, now: now), .notSet)
    }

    func testExactlyZeroIsDone() {
        let now = Date()
        XCTAssertEqual(CountdownState.make(deadline: now, now: now), .done)
    }

    func testMenuBarTitle() {
        let r = 23*d + 4*h + 17*m + 52
        XCTAssertEqual(CountdownFormatter.menuBarTitle(state: .counting(remaining: r), style: .short, emoji: "💀"), "💀 23d 4h")
        XCTAssertEqual(CountdownFormatter.menuBarTitle(state: .counting(remaining: r), style: .full, emoji: "💀"), "💀 23d 4:17:52")
        XCTAssertEqual(CountdownFormatter.menuBarTitle(state: .notSet, style: .short, emoji: "🪦"), "🪦 Set date")
        XCTAssertEqual(CountdownFormatter.menuBarTitle(state: .done, style: .full, emoji: "💀"), "💀 Goodbye")
    }

    // Days are 86,400 s, not calendar days: across a DST fall-back the day digit flips an hour off wall-clock.
    // Intended, so menu bar and widget agree. Don't switch to calendar days.
    func testDayIsFixedSecondsAcrossDST() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Berlin"))
        // Berlin leaves CEST at 03:00 on 2026-10-25, so this span is 2 wall-clock days but 49 hours.
        let now = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 17)))
        let deadline = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 10, day: 26, hour: 17)))

        guard case .counting(let remaining) = CountdownState.make(deadline: deadline, now: now) else {
            return XCTFail("expected counting")
        }
        XCTAssertEqual(CountdownFormatter.full(remaining), "2d 1:00:00")
    }
}
