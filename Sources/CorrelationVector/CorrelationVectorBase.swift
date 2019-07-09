// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

@objc internal class CorrelationVectorBase: NSObject {
  @objc internal var baseVector: String
  @objc internal var `extension`: UInt32

  /// Indicates whether the CV object is immutable.
  @objc internal var immutable: Bool

  @objc internal var base: String {
    if let index = self.baseVector.firstIndex(of: CorrelationVector.delimiter) {
      return String(self.baseVector[..<index])
    }
    return self.baseVector
  }

  @objc internal var value: String {
    return "\(self.baseVector)\(CorrelationVector.delimiter)\(self.extension)\(self.immutable ? CorrelationVector.terminator : "")"
  }

  required init(_ baseVector: String, _ extension: UInt32, _ immutable: Bool) {
    self.baseVector = baseVector
    self.extension = `extension`
    self.immutable = immutable
  }

  func increment(maxLength: Int) -> String {
    if self.immutable {
      return self.value
    }

    // Use locks because atomics aren't usable in Swift at the moment.
    // See https://bugs.swift.org/browse/SR-9144
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    if self.extension == UInt32.max {
      return self.value
    }
    let next = self.extension + 1
    if isOversized(self.baseVector, next, maxLength: maxLength) {
      self.immutable = true
    } else {
      self.extension = next
    }
    return self.value
  }
}

internal extension CorrelationVectorProtocol where Self: CorrelationVectorBase {

  /// Converts a string representation of a Correlation Vector into this class.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  static func parse(from correlationVector: String?) -> CorrelationVectorProtocol {
    if let vector = correlationVector, let lastDot = vector.lastIndex(of: CorrelationVector.delimiter) {
      let base = vector[..<lastDot]
      var ext = vector[vector.index(after: lastDot)...]
      let immutable = isImmutable(correlationVector)
      if immutable {
        ext = ext[..<ext.index(ext.endIndex, offsetBy: -CorrelationVector.terminator.count)]
      }
      if let extValue = UInt32(ext) {
        return self.init(String(base), extValue, immutable)
      }
    }
    return self.init()
  }

  /// Creates a new correlation vector by extending an existing value.
  /// This should be done at the entry point of an operation.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  /// - Throws: CorrelationVectorError.invalidArgument if vector is not valid.
  static func extend(_ correlationVector: String?, baseLength: Int, maxLength: Int) throws -> CorrelationVectorProtocol {
    if isImmutable(correlationVector) {
      return parse(from: correlationVector)
    }
    if CorrelationVector.validateDuringCreation {
      try validate(correlationVector, baseLength: baseLength, maxLength: maxLength)
    }
    if let vector = correlationVector {
      if isOversized(vector, 0, maxLength: maxLength) {
        return parse(vector + CorrelationVector.terminator)
      }
      return self.init(vector, 0, false)
    }
    return self.init()
  }
}
