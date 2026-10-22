import XCTest
@testable import LayoffCore

final class ProgressTests: XCTestCase {
    func t(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }

    func testProgressMidway() {
        XCTAssertEqual(NoticeProgress.fraction(start: t(0), deadline: t(100), now: t(50)), 0.5)
    }

    func testProgressClamps() {
        XCTAssertEqual(NoticeProgress.fraction(start: t(0), deadline: t(100), now: t(-10)), 0)
        XCTAssertEqual(NoticeProgress.fraction(start: t(0), deadline: t(100), now: t(150)), 1)
    }

    func testProgressStartAfterDeadline() {
        let dl = Date(timeIntervalSince1970: 1000)
        XCTAssertEqual(NoticeProgress.fraction(start: dl.addingTimeInterval(10), deadline: dl, now: dl.addingTimeInterval(-50)), 1.0)
        XCTAssertEqual(NoticeProgress.fraction(start: dl, deadline: dl, now: dl.addingTimeInterval(-50)), 1.0)
    }

    func testProgressWithoutStartIsFull() {
        XCTAssertEqual(NoticeProgress.fraction(start: nil, deadline: t(100), now: t(50)), 1.0)
    }
}
