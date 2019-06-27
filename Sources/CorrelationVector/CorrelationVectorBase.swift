import Foundation

internal protocol CorrelationVectorBaseProtocol {
  init(_ baseVector: String, _ extension: Int, _ immutable: Bool)
}

@objc internal class CorrelationVectorBase: NSObject, CorrelationVectorBaseProtocol {
  @objc internal var baseVector: String
  @objc internal var `extension`: Int
  @objc internal var immutable: Bool

  required init(_ baseVector: String, _ extension: Int, _ immutable: Bool) {
    self.baseVector = baseVector
    self.extension = `extension`
    self.immutable = immutable
  }
}

internal extension CorrelationVectorProtocol where Self: CorrelationVectorBaseProtocol {
  static func isImmutable(_ correlationVector: String?) -> Bool {
    return !(correlationVector ?? "").isEmpty && correlationVector!.hasSuffix(CorrelationVector.terminator)
  }

  static func parse(from correlationVector: String?) -> CorrelationVectorProtocol {
    // TODO
    return self.init("", 0, false)
  }

  static func validate(from correlationVector: String?, _ maxVectorLength: Int, _ baseLength: Int) {
    // TODO
  }

  static func extend(from correlationVector: String?, _ maxVectorLength: Int, _ baseLength: Int) -> CorrelationVectorProtocol {
    if isImmutable(correlationVector) {
      return parse(correlationVector)
    }
    validate(from: correlationVector, maxVectorLength, baseLength)
    // TODO if isOversized(correlationVector, 0)
    return self.init()
  }
}
