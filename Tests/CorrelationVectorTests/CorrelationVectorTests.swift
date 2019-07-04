// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    CorrelationVector.validateDuringCreation = false
  }
  
  func testDefaultVersion() {
    
    // If
    let sut = CorrelationVector()
    
    // Then
    XCTAssertEqual(sut.version, .v1)
  }

  func testGetBaseAsUuidForInvalidUuidVectorBase() throws {

    // If
    // CV base which has four non-zero least significant bits meaning conversion to Uuid will lose information.
    // CV Base -> Uuid -> CV Base conversion results in:
    //   /////////////////////B -> ffffffff-ffff-ffff-ffff-fffffffffffc -> /////////////////////A
    let vectorBase = "/////////////////////B";
    let vectorBaseUuid = UUID(uuidString: "ffffffff-ffff-ffff-ffff-fffffffffffc")
    let correlationVector = CorrelationVector.parse("\(vectorBase).0")

    // When
    let baseAsUuid = try correlationVector.baseAsUUID()

    // Then
    XCTAssertEqual(vectorBaseUuid, baseAsUuid)

    // When
    CorrelationVector.validateDuringCreation = true
    XCTAssertThrowsError(try correlationVector.baseAsUUID()) { error in
      guard case CorrelationVectorError.invalidOperation(let value) = error else {
        return XCTFail()
      }

      // Then
      XCTAssertEqual(value, "The four least significant bits of the base64 encoded vector base must be zeros to reliably convert to a UUID.")
    }
  }

  func testConvertFromVectorBaseToUuidBackToVectorBase() throws {

    // If
    // CV bases which have four zero least significant bits meaning a conversion to a Guid will retain all
    // information.
    // CV Base -> Guid -> CV Base conversions result in:
    //   /////////////////////A -> ffffffff-ffff-ffff-ffff-fffffffffffc -> /////////////////////A
    //   /////////////////////Q -> ffffffff-ffff-ffff-ffff-fffffffffffd -> /////////////////////Q
    //   /////////////////////g -> ffffffff-ffff-ffff-ffff-fffffffffffe -> /////////////////////g
    //   /////////////////////w -> ffffffff-ffff-ffff-ffff-ffffffffffff -> /////////////////////w
    let validGuidVectorBases = ["/////////////////////A",
                                "/////////////////////Q",
                                "/////////////////////g",
                                "/////////////////////w"]
    
    for vectorBase in validGuidVectorBases {

      // When
      let correlationVector = CorrelationVector.parse("\(vectorBase).0")
      guard let baseAsGuid = try correlationVector.baseAsUUID() else { return XCTFail() }
      let correlationVectorFromGuid = CorrelationVectorV2(baseAsGuid)

      // Then
      XCTAssertEqual(correlationVector.value, correlationVectorFromGuid.value);
    }
  }

  func testExplicitVersionCreation() throws {
    
    // If
    let cv1 = CorrelationVector(.v1)
    let cv2 = CorrelationVector(.v2)
    
    // Then
    XCTAssertEqual(cv1.version, .v1)
    XCTAssertEqual(cv2.version, .v2)
  }
  
  func testBase() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf"
    let sut = try CorrelationVector.extend(baseVector)
    
    // Then
    XCTAssertEqual(sut.version, .v1)
    XCTAssertEqual(sut.value, "\(baseVector).0")
    XCTAssertEqual(sut.base, baseVector)
  }
  
  func testIncrement() throws {
    
    // If
    let vectorBase = "tul4NUsfs9Cl7mOf"
    let sut = try CorrelationVector.extend(vectorBase)
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    let increment = sut.increment()
    
    // Then
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("\(vectorBase).1", increment)
  }
  
  func testIncrementIsUniqueAcrossMultipleThreads() {
    
    // If
    let sut = CorrelationVector()
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    let queue = DispatchQueue(label: "cv.increment", qos: .utility, attributes: .concurrent)
    for i in 0..<100 {
      let expectation = self.expectation(description: "\(#function):\(i)")
      queue.async {
        for _ in 0..<10_000 {
          let _ = sut.increment()
        }
        expectation.fulfill()
      }
    }
    
    // Then
    waitForExpectations(timeout: 10)
    XCTAssertEqual(1_000_000, sut.extension)
  }

  func testExtendNull() throws {
    
    // If
    let emptyString = ""
    let sut = try CorrelationVector.extend(emptyString)
    XCTAssertEqual(sut.value, ".0")
    XCTAssertEqual(sut.version, .v1)
    
    // When
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(emptyString)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "The correlation vector can not be null or bigger than 63 characters")
    }
  }
  
  func testThrowWithInsufficientCharsValue() {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mO"
    let baseValueWithExtension = "\(baseValue).1"
    CorrelationVector.validateDuringCreation = true
    
    // When
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "Invalid correlation vector \(baseValueWithExtension). Invalid base value \(baseValue)")
    }
  }
  
  func testThrowWithTooBigValue() {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mOf"
    let baseValueWithExtension = "\(baseValue).2147483647.2147483647.2147483647.2147483647.2147483647"
    CorrelationVector.validateDuringCreation = true;
    
    // When
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "The correlation vector can not be null or bigger than 63 characters")
    }
  }
  
  func testThrowWithTooBigExtensionValue() {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mOf"
    let baseValueWithExtension = "\(baseValue).11111111111111111111111111111"
    CorrelationVector.validateDuringCreation = true;
    
    // When
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "Invalid correlation vector \(baseValueWithExtension). Invalid base value \(baseValue)")
    }
  }
  
  func testThrowWithTooManyCharsValue() throws {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mOfN/dupsl"
    let baseValueWithExtension = "\(baseValue).1"
    let sut = try CorrelationVector.extend(baseValueWithExtension)
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    CorrelationVector.validateDuringCreation = true
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "Invalid correlation vector \(baseValueWithExtension). Invalid base value \(baseValue)")
    }
  }
  
  static var allTests = [
    ("defaultVersion", testDefaultVersion),
    ("convertFromVectorBaseToUuidAndBack", testConvertFromVectorBaseToUuidBackToVectorBase),
    ("explicitVersionCreation", testExplicitVersionCreation),
    ("increment", testIncrement),
    ("incrementIsUniqueAcrossMultipleThreads", testIncrementIsUniqueAcrossMultipleThreads),
    ("throwWithInsufficientCharsValue", testThrowWithInsufficientCharsValue),
    ("throwWithTooBigValue", testThrowWithTooBigValue),
    ("throwWithTooBigExtensionValue", testThrowWithTooBigExtensionValue),
    ("throwWithTooManyCharsValue", testThrowWithTooManyCharsValue)
  ]
}
