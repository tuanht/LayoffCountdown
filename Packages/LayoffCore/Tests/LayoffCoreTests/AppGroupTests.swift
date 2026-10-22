import XCTest
@testable import LayoffCore

final class AppGroupTests: XCTestCase {
    func testIdentifierValidation() {
        XCTAssertNil(AppGroup.identifier(from: nil))
        XCTAssertNil(AppGroup.identifier(from: ""))
        XCTAssertNil(AppGroup.identifier(from: ".com.layoffcountdown.shared"))       // no team set
        XCTAssertNil(AppGroup.identifier(from: "$(DEVELOPMENT_TEAM).com.x"))          // unexpanded
        XCTAssertEqual(AppGroup.identifier(from: "AB12CD34EF.com.layoffcountdown.shared"),
                       "AB12CD34EF.com.layoffcountdown.shared")
    }
}
