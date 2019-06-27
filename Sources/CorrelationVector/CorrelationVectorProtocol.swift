import Foundation


/// This protocol represents the Correlation Vector.
/// The Correlation Vector is a format for tracing and correlating events in large systems.
@objc public protocol CorrelationVectorProtocol {

  /// Gets the value of the correlation vector as a string.
  var value: String { get }

  var base: String { get }

  var `extension`: Int { get }

  /// Gets the version of the correlation vector implementation.
  var version: CorrelationVectorVersion { get }

  init()
  init(_ vectorBase: UUID)

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
  static func extend(_ correlationVector: String?) -> CorrelationVectorProtocol

  /// Creates a new correlation vector by applying the Spin operator to an existing value.
  /// This should be done at the entry point of an operation.
  ///
  /// - Parameter correlationVector: string representation.
  /// - Returns: the Correlation Vector based on its version.
  static func spin(_ correlationVector: String?) -> CorrelationVectorProtocol

  // TODO spin with params
}
