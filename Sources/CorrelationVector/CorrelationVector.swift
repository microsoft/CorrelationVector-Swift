import Foundation

@objc class CorrelationVector: NSObject, CorrelationVectorProtocol {
  private var implementation: CorrelationVectorProtocol

  var value: String {
    return self.implementation.value
  }

  var base: String {
    return self.implementation.base
  }

  var version: CorrelationVectorVersion {
    return self.implementation.version
  }

  required override convenience init() {
    self.init(.v1)
  }

  required convenience init(_ vectorBase: UUID) {
    self.init(.v1, vectorBase)
  }

  convenience init(_ version: CorrelationVectorVersion) {
    self.init(CorrelationVector.type(for: version).init())
  }

  convenience init(_ version: CorrelationVectorVersion, _ vectorBase: UUID) {
    self.init(CorrelationVector.type(for: version).init(vectorBase))
  }

  private init(_ implementation: CorrelationVectorProtocol) {
    self.implementation = implementation
    super.init()
  }

  func increment() -> String {
    return self.implementation.increment()
  }

  // TODO isEqual
  // TODO toString

  static func parse(_ correlationVector: String) -> CorrelationVectorProtocol {
    let version = CorrelationVector.inferVersion(correlationVector)
    let type = CorrelationVector.type(for: version)
    let instance = type.parse(correlationVector)
    return CorrelationVector(instance)
  }

  static func extend(_ correlationVector: String) -> CorrelationVectorProtocol {
    let version = CorrelationVector.inferVersion(correlationVector)
    let type = CorrelationVector.type(for: version)
    let instance = type.extend(correlationVector)
    return CorrelationVector(instance)
  }

  static func spin(_ correlationVector: String) -> CorrelationVectorProtocol {
    let version = CorrelationVector.inferVersion(correlationVector)
    let type = CorrelationVector.type(for: version)
    let instance = type.spin(correlationVector)
    return CorrelationVector(instance)
  }

  private static func inferVersion(_ correlationVector: String) -> CorrelationVectorVersion {
    // TODO
    return .v1
  }

  private static func type(for version: CorrelationVectorVersion) -> CorrelationVectorProtocol.Type {
    switch version {
    case .v1:
      return CorrelationVectorV1.self
    case .v2:
      return CorrelationVectorV2.self
    }
  }
}
