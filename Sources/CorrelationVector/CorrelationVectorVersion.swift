// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

/// Version of Correlation Vector protocol specification.
///
/// - v1: represents the correlation vector version 1.
/// - v2: represents the correlation vector version 2.
@objc(MSCVCorrelationVectorVersion)
public enum CorrelationVectorVersion: Int {
  case v1 = 1
  case v2 = 2

  /// The type of implementation for the specific version of protocol.
  internal var type: CorrelationVectorProtocol.Type {
    switch self {
    case .v1:
      return CorrelationVectorV1.self
    case .v2:
      return CorrelationVectorV2.self
    }
  }
}
