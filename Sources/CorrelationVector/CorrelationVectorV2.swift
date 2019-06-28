// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

@objc internal class CorrelationVectorV2: CorrelationVectorBase, CorrelationVectorProtocol {

  /// The max length of a correlation vector.
  internal static let maxVectorLength = 127

  /// The max length of a correlation vector base.
  internal static let baseLength = 22

  var version: CorrelationVectorVersion {
    return .v2
  }

  required convenience init() {
    // TODO
    self.init("", 0, false)
  }

  required convenience init(_ base: UUID) {
    // TODO
    self.init("", 0, false)
  }

  required init(_ baseVector: String, _ extension: Int, _ immutable: Bool) {
    super.init(baseVector, `extension`, immutable)
  }

  func increment() -> String {
    // TODO
    return ""
  }

  static func parse(_ correlationVector: String?) -> CorrelationVectorProtocol {
    return parse(from: correlationVector)
  }

  static func extend(_ correlationVector: String?) -> CorrelationVectorProtocol {
    return extend(from: correlationVector, maxVectorLength, baseLength)
  }

  static func spin(_ correlationVector: String?) -> CorrelationVectorProtocol {
    // TODO
    return CorrelationVector()
  }

  static func spin(_ correlationVector: String?, _ parameters: SpinParameters) -> CorrelationVectorProtocol {
    // TODO
    return CorrelationVector()
  }
  
  func getBaseAsGuid() throws -> UUID {
    if (CorrelationVector.validateDuringCreation) {
      let index = base.index(before: base.endIndex)
      let lastChar = base[index]
      if (lastChar != "A" && lastChar != "Q" && lastChar != "g" && lastChar != "w") {
        throw CorrelationVectorError.invalidOperation("The four least significant bits of the base64 encoded vector base must be zeros to reliably convert to a guid.")
      }
    }
    let decodedData = Data(base64Encoded: base.appending("=="))
    let decodedString = String(data: decodedData!, encoding: .utf8)
    return UUID(uuidString: decodedString!)!
  }
}
