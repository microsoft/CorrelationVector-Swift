// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorV2Tests: XCTestCase {
  override func setUp() {
    CorrelationVector.validateDuringCreation = false
  }
  
  func testCreateCorrelationVectorFromStringV2() throws {
    let sut = try CorrelationVectorV2.extend("KZY+dsX2jEaZesgCPjJ2Ng.1")
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("KZY+dsX2jEaZesgCPjJ2Ng.1.1", sut.value)
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
    let sut = CorrelationVectorV2(uuid)
    XCTAssertEqual(0, sut.extension)
    sut.increment()
    let split = sut.value.split(separator: ".")
    let uuidString = uuid.uuidString
    let base64String = Data(uuidString.utf8).base64EncodedString();
    let endIndex = base64String.index(base64String.startIndex, offsetBy: 22);
    XCTAssertEqual(String(base64String[..<endIndex]), String(split[0]))
    XCTAssertEqual(1, sut.extension)
  }
  
  func testExtendOverMaxCVLengthV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2141"
    let sut = try CorrelationVectorV2.extend(baseVector)
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
  }
  
  func testImmutableCVWIthTerminatorV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.21474836479.0!"
    XCTAssertEqual(baseVector, try CorrelationVectorV2.extend(baseVector).value)
    XCTAssertEqual(baseVector, try CorrelationVectorV2.spin(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVectorV2.parse(baseVector).increment())
  }
  
  func testIncrementPastMaxWithNoErrorsV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.214"
    let sut = try CorrelationVectorV2.extend(baseVector)
    sut.increment()
    XCTAssertEqual(baseVector+".1", sut.value)
    for _ in 1...20 {
      sut.increment()
    }
    XCTAssertEqual(baseVector+".9!", sut.value)
  }
  
  func testSpinOverMaxCVLengthV2() throws {
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.214";
    let cv = try CorrelationVectorV2.spin(baseVector);
    XCTAssertEqual(baseVector + CorrelationVector.terminator, cv.value)
  }
  
  func testThrowWithTooBigCorrelationVectorValueV2() {
    let baseValue = "KZY+dsX2jEaZesgCPjJ2Ng"
    let baseValueWithExtension = "\(baseValue).2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647"
    CorrelationVector.validateDuringCreation = true;
    XCTAssertThrowsError(try CorrelationVectorV2.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      XCTAssertEqual(value, "The \(baseValueWithExtension) correlation vector can not be null or bigger than 127 characters")
    }
  }
  
  func testSpinSortValidationV2() throws {
    let sut = CorrelationVectorV2()
    let params = SpinParameters(interval: SpinCounterInterval.fine, periodicity: SpinCounterPeriodicity.short, entropy: SpinEntropy.two)
    var lastSpinValue : Int64 = 0;
    var wrappedCounter = 0;
    for _ in 0...100 {
      let cV2 = try CorrelationVectorV2.spin(sut.value, params)
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
    
    // The cV after a spin will look like <cvBase>.0.<spinValue>.0, so the spinValue
    // is at index = 2
    XCTAssertTrue(wrappedCounter <= 1)
  }
  
  static var allTests = [
    ("createCorrelationVectorFromStringV2", testCreateCorrelationVectorFromStringV2),
    ("createExtendAndIncrementCorrelationVectorV2", testCreateExtendAndIncrementCorrelationVectorV2),
    ("createExtendAndIncrementCorrelationVectorV2fromUuid", testCreateExtendAndIncrementCorrelationVectorV2fromUuid),
    ("extendOverMaxCVLengthV2", testExtendOverMaxCVLengthV2),
    ("immutableCVWithTerminatorV2", testImmutableCVWIthTerminatorV2),
    ("incrementPastMaxWithNoErrorsV2", testIncrementPastMaxWithNoErrorsV2),
    ("spinOverMaxCVLengthV2", testSpinOverMaxCVLengthV2),
    ("throwWithTooBigCorrelationVectorValueV2", testThrowWithTooBigCorrelationVectorValueV2),
    ("spinSortValidationV2", testSpinSortValidationV2),
  ]
}
