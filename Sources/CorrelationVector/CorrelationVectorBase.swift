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
    return "\(self.base).\(next)"
  }
}

internal extension CorrelationVectorProtocol where Self: CorrelationVectorBase {

  /// Converts a string representation of a Correlation Vector into this class.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  static func parse(from correlationVector: String?) -> CorrelationVectorProtocol {
    if let vector = correlationVector {
      let p = vector.lastIndex(of: ".")
      let immutable = isImmutable(correlationVector)
      if let lastDotIndex = p {
        let startIndex = vector.index(after: lastDotIndex)
        let distanceP = vector.distance(from: vector.startIndex, to: lastDotIndex)
        let endIndex = vector.index(vector.startIndex, offsetBy: vector.count - 1 - CorrelationVector.terminator.count - distanceP)
        let endIndexSecond = startIndex
        let extensionValue = String(immutable ? vector[startIndex...endIndex] : vector[..<endIndexSecond])
        let extensionIntValue = Int(extensionValue)
        if extensionIntValue != nil && extensionIntValue! >= 0 {
          return self.init(String(vector[..<lastDotIndex]), extensionIntValue!, immutable)
        }
      }
    }
    return self.init()
  }

  /// Creates a new correlation vector by extending an existing value.
  /// This should be done at the entry point of an operation.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  /// - Throws: CorrelationVectorError.argumentException if vector is not valid.
  static func extend(_ correlationVector: String?, baseLength: Int, maxLength: Int) throws -> CorrelationVectorProtocol {
    if isImmutable(correlationVector) {
      return parse(from: correlationVector)
    }
    if CorrelationVector.validateDuringCreation {
      try validate(correlationVector, baseLength: baseLength, maxLength: maxLength)
    }
    if let vector = correlationVector, isOversized(vector, 0, maxLength: maxLength) {
      return parse(vector.appending(CorrelationVector.terminator))
    }
    return self.init(correlationVector!, 0, false)
  }
}
