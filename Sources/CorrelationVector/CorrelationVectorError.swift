// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

/// The errors that can be thrown from correlation vector library.
///
/// - invalidOperation: invalid operation.
/// - invalidArgument: invalid argument.
enum CorrelationVectorError: Error {
  case invalidOperation(_ description: String)
  case invalidArgument(_ description: String)
}
