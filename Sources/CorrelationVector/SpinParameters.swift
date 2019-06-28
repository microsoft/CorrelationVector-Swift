// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

/// The number of least significant bits to drop when computing the counter
/// for CV's spin operation.
///
/// - coarse: the coarse interval drops the 24 least significant bits
///           resulting in a counter that increments every 1.67 seconds.
/// - fine: the fine interval drops the 16 least significant bits resulting
///         in a counter that increments every 6.5 milliseconds.
@objc public enum SpinCounterInterval: Int {
  case coarse = 24
  case fine = 16
}

/// Counter for CV's spin operation.
///
/// - none: do not store a counter as part of the spin value.
/// - short: the short periodicity stores the counter using 16 bits.
/// - medium: the medium periodicity stores the counter using 24 bits.
/// - long: the long periodicity stores the counter using 32 bits.
@objc public enum SpinCounterPeriodicity: Int {
  case none = 0
  case short = 16
  case medium = 24
  case long = 32
}

/// Entropy bytes that is used for CV's spin operation.
///
/// - none: do not generate entropy as part of the spin value
/// - one: generate entropy using 8 bits.
/// - two: generate entropy using 16 bits.
/// - three: generate entropy using 24 bits.
/// - four: generate entropy using 32 bits.
@objc public enum SpinEntropy: Int {
  case none = 0
  case one = 1
  case two = 2
  case three = 3
  case four = 4
}

/// Configuration parameters used by CV's spin operation.
@objc public class SpinParameters: NSObject {

  /// The interval (proportional to time) by which the counter increments.
  var interval: SpinCounterInterval = .coarse

  /// How frequently the counter wraps around to zero, as determined by the amount
  /// of space to store the counter.
  var periodicity: SpinCounterPeriodicity = .short

  /// The number of bytes to use for entropy. Valid values from a
  /// minimum of 0 to a maximum of 4.
  var entropy: SpinEntropy = .two

  /// The total number of bits to keep for the spin operation.
  var totalBits: Int {
    return periodicity.rawValue + entropy.rawValue * 8
  }
}
