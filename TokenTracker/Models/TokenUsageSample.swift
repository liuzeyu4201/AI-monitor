import Foundation

struct TokenUsageSample: Identifiable, Codable, Equatable {
    let id: UUID
    let providerId: ProviderID
    let remaining: Double
    let limit: Double
    let timestamp: Date

    var used: Double { max(0, limit - remaining) }

    init(providerId: ProviderID, remaining: Double, limit: Double, timestamp: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.providerId = providerId
        self.remaining = remaining
        self.limit = limit
        self.timestamp = timestamp
    }
}
