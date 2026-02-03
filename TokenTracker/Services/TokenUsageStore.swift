import Foundation

protocol TokenUsageStore {
    func load() -> [ProviderID: TokenUsage]
    func save(_ usage: [ProviderID: TokenUsage])
}
