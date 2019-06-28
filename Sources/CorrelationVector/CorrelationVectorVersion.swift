import Foundation

@objc public enum CorrelationVectorVersion: Int {
  case v1 = 1
  case v2 = 2

  internal var type: CorrelationVectorProtocol.Type {
    switch self {
    case .v1:
      return CorrelationVectorV1.self
    case .v2:
      return CorrelationVectorV2.self
    }
  }

  /// Identifies which version of the Correlation Vector is being used.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: An enum indicating correlation vector version.
  internal static func infer(from correlationVector: String?) -> CorrelationVectorVersion {
    if let index = correlationVector?.firstIndex(of: CorrelationVector.delimiter) {
      let distance = correlationVector!.distance(from: correlationVector!.startIndex, to: index)
      if CorrelationVectorV1.baseLength == distance {
        return .v1
      } else if CorrelationVectorV2.baseLength == distance {
        return .v2
      }
    }
    // Use version 1 by default.
    return .v1
  }
}
