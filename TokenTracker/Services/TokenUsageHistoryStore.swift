import Foundation

protocol TokenUsageHistoryStore {
    func load() -> [ProviderID: [TokenUsageSample]]
    func save(_ history: [ProviderID: [TokenUsageSample]])
}
