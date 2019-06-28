// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

@objc internal class CorrelationVectorV2: CorrelationVectorBase, CorrelationVectorProtocol {

  /// The max length of a correlation vector.
  internal static let maxLength = 127

  /// The max length of a correlation vector base.
  internal static let baseLength = 22

  var version: CorrelationVectorVersion {
    return .v2
  }

  required convenience init() {
    self.init(UUID())
  }

  required convenience init(_ base: UUID) {
    self.init(baseUuid(from: base, baseLength: CorrelationVectorV2.baseLength), 0, false)
  }

  required init(_ base: String, _ extension: Int, _ immutable: Bool) {
    super.init(base, `extension`, immutable || isOversized(base, `extension`, maxLength: CorrelationVectorV2.maxLength))
  }

  func increment() -> String {
    return self.increment(maxLength: CorrelationVectorV2.maxLength)
  }

  static func parse(_ correlationVector: String?) -> CorrelationVectorProtocol {
    return parse(from: correlationVector)
  }

  static func extend(_ correlationVector: String?) throws -> CorrelationVectorProtocol {
    return try extend(correlationVector, baseLength: baseLength, maxLength: maxLength)
  }

  static func spin(_ correlationVector: String?) throws -> CorrelationVectorProtocol {
    // TODO
    return CorrelationVector()
  }

  static func spin(_ correlationVector: String?, _ parameters: SpinParameters) throws -> CorrelationVectorProtocol {
    // TODO
    return CorrelationVector()
  }
}
