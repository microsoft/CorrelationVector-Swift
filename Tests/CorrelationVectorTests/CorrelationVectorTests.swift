// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorTests: XCTestCase {
  func testDefaultVersion() {
    let sut = CorrelationVector()
    XCTAssertEqual(sut.version, .v1)
  }

  override func setUp() {
    super.setUp()
    CorrelationVector.validateDuringCreation = false
  }
  
  func testIncrement() {
    let sut = CorrelationVector()
    XCTAssertEqual(0, sut.extension)
    let _ = sut.increment()
    XCTAssertEqual(1, sut.extension)
  }
  
  func testCreateCorrelationVectorFromString() throws {
    let sut = try CorrelationVector.extend("tul4NUsfs9Cl7mOf.1")
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("tul4NUsfs9Cl7mOf.1.1", sut.value)
  }
  
  func testExtendOverMaxCVLength() throws {
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.214748364.23"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
  }
  
  func testExctendNullCorrelationVector() throws {
    let nullString = ""
    let sut = try CorrelationVector.extend(nullString)
    XCTAssertEqual(".0", sut.value)
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(nullString)) {
      error in guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "The  correlation vector can not be null or bigger than 63 characters")
    }
  }
  
  func testImmutableCVWithTerminator() {
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.21474836479.0!"
    XCTAssertEqual(baseVector, try CorrelationVector.extend(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVector.parse(baseVector).increment())
  }
  
  func testIncrementPastMaxWithNoErrors() throws {
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.21474836479"
    let sut = try CorrelationVector.extend(baseVector)
    sut.increment()
    XCTAssertEqual(baseVector+".1", sut.value)
    for i in 1...20 {
      sut.increment()
    }
    XCTAssertEqual(baseVector+".9!", sut.value)
  }
  
  func testSpinOverMaxCVLength() throws {
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.214748364.23";
    XCTAssertThrowsError(try CorrelationVector.spin(baseVector)) { error in
      guard case CorrelationVectorError.invalidOperation(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "Spin is not supported in Correlation Vector V1")
    }
  }
  
  func testSpinSortValidation() throws {
    let sut = CorrelationVector()
    let params = SpinParameters(interval: SpinCounterInterval.fine, periodicity: SpinCounterPeriodicity.short, entropy: SpinEntropy.two)
    
    var lastSpinValue : Int64 = 0;
    var wrappedCounter = 0;
    
    for _ in 0...100 {
      let cV2 = try CorrelationVector.spin(sut.value, params)
      
      // The cV after a spin will look like <cvBase>.0.<spinValue>.0, so the spinValue
      // is at index = 2
      let splitCv = cV2.value.split(separator: ".")
      let spinValue = Int64(splitCv[2])!
      
      // Count the number of times the counter wraps.
      if (spinValue <= lastSpinValue) {
        wrappedCounter += 1
      }
      lastSpinValue = spinValue
      
      //Wait for 10ms
      usleep(10000)
    }
    
  }
  
  func testThrowWithInsufficientCharsCorrelationVectorValue() {
    let baseValue = "tul4NUsfs9Cl7mO"
    let baseValueWithExtension = "\(baseValue).1"
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "Invalid correlation vector \(baseValueWithExtension). Invalid base value \(baseValue)")
    }
  }
  
  func testThrowWithTooBigCorrelationVectorValue() {
    let baseValue = "tul4NUsfs9Cl7mOf"
    let baseValueWithExtension = "\(baseValue).2147483647.2147483647.2147483647.2147483647.2147483647"
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "The \(baseValueWithExtension) correlation vector can not be null or bigger than 63 characters")
    }
  }
  
  func testThrowWithTooBigExtensionCorrelationVectorValue() {
    let baseValue = "tul4NUsfs9Cl7mOf"
    let baseValueWithExtension = "\(baseValue).11111111111111111111111111111"
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "Invalid correlation vector \(baseValueWithExtension). Invalid base value \(baseValue)")
    }
  }
  
  func testThrowWithTooManyCharsCorrelationVectorValue() throws {
    let baseValue = "tul4NUsfs9Cl7mOfN/dupsl"
    let baseValueWithExtension = "\(baseValue).1"
    let sut = try CorrelationVector.extend(baseValueWithExtension)
    XCTAssertEqual(0, sut.extension)
    
    //Enable validation
    CorrelationVector.validateDuringCreation = true
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "Invalid correlation vector \(baseValueWithExtension). Invalid base value \(baseValue)")
    }
  }
  
  static var allTests = [
    ("defaultVersion", testDefaultVersion),
    ("increment", testIncrement),
    ("createCorrelationVectorFromString", testCreateCorrelationVectorFromString),
    ("extendOverMaxCVLength", testExtendOverMaxCVLength),
    ("immutableCVWithTerminator", testImmutableCVWithTerminator),
    ("incrementPastMaxWithNoErrors", testIncrementPastMaxWithNoErrors),
    ("spinOverMaxCVLength", testSpinOverMaxCVLength),
    ("spinSortValidation", testSpinSortValidation),
    ("throwWithInsufficientCharsCorrelationVectorValue", testThrowWithInsufficientCharsCorrelationVectorValue),
    ("throwWithTooBigCorrelationVectorValue", testThrowWithTooBigCorrelationVectorValue),
    ("throwWithTooBigExtensionCorrelationVectorValue", testThrowWithTooBigExtensionCorrelationVectorValue),
    ("throwWithTooManyCharsCorrelationVectorValue", testThrowWithTooManyCharsCorrelationVectorValue)
  ]
}
