import Foundation

enum CorrelationVectorError: Error {
  case invalidOperation(_ description: String)
  case argumentException(_ description: String)
}
