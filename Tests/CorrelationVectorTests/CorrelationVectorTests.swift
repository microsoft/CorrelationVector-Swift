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
  ]
}
