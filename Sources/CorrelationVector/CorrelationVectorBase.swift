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
  
  static func baseUuid(from uuid: UUID, _ baseLength: Int) -> String {
    let uuidString = uuid.uuidString
    let base64String = Data(uuidString.utf8).base64EncodedString();
    let endIndex = base64String.index(base64String.startIndex, offsetBy: baseLength);
    return String(base64String[..<endIndex])
  }
  
  func increment(_ baseLength: Int) -> String {
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
      if CorrelationVectorBase.isOversized(base, next, baseLength) {
        self.immutable = true
        return self.value
      }
    } while OSAtomicCompareAndSwap(snapshot, next)
    
    return "\(self.base).\(String(next))"
  }
  
  static func isOversized(_ baseVector: String?, _ baseExtension: Int, _ maxVectorLength: Int) -> Bool {
    guard let vector = baseVector, !vector.isEmpty else {
      return false
    }
    let size = Double(vector.count) + 1 + (Double(baseExtension) > 0 ? log10(Double(baseExtension)) : 0) + 1
    return size > Double(maxVectorLength)
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
    if let vector = correlationVector {
      let p = vector.lastIndex(of: ".")
      let immutable = self.isImmutable(correlationVector)
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
    return self.init("", 0, false)
  }
  
  /// Validates the CV string with the given CV version.
  ///
  /// - Parameters:
  ///   - correlationVector: string representation.
  ///   - maxVectorLength: the max length of a correlation vector.
  ///   - baseLength: the max length of a correlation vector base.
  ///   - Throws: CorrelationVectorError.argumentException if vector is not valid.
  static func validate(from correlationVector: String?, _ maxVectorLength: Int, _ baseLength: Int) throws {
    guard let vector = correlationVector, !vector.isEmpty && vector.count <= maxVectorLength else {
      throw CorrelationVectorError.argumentException("The \(correlationVector!) correlation vector can not be null or bigger than \(maxVectorLength) characters")
    }
    let parts = vector.split(separator: ".")
    if parts.count < 2 || parts[0].count != baseLength {
        throw CorrelationVectorError.argumentException("Invalid correlation vector \(vector). Invalid base value \(parts[0])")
    }
    for index in 1...parts.count {
      let result = Int(parts[index])
      if result == nil || result! < 0 {
        throw CorrelationVectorError.argumentException("Invalid correlation vector \(vector). Invalid base value \(parts[0])")
      }
    }
  }
  
  static func extend(from correlationVector: String?, _ maxVectorLength: Int, _ baseLength: Int) throws -> CorrelationVectorProtocol {
    if isImmutable(correlationVector) {
      return parse(from: correlationVector)
    }
    if CorrelationVector.validateDuringCreation {
      try validate(from: correlationVector, maxVectorLength, baseLength)
    }
    if let vector = correlationVector, isOversized(vector, 0, maxVectorLength) {
      return parse(vector.appending(CorrelationVector.terminator))
    }
    return self.init(correlationVector!, 0, false)
  }
}
