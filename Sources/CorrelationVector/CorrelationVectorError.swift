// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

enum CorrelationVectorError: Error {
  case invalidOperation(_ description: String)
  case argumentException(_ description: String)
}
