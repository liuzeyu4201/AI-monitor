import Foundation

enum TokenUsageClientError: LocalizedError {
    case missingApiKey
    case invalidResponse
    case invalidBalance
    case httpStatus(Int, String?)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Missing API key"
        case .invalidResponse:
            return "Invalid response"
        case .invalidBalance:
            return "Invalid balance data"
        case .httpStatus(let code, let message):
            if let message = message, !message.isEmpty {
                return "HTTP \(code): \(message)"
            }
            return "HTTP \(code)"
        }
    }
}
