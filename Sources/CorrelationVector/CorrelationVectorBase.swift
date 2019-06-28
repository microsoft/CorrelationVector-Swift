import Foundation

@objc internal class CorrelationVectorBase: NSObject {
  @objc internal var baseVector: String
  @objc internal var `extension`: Int

  /// Indicates whether the CV object is immutable.
  @objc internal var immutable: Bool

  required init(_ baseVector: String, _ extension: Int, _ immutable: Bool) {
    self.baseVector = baseVector
    self.extension = `extension`
    self.immutable = immutable
  }
}

internal extension CorrelationVectorProtocol where Self: CorrelationVectorBase {


  /// Checks if the given CV string is immutable. If the given non-empty string
  /// ends with the CV termination sign, the CV is said to be immutable.
  ///
  /// - Parameter correlationVector: <#correlationVector description#>
  /// - Returns: <#return value description#>
  static func isImmutable(_ correlationVector: String?) -> Bool {
    return !(correlationVector ?? "").isEmpty && correlationVector!.hasSuffix(CorrelationVector.terminator)
  }

  static func parse(from correlationVector: String?) -> CorrelationVectorProtocol {
    // TODO
    return self.init("", 0, false)
  }

  /// Validates the CV string with the given CV version.
  ///
  /// - Parameters:
  ///   - correlationVector: <#correlationVector description#>
  ///   - maxVectorLength: <#maxVectorLength description#>
  ///   - baseLength: <#baseLength description#>
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
