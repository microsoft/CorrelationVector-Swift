// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

// MARK: - Extensions methods providing additional functionality for correlation vectors.
public extension CorrelationVectorProtocol {

  /// Creates a new correlation vector by applying the spin operator to an existing value.
  /// This should be done at the entry point of an operation.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  /// - Throws: CorrelationVectorError.invalidOperation if spin operation isn't supported
  ///           for this correlation vector.
  static func spin(_ correlationVector: String?) throws -> CorrelationVectorProtocol {
    return try spin(correlationVector, SpinParameters())
  }

  /// Gets the value of the correlation vector base encoded as a UUID.
  ///
  /// - Returns: The UUID value of the encoded vector base.
  /// - Throws: CorrelationVectorError.invalidOperation if value is not valid.
  func baseAsUUID() throws -> UUID? {
    if version == .v1 {
      throw CorrelationVectorError.invalidOperation("Cannot convert a V1 correlation vector base to a UUID.")
    }
    if (CorrelationVector.validateDuringCreation) {

      // In order to reliably convert a V2 vector base to a guid, the four least significant bits of the last
      // base64 content-bearing 6-bit block must be zeros.
      // There are four such base64 characters so we can easily detect whether this condition is true.
      // A - 00 0000
      // Q - 01 0000
      // g - 10 0000
      // w - 11 0000
      let lastChar = base.last
      if lastChar != "A" && lastChar != "Q" && lastChar != "g" && lastChar != "w" {
        throw CorrelationVectorError.invalidOperation("The four least significant bits of the base64 encoded vector base must be zeros to reliably convert to a UUID.")
      }
    }
    return Data(base64Encoded: base + "==")?.uuid
  }
}
