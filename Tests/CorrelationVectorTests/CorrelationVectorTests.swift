import XCTest
@testable import CorrelationVector

final class CorrelationVectorTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CorrelationVector().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
