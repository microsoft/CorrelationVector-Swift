import XCTest

@testable import CorrelationVector

final class CorrelationVectorTests: XCTestCase {
  func defaultVersion() {
    let sut = CorrelationVector()
    XCTAssertEqual(sut.version, .v1)
  }

  static var allTests = [
    ("defaultVersion", defaultVersion),
  ]
}
