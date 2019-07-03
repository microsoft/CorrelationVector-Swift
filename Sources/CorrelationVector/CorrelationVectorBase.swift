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

  func increment(maxLength: Int) -> String {
    if self.immutable {
      return self.value
    }
    var snapshot = 0
    var next = 0
    repeat {
      snapshot = self.extension
      if snapshot == Int.max {
        return self.value
      }
      next = snapshot + 1
      if isOversized(base, next, maxLength: maxLength) {
        self.immutable = true
        return self.value
      }
    } while !compareAndSwap(OpaquePointer(UnsafeMutablePointer<Int>(&self.extension)), UnsafeMutablePointer<Int>(&snapshot), next)
    return "\(self.base)\(CorrelationVector.delimiter)\(next)"
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
      if let extValue = Int(ext), extValue >= 0 {
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
