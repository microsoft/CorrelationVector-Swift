import Foundation

@objc class CorrelationVectorV1: NSObject, CorrelationVectorProtocol {
  var value: String = ""

  var base: String = ""

  var version: CorrelationVectorVersion {
    return .v1
  }

  required override init() {
  }

  required init(_ vectorBase: UUID) {
  }

  func increment() -> String {
    return ""
  }

  static func parse(_ correlationVector: String) -> CorrelationVectorProtocol {
    return CorrelationVector()
  }

  static func extend(_ correlationVector: String) -> CorrelationVectorProtocol {
    return CorrelationVector()
  }

  static func spin(_ correlationVector: String) -> CorrelationVectorProtocol {
    return CorrelationVector()
  }
}
