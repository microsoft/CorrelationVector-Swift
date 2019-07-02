// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

/// Gets the length of an integer. The given integer must be non-negative.
///
/// - Parameter value: non-negative integer.
/// - Returns: length of the given integer.
fileprivate func intLength(_ value: Int) -> Int {
  return value > 0 ? Int(log10(Double(value))) + 1 : 1;
}

/// Checks if the cV will be too big if an extension is added to the base vector.
///
/// - Parameters:
///   - baseVector: base vector from the incoming request.
///   - extension: extension number.
///   - maxLength: the max length of a correlation vector.
/// - Returns: True if new vector will be too large. False if there is no vector or the vector is the appropriate size.
internal func isOversized(_ baseVector: String?, _ extension: Int, maxLength: Int) -> Bool {
  guard let vector = baseVector, !vector.isEmpty else {
    return false
  }
  let size = vector.count + 1 + intLength(`extension`)
  return size > maxLength
}

/// Checks if the given cV string is immutable. If the given non-empty string
/// ends with the cV termination sign, the CV is said to be immutable.
///
/// - Parameter correlationVector: string representation.
/// - Returns: true is the given CV string is immutable.
internal func isImmutable(_ correlationVector: String?) -> Bool {
  guard let vector = correlationVector, !vector.isEmpty else {
    return false
  }
  return vector.hasSuffix(CorrelationVector.terminator)
}

/// Validates the cV string with the given cV version.
///
/// - Parameters:
///   - correlationVector: string representation.
///   - baseLength: the max length of a correlation vector base.
///   - maxLength: the max length of a correlation vector.
/// - Throws: CorrelationVectorError.invalidArgument if vector is not valid.
internal func validate(_ correlationVector: String?, baseLength: Int, maxLength: Int) throws {
  guard let vector = correlationVector, !vector.isEmpty && vector.count <= maxLength else {
    throw CorrelationVectorError.invalidArgument("The \(correlationVector!)\(correlationVector!.isEmpty ? "" : " ")correlation vector can not be null or bigger than \(maxLength) characters")
  }
  let parts = vector.split(separator: CorrelationVector.delimiter)
  if parts.count < 2 || parts[0].count != baseLength {
    throw CorrelationVectorError.invalidArgument("Invalid correlation vector \(vector). Invalid base value \(parts[0])")
  }
  for index in 1...parts.count {
    guard let result = Int(parts[index]), result < 0 else {
      throw CorrelationVectorError.invalidArgument("Invalid correlation vector \(vector). Invalid base value \(parts[0])")
    }
  }
}

/// Gets an encoded vector base value from the UUID.
///
/// - Parameters:
///   - uuid: The UUID to encode as a vector base.
///   - baseLength: the max length of a correlation vector base.
/// - Returns: The encoded vector base value.
internal func baseUuid(from uuid: UUID, baseLength: Int) -> String {
  let uuidString = uuid.uuidString
  let base64String = Data(uuidString.utf8).base64EncodedString();
  let endIndex = base64String.index(base64String.startIndex, offsetBy: baseLength);
  return String(base64String[..<endIndex])
}

/// Generates data with random bytes.
///
/// - Parameter count: the number of bytes.
/// - Returns: the data object with random bytes.
internal func randomBytes(count: Int) -> Data {
  var data = Data(count: count)
  data.withUnsafeMutableBytes {
    arc4random_buf($0.baseAddress!, count)
  }
  return data
}
