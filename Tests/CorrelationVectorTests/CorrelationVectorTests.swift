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
  
  func testBase() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf"
    let sut = try CorrelationVector.extend(baseVector)
    
    // Then
    XCTAssertEqual(sut.version, .v1)
    XCTAssertEqual(sut.value, "\(baseVector)\(CorrelationVector.delimiter)0")
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
  
  func testCreateFromString() throws {
    
    // If
    let sut = try CorrelationVector.extend("tul4NUsfs9Cl7mOf\(CorrelationVector.delimiter)1")
    XCTAssertEqual(sut.version, .v1)
    XCTAssertEqual(sut.extension, 0)
    
    // When
    sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("tul4NUsfs9Cl7mOf\(CorrelationVector.delimiter)1\(CorrelationVector.delimiter)1", sut.value)
  }
  
  func testExtendOverMaxLength() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)214748364\(CorrelationVector.delimiter)23"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v1)
    
    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
  }
  
  func testExtendNull() throws {
    
    // If
    let nullString = ""
    let sut = try CorrelationVector.extend(nullString)
    XCTAssertEqual(sut.value, "\(CorrelationVector.delimiter)0")
    XCTAssertEqual(sut.version, .v1)
    
    // When
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(nullString)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "The correlation vector can not be null or bigger than 63 characters")
    }
  }
  
  func testImmutableWithTerminator() {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)21474836479\(CorrelationVector.delimiter)0\(CorrelationVector.terminator)"
    
    // Then
    XCTAssertEqual(baseVector, try CorrelationVector.extend(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVector.parse(baseVector).increment())
  }
  
  func testIncrementPastMaxWithNoErrors() throws {
    
    // If
    let baseVector = "tul4NUsfs9Cl7mOf\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)21474836479"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v1)
    
    // When
    sut.increment()
    
    // Then
    XCTAssertEqual(baseVector + "\(CorrelationVector.delimiter)1", sut.value)
    
    // When
    for _ in 1...20 {
      sut.increment()
    }
    
    // Then
    XCTAssertEqual(baseVector+"\(CorrelationVector.delimiter)9\(CorrelationVector.terminator)", sut.value)
  }
  
  func testThrowWithInsufficientCharsValue() {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mO"
    let baseValueWithExtension = "\(baseValue)\(CorrelationVector.delimiter)1"
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
  
  func testThrowWithTooBigValue() {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mOf"
    let baseValueWithExtension = "\(baseValue)\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647"
    CorrelationVector.validateDuringCreation = true;
    
    // When
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "The \(baseValueWithExtension) correlation vector can not be null or bigger than 63 characters")
    }
  }
  
  func testThrowWithTooBigExtensionValue() {
    
    // If
    let baseValue = "tul4NUsfs9Cl7mOf"
    let baseValueWithExtension = "\(baseValue)\(CorrelationVector.delimiter)11111111111111111111111111111"
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
    let baseValueWithExtension = "\(baseValue)\(CorrelationVector.delimiter)1"
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
    ("increment", testIncrement),
    ("createFromString", testCreateFromString),
    ("extendOverMaxLength", testExtendOverMaxLength),
    ("immutableWithTerminator", testImmutableWithTerminator),
    ("incrementPastMaxWithNoErrors", testIncrementPastMaxWithNoErrors),
    ("throwWithInsufficientCharsValue", testThrowWithInsufficientCharsValue),
    ("throwWithTooBigValue", testThrowWithTooBigValue),
    ("throwWithTooBigExtensionValue", testThrowWithTooBigExtensionValue),
    ("throwWithTooManyCharsValue", testThrowWithTooManyCharsValue)
  ]
}
