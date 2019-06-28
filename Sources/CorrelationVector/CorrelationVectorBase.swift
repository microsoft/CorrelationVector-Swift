// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

@objc internal class CorrelationVectorBase: NSObject {
  @objc internal var base: String
  @objc internal var `extension`: Int

  /// Indicates whether the CV object is immutable.
  @objc internal var immutable: Bool

  @objc var value: String {
    return "\(self.base).\(self.extension)\(self.immutable ? CorrelationVector.terminator : "")"
  }

  required init(_ base: String, _ extension: Int, _ immutable: Bool) {
    self.base = base
    self.extension = `extension`
    self.immutable = immutable
  }
}

internal extension CorrelationVectorProtocol where Self: CorrelationVectorBase {

  /// Checks if the given CV string is immutable. If the given non-empty string
  /// ends with the CV termination sign, the CV is said to be immutable.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: true is the given CV string is immutable.
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
  ///   - correlationVector: string representation.
  ///   - maxVectorLength: the max length of a correlation vector.
  ///   - baseLength: the max length of a correlation vector base.
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
  
  static func getBaseFromGuid(guid: UUID, baseLength: Int) -> String {
    let guidString = guid.uuidString
    let base64String = Data(guidString.utf8).base64EncodedString();
    let endIndex = base64String.index(base64String.startIndex, offsetBy: baseLength);
    return String(base64String[..<endIndex])
  }
}
