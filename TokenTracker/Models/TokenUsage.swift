import Foundation

enum UsageUnit: Codable, Equatable {
    case tokens
    case currency(String)

    var label: String {
        switch self {
        case .tokens:
            return "tokens"
        case .currency(let code):
            return code
        }
    }

    var fractionDigits: Int {
        switch self {
        case .tokens:
            return 0
        case .currency:
            return 2
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if value == "tokens" {
            self = .tokens
        } else if value.hasPrefix("currency:") {
            self = .currency(String(value.dropFirst("currency:".count)))
        } else {
            self = .tokens
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .tokens:
            try container.encode("tokens")
        case .currency(let code):
            try container.encode("currency:\(code)")
        }
    }
}

struct TokenUsage: Codable, Equatable {
    let providerId: ProviderID
    var remaining: Double
    var limit: Double
    var updatedAt: Date
    var burnRatePerMinute: Double
    var unit: UsageUnit

    var used: Double { max(0, limit - remaining) }

    var etaDepletion: Date? {
        guard burnRatePerMinute > 0 else { return nil }
        let minutes = remaining / burnRatePerMinute
        return Date().addingTimeInterval(minutes * 60)
    }

    static func empty(for providerId: ProviderID) -> TokenUsage {
        TokenUsage(providerId: providerId, remaining: 0, limit: 0, updatedAt: Date(), burnRatePerMinute: 0, unit: .tokens)
    }
}
