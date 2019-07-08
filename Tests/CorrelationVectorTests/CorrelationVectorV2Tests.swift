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
    let sut = try CorrelationVector.extend("KZY+dsX2jEaZesgCPjJ2Ng.1")
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    let _ = sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(3, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual("KZY+dsX2jEaZesgCPjJ2Ng.1.1", sut.value)
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

  func testGetBaseAsUuidTest() throws {

    // If
    let uuid = UUID.init()

    // When
    let cV = CorrelationVector(uuid)
    let actualUuid = try cV.baseAsUUID()

    // Then
    XCTAssertEqual(uuid, actualUuid)
  }

  func testCreateIncrement() throws {
    
    // If
    let sut = CorrelationVector(.v2)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    let _ = sut.increment()
    
    // Then
    let split = sut.value.split(separator: CorrelationVector.delimiter)
    XCTAssertEqual(2, split.count)
    XCTAssertEqual(1, sut.extension)
    XCTAssertEqual(22, split[0].count)
  }
  
  func testCreateIncrementFromUuid() throws {
    
    // If
    let uuid = UUID(uuidString: "C1F00B9C-0076-437A-8BA9-4E230EB2C87A")
    let sut = CorrelationVector(uuid!)
    XCTAssertEqual(sut.extension, 0)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    let _ = sut.increment()
    
    // Then
    XCTAssertEqual(uuid, try sut.baseAsUUID())
    XCTAssertEqual(1, sut.extension)
  }
  
  func testExtendOverMaxLength() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2141"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v2)
    
    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, sut.value)
  }
  
  func testImmutableWithTerminator() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.21474836479.0!"
    
    // Then
    XCTAssertEqual(baseVector, try CorrelationVector.extend(baseVector).value)
    XCTAssertEqual(baseVector, try CorrelationVector.spin(baseVector).value)
    XCTAssertEqual(baseVector, CorrelationVector.parse(baseVector).increment())
  }
  
  func testIncrementPastMaxWithNoErrors() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.214"
    let sut = try CorrelationVector.extend(baseVector)
    XCTAssertEqual(sut.version, .v2)
    
    // When
    let _ = sut.increment()
    
    // Then
    XCTAssertEqual(baseVector+".1", sut.value)
    
    // When
    for _ in 1...20 {
      let _ = sut.increment()
    }
    
    // Then
    XCTAssertEqual(baseVector+".9!", sut.value)
  }
  
  func testSpinOverMaxLength() throws {
    
    // If
    let baseVector = "KZY+dsX2jEaZesgCPjJ2Ng.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.214"
    
    // When
    let cv = try CorrelationVector.spin(baseVector)
    
    // Then
    XCTAssertEqual(baseVector + CorrelationVector.terminator, cv.value)
  }
  
  func testThrowWithTooBigValue() {
    
    // If
    let baseValue = "KZY+dsX2jEaZesgCPjJ2Ng"
    let baseValueWithExtension = "\(baseValue).2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647.2147483647"
    CorrelationVector.validateDuringCreation = true
    
    // When
    XCTAssertThrowsError(try CorrelationVector.extend(baseValueWithExtension)) { error in
      guard case CorrelationVectorError.invalidArgument(let value) = error else {
        return XCTFail()
      }
      
      // Then
      XCTAssertEqual(value, "The correlation vector can not be null or bigger than 127 characters")
    }
  }
  
  func testSpinSortValidation() throws {
    
    // If
    let sut = CorrelationVector(.v2)
    let params = SpinParameters(interval: SpinCounterInterval.fine, periodicity: SpinCounterPeriodicity.short, entropy: SpinEntropy.two)
    var lastSpinValue : Int64 = 0
    var wrappedCounter = 0
    
    // When
    for _ in 0...100 {
      let cV2 = try CorrelationVector.spin(sut.value, params)
      let splitCv = cV2.value.split(separator: CorrelationVector.delimiter)
      let spinValue = Int64(splitCv[2])!
      
      // Count the number of times the counter wraps.
      if (spinValue <= lastSpinValue) {
        wrappedCounter += 1
      }
      lastSpinValue = spinValue

      // Spin depends on processor ticks. We need usleep() to make spin values unique, there will be a collision otherwise.
      usleep(10000)
    }
    
    // Then
    // The cV after a spin will look like <cvBase>.0.<spinValue>.0, so the spinValue
    // is at index = 2.
    XCTAssertLessThanOrEqual(wrappedCounter, 1)
  }
  
  static var allTests = [
    ("createFromString", testCreateFromString),
    ("implicitV2Creation", testImplicitV2Creation),
    ("getBaseAsUuidTest", testGetBaseAsUuidTest),
    ("createIncrement", testCreateIncrement),
    ("createIncrementFromUuid", testCreateIncrementFromUuid),
    ("extendOverMaxLength", testExtendOverMaxLength),
    ("immutableWithTerminator", testImmutableWithTerminator),
    ("incrementPastMaxWithNoErrors", testIncrementPastMaxWithNoErrors),
    ("spinOverMaxLength", testSpinOverMaxLength),
    ("throwWithTooBigValue", testThrowWithTooBigValue),
    ("spinSortValidation", testSpinSortValidation),
  ]
}
