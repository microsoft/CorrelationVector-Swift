// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

@objc internal class CorrelationVectorV1: CorrelationVectorBase, CorrelationVectorProtocol {

  /// The max length of a correlation vector.
  internal static let maxLength = 63

  /// The max length of a correlation vector base.
  internal static let baseLength = 16

  var version: CorrelationVectorVersion {
    return .v1
  }

  required convenience init() {
    self.init(CorrelationVectorV1.uniqueValue(), 0, false)
  }

  required convenience init(_ base: UUID) {
    self.init(baseUuid(from: base, baseLength: CorrelationVectorV1.baseLength), 0, false)
  }

  required init(_ base: String, _ extension: UInt32, _ immutable: Bool) {
    super.init(base, `extension`, immutable || isOversized(base, `extension`, maxLength: CorrelationVectorV1.maxLength))
  }

  func increment() -> String {
    return self.increment(maxLength: CorrelationVectorV1.maxLength)
  }

  static func parse(_ correlationVector: String?) -> CorrelationVectorProtocol {
    return parse(from: correlationVector)
  }

  static func extend(_ correlationVector: String?) throws -> CorrelationVectorProtocol {
    return try extend(correlationVector, baseLength: baseLength, maxLength: maxLength)
  }

  static func spin(_ correlationVector: String?, _ parameters: SpinParameters) throws -> CorrelationVectorProtocol {
    throw CorrelationVectorError.invalidOperation("Spin is not supported in Correlation Vector V1")
  }

  private static func uniqueValue() -> String {
    return UUID().data.prefix(12).base64EncodedString()
  }
}
