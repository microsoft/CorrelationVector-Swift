// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

/// This protocol represents the Correlation Vector.
/// The Correlation Vector is a format for tracing and correlating events in large systems.
@objc(MSCVCorrelationVectorProtocol)
public protocol CorrelationVectorProtocol {

  /// The value of the correlation vector as a string.
  var value: String { get }

  /// The base value of the correlation vector.
  var base: String { get }

  /// The extension number.
  var `extension`: UInt32 { get }

  /// The version of the correlation vector implementation.
  var version: CorrelationVectorVersion { get }

  /// Initializes a new instance of the Correlation Vector.
  /// This should only be called when no correlation vector was found in the message header.
  init()

  /// Initializes a new instance of the Correlation Vector using the given UUID as the vector base.
  ///
  /// - Parameter base: the UUID to use as a correlation vector base.
  init(_ base: UUID)

  /// Increments the extension, the numerical value at the end of the vector, by one
  /// and returns the string representation.
  ///
  /// - Returns: the new cV value as a string that you can add to the outbound message header.
  func increment() -> String

  /// Converts a string representation of a Correlation Vector into this class.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  static func parse(_ correlationVector: String?) -> CorrelationVectorProtocol

  /// Creates a new correlation vector by extending an existing value.
  /// This should be done at the entry point of an operation.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  /// - Throws: CorrelationVectorError.invalidArgument if vector is not valid.
  static func extend(_ correlationVector: String?) throws -> CorrelationVectorProtocol

  /// Creates a new correlation vector by applying the spin operator to an existing value.
  /// This should be done at the entry point of an operation.
  ///
  /// - Parameters:
  ///   - correlationVector: string representation.
  ///   - parameters: the parameters to use when applying the Spin operator.
  /// - Returns: the Correlation Vector based on its version.
  /// - Throws: CorrelationVectorError.invalidOperation if spin operation isn't supported
  ///           for this correlation vector.
  static func spin(_ correlationVector: String?, _ parameters: SpinParameters) throws -> CorrelationVectorProtocol
}
