// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import XCTest

@testable import CorrelationVector

final class CorrelationVectorV2Tests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    CorrelationVector.validateDuringCreation = false
  }
  
  func testCreateFromString() throws {
    
    // If
    let sut = try CorrelationVectorV2.extend("KZY+dsX2jEaZesgCPjJ2Ng\(CorrelationVector.delimiter)1")
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    sut.increment()
    
    // Then
    let split = sut.value.split(separator: ".")
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("KZY+dsX2jEaZesgCPjJ2Ng\(CorrelationVector.delimiter)1\(CorrelationVector.delimiter)1", sut.value)
  }
  
  func testCreateExtendAndIncrement() throws {
    
    // If
    let sut = CorrelationVectorV2()
    XCTAssertEqual(sut.version, .v2)
    
    // When
    sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(22, split[0].count)
  }
  
  func testCreateExtendAndIncrementFromUuid() throws {
    
    // If
    let uuid = UUID.init()
    let sut = CorrelationVectorV2(uuid)
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    let uuidString = uuid.uuidString
    let base64String = Data(uuidString.utf8).base64EncodedString();
    let endIndex = base64String.index(base64String.startIndex, offsetBy: 22);
    XCTAssertEqual(String(base64String[..<endIndex]), String(split[0]))
    XCTAssertEqual(1, sut.extension)
  }
  
  func testExtendOverMaxLength() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647.2147483647.2147483647.2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2141"
    let sut = try CorrelationVectorV2.extend(baseVector)
    XCTAssertEqual(sut.version, .v2)
    
    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value);
  }
  
  func testImmutableWithTerminator() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)21474836479\(CorrelationVector.delimiter)0!"
    
    // Then
    XCTAssertEqual(baseVector, try CorrelationVectorV2.extend(baseVector).value)
    XCTAssertEqual(baseVector, try CorrelationVectorV2.spin(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVectorV2.parse(baseVector).increment())
  }
  
  func testIncrementPastMaxWithNoErrors() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)214"
    let sut = try CorrelationVectorV2.extend(baseVector)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    sut.increment()
    
    // Then
    XCTAssertEqual(baseVector+"\(CorrelationVector.delimiter)1", sut.value)
    
    // When
    for _ in 1...20 {
      sut.increment()
    }
    
    // Then
    XCTAssertEqual(baseVector+"\(CorrelationVector.delimiter)9\(CorrelationVector.terminator)", sut.value)
  }
  
  func testSpinOverMaxLength() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)214";
    
    // When
    let cv = try CorrelationVectorV2.spin(baseVector);
    
    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, cv.value)
  }
  
  func testThrowWithTooBigValue() {
    
    // If
    let baseValue = "KZY+dsX2jEaZesgCPjJ2Ng"
    let baseValueWithExtension = "\(baseValue).2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647\(CorrelationVector.delimiter)2147483647"
    CorrelationVector.validateDuringCreation = true;
    
    // When
    XCTAssertThrowsError(try CorrelationVectorV2.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "The \(baseValueWithExtension) correlation vector can not be null or bigger than 127 characters")
    }
  }
  
  func testSpinSortValidation() throws {
    
    // If
    let sut = CorrelationVectorV2()
    let params = SpinParameters(interval: SpinCounterInterval.fine, periodicity: SpinCounterPeriodicity.short, entropy: SpinEntropy.two)
    var lastSpinValue : Int64 = 0;
    var wrappedCounter = 0;
    
    // When
    for _ in 0...100 {
      let cV2 = try CorrelationVectorV2.spin(sut.value, params)
      let splitCv = cV2.value.split(separator: ".")
      let spinValue = Int64(splitCv[2])!
      
      // Count the number of times the counter wraps.
      if (spinValue <= lastSpinValue) {
        wrappedCounter += 1
      }
      lastSpinValue = spinValue
      
      // Wait for 10ms.
      usleep(10000)
    }
    
    // Then
    // The cV after a spin will look like <cvBase>.0.<spinValue>.0, so the spinValue
    // is at index = 2.
    XCTAssertTrue(wrappedCounter <= 1)
  }
  
  static var allTests = [
    ("createFromStringV2", testCreateFromString),
    ("createExtendAndIncrement", testCreateExtendAndIncrement),
    ("createExtendAndIncrementFromUuid", testCreateExtendAndIncrementFromUuid),
    ("extendOverMaxLength", testExtendOverMaxLength),
    ("immutableWithTerminator", testImmutableWithTerminator),
    ("incrementPastMaxWithNoErrors", testIncrementPastMaxWithNoErrors),
    ("spinOverMaxLength", testSpinOverMaxLength),
    ("throwWithTooBigValue", testThrowWithTooBigValue),
    ("spinSortValidation", testSpinSortValidation),
  ]
}
