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
  
  func testConvertFromVectorBaseToGuidBackToVectorBase() throws {
    
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
    
    for vectorBase in validGuidVectorBases
    {
      
      // When
      let correlationVector = CorrelationVector.parse("\(vectorBase).0")
      guard let baseAsGuid = try correlationVector.baseAsUUID() else { return XCTFail() }
      let correlationVectorFromGuid = CorrelationVectorV2(baseAsGuid)
      
      // Then
      XCTAssertEqual(correlationVector.value, correlationVectorFromGuid.value);
    }
    
  }
  
  func testImplicitV2Creation() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.1"
    let cv1 = CorrelationVector.parse(baseVector)
    let cv2 = try CorrelationVector.extend(baseVector)
    
    //Then
    XCTAssertEqual(cv1.version, .v2)
    XCTAssertEqual(cv2.version, .v2)
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
  
  func testIncrement() {
    
    // If
    let sut = CorrelationVector()
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    let _ = sut.increment()
    
    // Then
    XCTAssertEqual(1, sut.extension)
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
  
  func testExtendOverMaxLength() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.214748364.23"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v1)
    
    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
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
  
  func testImmutableWithTerminator() {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.21474836479.0!"
    
    // Then
    XCTAssertEqual(baseVector, try CorrelationVector.extend(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVector.parse(baseVector).increment())
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
    XCTAssertEqual("\(vectorBase).\(uintMax).1", sut.value)
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
    ("convertFromVectorBaseToGuidAndBack", testConvertFromVectorBaseToGuidBackToVectorBase),
    ("implicitV2Creation", testImplicitV2Creation),
    ("explicitVersionCreation", testExplicitVersionCreation),
    ("increment", testIncrement),
    ("incrementIsUniqueAcrossMultipleThreads", testIncrementIsUniqueAcrossMultipleThreads),
    ("createFromString", testCreateFromString),
    ("extendOverMaxLength", testExtendOverMaxLength),
    ("immutableWithTerminator", testImmutableWithTerminator),
    ("extendAndIncrementPastMaxWithNoErrors", testExtendAndIncrementPastMaxWithNoErrors),
    ("incrementPastMax", testIncrementPastMax),
    ("throwWithInsufficientCharsValue", testThrowWithInsufficientCharsValue),
    ("throwWithTooBigValue", testThrowWithTooBigValue),
    ("throwWithTooBigExtensionValue", testThrowWithTooBigExtensionValue),
    ("throwWithTooManyCharsValue", testThrowWithTooManyCharsValue)
  ]
}
