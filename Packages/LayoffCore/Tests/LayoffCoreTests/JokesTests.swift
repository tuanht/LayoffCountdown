import XCTest
@testable import LayoffCore

final class JokesTests: XCTestCase {
    let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }()

    func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int = 0, _ mi: Int = 0) throws -> Date {
        try XCTUnwrap(cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi)))
    }

    func testJokesCountAndNoEmpty() {
        XCTAssertTrue((25...35).contains(Jokes.all.count))
        XCTAssertFalse(Jokes.all.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty })
        XCTAssertEqual(Set(Jokes.all).count, Jokes.all.count)
    }

    func testJokeStableWithinDayChangesNextDay() throws {
        let morning = Jokes.joke(for: try date(2026, 10, 22, 9), calendar: cal)
        XCTAssertEqual(Jokes.joke(for: try date(2026, 10, 22, 23, 59), calendar: cal), morning)
        XCTAssertNotEqual(Jokes.joke(for: try date(2026, 10, 23, 0, 1), calendar: cal), morning)
    }

    func testJokeIndexCountsDaysFromEpoch() throws {
        XCTAssertEqual(Jokes.joke(for: try date(2026, 1, 1, 12), calendar: cal), Jokes.all[0])
        XCTAssertEqual(Jokes.joke(for: try date(2026, 1, 2), calendar: cal), Jokes.all[1])
    }

    func testJokeBeforeEpochWrapsNonNegative() throws {
        XCTAssertEqual(Jokes.joke(for: try date(2025, 12, 31, 12), calendar: cal), Jokes.all.last)
    }

    func testFarewell() {
        XCTAssertEqual(Jokes.farewell, "Goodbye. Hand in your laptop on the way out.")
    }

    func testJokeAdvancesOneIndexAcrossDST() throws {
        for (y, mo, d) in [(2026, 10, 25), (2026, 3, 29)] {
            let before = try XCTUnwrap(Jokes.all.firstIndex(of: Jokes.joke(for: try date(y, mo, d, 12), calendar: cal)))
            let after = try XCTUnwrap(Jokes.all.firstIndex(of: Jokes.joke(for: try date(y, mo, d + 1, 12), calendar: cal)))
            XCTAssertEqual(after, (before + 1) % Jokes.all.count, "\(y)-\(mo)-\(d)")
        }
    }
}
