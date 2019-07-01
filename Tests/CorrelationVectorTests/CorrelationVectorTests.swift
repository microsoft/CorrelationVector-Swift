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
  
  func testCreateCorrelationVectorFromString() throws {
    let sut = try CorrelationVector.extend("tul4NUsfs9Cl7mOf.1")
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("tul4NUsfs9Cl7mOf.1.1", sut.value)
  }

  func testCreateCorrelationVectorFromStringV2() throws {
    let sut = try CorrelationVector.extend("KZY+dsX2jEaZesgCPjJ2Ng.1")
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("KZY+dsX2jEaZesgCPjJ2Ng.1.1", sut.value)
  }
  
  func testCreateExtendAndIncrementCorrelationVectorV1() throws {
    let sut = CorrelationVectorV1()
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(16, split[0].count)
  }
  
  func testCreateExtendAndIncrementCorrelationVectorV2() throws {
    let sut = CorrelationVectorV2()
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(22, split[0].count)
  }
  
  func testCreateExtendAndIncrementCorrelationVectorV2fromUuid() throws {
    let uuid = UUID.init()
    let sut = CorrelationVector(uuid)
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    let uuidString = uuid.uuidString
    let base64String = Data(uuidString.utf8).base64EncodedString();
    let endIndex = base64String.index(base64String.startIndex, offsetBy: 22);
    XCTAssertEqual(String(base64String[..<endIndex]), String(split[0]))
    XCTAssertEqual(1, sut.extension)
  }
  
  func testExtendOverMaxCVLength() throws {
    let baseVector = "tul4NUsfs9Cl7mOf.2147483647.2147483647.2147483647.214748364.23"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
  }
  
  func testExtendOverMaxCVLengthV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2141"
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
 
  func testImmutableCVWIthTerminatorV2() {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.21474836479.0!"
    XCTAssertEqual(baseVector, try CorrelationVector.extend(baseVector).value)
    XCTAssertEqual(baseVector, try CorrelationVector.spin(baseVector).value)
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
  
  func testIncrementPastMaxWithNoErrorsV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.214"
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
    
    //todo: Java doesn't throw error on this test
    //let cv = try CorrelationVector.spin(baseVector);
    //XCTAssertEqual(baseVector + CorrelationVector.terminator, cv.value)
    
    XCTAssertThrowsError(try CorrelationVector.spin(baseVector)) { error in
      guard case CorrelationVectorError.invalidOperation(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "Spin is not supported in Correlation Vector V1")
    }
  }
  
  func testSpinOverMaxCVLengthV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.214";
    let cv = try CorrelationVector.spin(baseVector);
    XCTAssertEqual(baseVector + CorrelationVector.terminator, cv.value)
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
  
  func testThrowWithTooBigCorrelationVectorValueV2() {
    let baseValue = "KZY+dsX2jEaZesgCPjJ2Ng"
    let baseValueWithExtension = "\(baseValue).2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647"
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "The \(baseValueWithExtension) correlation vector can not be null or bigger than 127 characters")
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
    ("createCorrelationVectorFromStringV2", testCreateCorrelationVectorFromStringV2),
    ("createExtendAndIncrementCorrelationVectorV1", testCreateExtendAndIncrementCorrelationVectorV1),
    ("createExtendAndIncrementCorrelationVectorV2", testCreateExtendAndIncrementCorrelationVectorV2),
    ("createExtendAndIncrementCorrelationVectorV2fromUuid", testCreateExtendAndIncrementCorrelationVectorV2fromUuid),
    ("extendOverMaxCVLength", testExtendOverMaxCVLength),
    ("extendOverMaxCVLength", testExtendOverMaxCVLengthV2),
    ("immutableCVWithTerminator", testImmutableCVWithTerminator),
    ("immutableCVWithTerminatorV2", testImmutableCVWIthTerminatorV2),
    ("incrementPastMaxWithNoErrors", testIncrementPastMaxWithNoErrors),
    ("incrementPastMaxWithNoErrorsV2", testIncrementPastMaxWithNoErrorsV2),
    ("spinOverMaxCVLength", testSpinOverMaxCVLength),
    ("spinOverMaxCVLengthV2", testSpinOverMaxCVLengthV2),
    ("spinSortValidation", testSpinSortValidation),
    ("throwWithInsufficientCharsCorrelationVectorValue", testThrowWithInsufficientCharsCorrelationVectorValue),
    ("throwWithTooBigCorrelationVectorValue", testThrowWithTooBigCorrelationVectorValue),
    ("throwWithTooBigCorrelationVectorValueV2", testThrowWithTooBigCorrelationVectorValueV2),
    ("throwWithTooBigExtensionCorrelationVectorValue", testThrowWithTooBigExtensionCorrelationVectorValue),
    ("throwWithTooManyCharsCorrelationVectorValue", testThrowWithTooManyCharsCorrelationVectorValue)
  ]
}
