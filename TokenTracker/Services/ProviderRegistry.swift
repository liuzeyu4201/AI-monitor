import Foundation

struct ProviderRegistry {
    let providers: [Provider]
    let clients: [ProviderID: TokenUsageClient]

    static func `default`() -> ProviderRegistry {
        let providers = ProviderID.allCases.map { Provider(id: $0, apiBaseURL: ProviderCatalog.baseURL(for: $0)) }
        let settingsStore = ProviderSettingsStore.shared

        // TODO: Replace MockTokenUsageClient with real API clients per provider.
        // Keep the mapping by ProviderID so new providers can be added without changing view code.
        let clients: [ProviderID: TokenUsageClient] = [
            .openai: MockTokenUsageClient(providerId: .openai),
            .deepseek: DeepSeekTokenUsageClient(settingsStore: settingsStore),
            .qwen: MockTokenUsageClient(providerId: .qwen),
            .zhipu: MockTokenUsageClient(providerId: .zhipu)
        ]

        return ProviderRegistry(providers: providers, clients: clients)
    }
}
