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
      if CorrelationVectorBase.isOversized(base, `extension`, baseLength) {
        self.immutable = true
        return self.value
      }
    } while OSAtomicCompareAndSwap(snapshot, next)
    
    return self.base + "." + String(next)
  }
  
  static func isOversized(_ baseVector: String, _ baseExtension: Int, _ maxVectorLength: Int) -> Bool {
    if !baseVector.isEmpty {
      let size = Double(baseVector.count) + 1 + (Double(baseExtension) > 0 ? log10(Double(baseExtension)) : 0) + 1
      return size > Double(maxVectorLength)
    }
    return false
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
    if correlationVector != nil {
      let p = correlationVector?.lastIndex(of: ".")
      let immutable = self.isImmutable(correlationVector)
      if p != nil {
        let startIndex = correlationVector?.index(after: p!)
        let distanceP = correlationVector!.distance(from: correlationVector!.startIndex, to: p!)
        let endIndex = correlationVector?.index(correlationVector!.startIndex, offsetBy: correlationVector!.count - 1 - CorrelationVector.terminator.count - distanceP)
        let endIndexSecond = correlationVector?.index(after: p!)
        let extensionValue = String(immutable ? correlationVector![startIndex!...endIndex!] : correlationVector![..<endIndexSecond!])
        let extensionIntValue = Int(extensionValue)
        if (extensionIntValue != nil) && extensionIntValue! >= 0 {
          return self.init(String(correlationVector![..<p!]), extensionIntValue!, immutable)
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
    let maxVectorLength = maxVectorLength
    let baseLength = baseLength
    if correlationVector != nil && (correlationVector!.isEmpty || correlationVector!.count > maxVectorLength) {
      throw CorrelationVectorError.argumentException("The \(correlationVector!) correlation vector can not be null or bigger than \(maxVectorLength) characters")
    }
    let parts = correlationVector?.split(separator: ".")
    if parts != nil {
      if parts!.count < 2 || parts![0].count != baseLength {
        throw CorrelationVectorError.argumentException("Invalid correlation vector \(correlationVector!). Invalid base value \(parts![0])")
      }
      for index in 1...parts!.count {
        let result = Int(parts![index])
        if result! < 0 {
          throw CorrelationVectorError.argumentException("Invalid correlation vector \(correlationVector!). Invalid base value \(parts![0])")
        }
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
    if isOversized(correlationVector!, 0, maxVectorLength) {
      return parse(correlationVector!.appending(CorrelationVector.terminator))
    }
    return self.init()
  }
}
