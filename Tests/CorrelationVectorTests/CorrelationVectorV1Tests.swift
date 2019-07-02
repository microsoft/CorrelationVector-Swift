// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorV1Tests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    CorrelationVector.validateDuringCreation = false
  }
  
  func testCreateExtendAndIncrement() throws {
    
    // If
    let sut = CorrelationVectorV1()
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(16, split[0].count)
  }
  
  func testSpinOverMaxLength() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)214748364\(CorrelationVector.delimiter)23";
    
    // When
    XCTAssertThrowsError(try CorrelationVector.spin(baseVector)) { error in
      guard case CorrelationVectorError.invalidOperation(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "Spin is not supported in Correlation Vector V1")
    }
  }
  
  static var allTests = [
    ("createExtendAndIncrement", testCreateExtendAndIncrement),
    ("spinOverMaxLength", testSpinOverMaxLength),
  ]
}
