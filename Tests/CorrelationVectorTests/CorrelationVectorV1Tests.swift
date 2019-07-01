// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorV1Tests: XCTestCase {
  func testCreateExtendAndIncrementCorrelationVectorV1() throws {
    let sut = CorrelationVectorV1()
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(16, split[0].count)
  }
  
  static var allTests = [
    ("createExtendAndIncrementCorrelationVectorV1", testCreateExtendAndIncrementCorrelationVectorV1),
  ]
}
