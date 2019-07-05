// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorV1Tests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    CorrelationVector.validateDuringCreation = false
  }

  func testCreateFromString() throws {

    // If
    let sut = try CorrelationVector.extend("tul4NUsfs9Cl7mOf.1")
    XCTAssertEqual(sut.version, .v1)
    XCTAssertEqual(sut.extension, 0)

    // When
    let _ = sut.increment()

    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("tul4NUsfs9Cl7mOf.1.1", sut.value)
  }

  func testGetBaseAsUuidTest(){

    // If
    let cV = CorrelationVector()

    // When
    XCTAssertThrowsError(try cV.baseAsUUID()) { error in
      guard case CorrelationVectorError.invalidOperation(let value) = error else {
        return XCTFail()
      }

      // Then
      XCTAssertEqual(value, "Cannot convert a V1 correlation vector base to a UUID.")
    }
  }

  func testExtendOverMaxLength() throws {

    // If
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.214748364.23"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v1)

    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
  }

  func testExtendAndIncrementPastMaxWithNoErrors() throws {

    // If
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.21474836479"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v1)

    // When
    let _ = sut.increment()

    // Then
    XCTAssertEqual(baseVector + ".1", sut.value)

    // When
    for _ in 1...20 {
      let _ = sut.increment()
    }

    // Then
    XCTAssertEqual(baseVector+".9!", sut.value)
  }

  func testIncrementPastMax() throws {

    // If
    let vectorBase = "tul4NUsfs9Cl7mOf"
    let uintMax = 0xFF_FF_FF_FF
    let baseVector = "\(vectorBase).\(uintMax)"
    let sut = CorrelationVector.parse(baseVector)
    XCTAssertEqual(sut.version, .v1)

    // When
    let _ = sut.increment()

    // Then
    XCTAssertEqual("\(vectorBase).\(uintMax)", sut.value)
  }

  func testCreateExtendAndIncrement() throws {
    
    // If
    let sut = CorrelationVector()
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    let _ = sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(16, split[0].count)
  }
  
  func testSpinOverMaxLength() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.214748364.23";
    
    // When
    XCTAssertThrowsError(try CorrelationVector.spin(baseVector)) { error in
      guard case CorrelationVectorError.invalidOperation(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "Spin is not supported in Correlation Vector V1")
    }
  }

  func testImmutableWithTerminator() {

    // If
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.21474836479.0!"

    // Then
    XCTAssertEqual(baseVector, try CorrelationVector.extend(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVector.parse(baseVector).increment())
  }

  static var allTests = [
    ("createFromString", testCreateFromString),
    ("getBaseAsUuidTest", testGetBaseAsUuidTest),
    ("extendOverMaxLength", testExtendOverMaxLength),
    ("extendAndIncrementPastMaxWithNoErrors", testExtendAndIncrementPastMaxWithNoErrors),
    ("immutableWithTerminator", testImmutableWithTerminator),
    ("incrementPastMax", testIncrementPastMax),
    ("createExtendAndIncrement", testCreateExtendAndIncrement),
    ("spinOverMaxLength", testSpinOverMaxLength),
  ]
}
