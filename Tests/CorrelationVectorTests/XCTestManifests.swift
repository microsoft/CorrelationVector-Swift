import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CorrelationVectorTests.allTests),
        testCase(CorrelationVectorV1Tests.allTests),
        testCase(CorrelationVectorV2Tests.allTests),
    ]
}
#endif
