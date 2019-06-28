// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

@objc internal class CorrelationVectorV1: CorrelationVectorBase, CorrelationVectorProtocol {

  /// The max length of a correlation vector.
  internal static let maxVectorLength = 63

  /// The max length of a correlation vector base.
  internal static let baseLength = 16

  var version: CorrelationVectorVersion {
    return .v1
  }

  required convenience init() {
    self.init(CorrelationVectorV1.uniqueValue(), 0, false)
  }

  required convenience init(_ base: UUID) {
    self.init(CorrelationVectorBase.baseUuid(from: base, CorrelationVectorV1.baseLength), 0, false)
  }

  required init(_ baseVector: String, _ extension: Int, _ immutable: Bool) {
    super.init(baseVector, `extension`, immutable)
  }
  
  func increment() -> String {
    return self.increment(CorrelationVectorV1.maxVectorLength)
  }

  static func parse(_ correlationVector: String?) -> CorrelationVectorProtocol {
    return parse(from: correlationVector)
  }

  static func extend(_ correlationVector: String?) throws -> CorrelationVectorProtocol {
    return try extend(from: correlationVector, maxVectorLength, baseLength)
  }

  static func spin(_ correlationVector: String?) throws -> CorrelationVectorProtocol {
    throw CorrelationVectorError.invalidOperation("Spin is not supported in Correlation Vector V1")
  }

  static func spin(_ correlationVector: String?, _ parameters: SpinParameters) throws -> CorrelationVectorProtocol {
    throw CorrelationVectorError.invalidOperation("Spin is not supported in Correlation Vector V1")
  }
  
  private static func uniqueValue() -> String {
    let uuid = UUID().uuidString
    return Data(uuid.utf8).base64EncodedString()
  }
}
