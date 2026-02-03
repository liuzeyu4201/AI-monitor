import Foundation

enum TokenUsageClientError: LocalizedError {
    case missingApiKey
    case invalidResponse
    case invalidBalance

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Missing API key"
        case .invalidResponse:
            return "Invalid response"
        case .invalidBalance:
            return "Invalid balance data"
        }
    }
}
