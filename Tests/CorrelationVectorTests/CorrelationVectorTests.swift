import XCTest

@testable import CorrelationVector

final class CorrelationVectorTests: XCTestCase {
  func testDefaultVersion() {
    let sut = CorrelationVector()
    XCTAssertEqual(sut.version, .v1)
  }

  func testIncrement() {
    let sut = CorrelationVector()
    XCTAssertEqual(0, sut.extension)
    let _ = sut.increment()
    XCTAssertEqual(1, sut.extension)
  }

  static var allTests = [
    ("defaultVersion", testDefaultVersion),
    ("increment", testIncrement),
  ]
}
