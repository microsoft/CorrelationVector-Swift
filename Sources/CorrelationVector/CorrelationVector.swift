import Foundation

@objc public class CorrelationVector: NSObject, CorrelationVectorProtocol {
  internal static let delimiter: Character = "."
  internal static let terminator = "!"

  private var implementation: CorrelationVectorProtocol

  public var value: String {
    return self.implementation.value
  }

  public var base: String {
    return self.implementation.base
  }

  public var `extension`: Int {
    return self.implementation.extension
  }

  public var version: CorrelationVectorVersion {
    return self.implementation.version
  }

  public required override convenience init() {
    self.init(.v1)
  }

  public required convenience init(_ vectorBase: UUID) {
    self.init(.v1, vectorBase)
  }

  public convenience init(_ version: CorrelationVectorVersion) {
    self.init(version.type.init())
  }

  public convenience init(_ version: CorrelationVectorVersion, _ vectorBase: UUID) {
    self.init(version.type.init(vectorBase))
  }

  private init(_ implementation: CorrelationVectorProtocol) {
    self.implementation = implementation
    super.init()
  }

  public func increment() -> String {
    return self.implementation.increment()
  }

  // TODO isEqual
  // TODO toString

  public static func parse(_ correlationVector: String?) -> CorrelationVectorProtocol {
    let version = CorrelationVectorVersion.infer(from: correlationVector)
    let instance = version.type.parse(correlationVector)
    return CorrelationVector(instance)
  }

  public static func extend(_ correlationVector: String?) -> CorrelationVectorProtocol {
    let version = CorrelationVectorVersion.infer(from: correlationVector)
    let instance = version.type.extend(correlationVector)
    return CorrelationVector(instance)
  }

  public static func spin(_ correlationVector: String?) -> CorrelationVectorProtocol {
    let version = CorrelationVectorVersion.infer(from: correlationVector)
    let instance = version.type.spin(correlationVector)
    return CorrelationVector(instance)
  }
}
