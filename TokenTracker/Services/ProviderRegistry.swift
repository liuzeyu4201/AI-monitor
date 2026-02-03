import Foundation

struct ProviderRegistry {
    let providers: [Provider]
    let clients: [ProviderID: TokenUsageClient]

    static func `default`() -> ProviderRegistry {
        let settingsStore = ProviderSettingsStore.shared
        let clients: [ProviderID: TokenUsageClient] = [
            .deepseek: DeepSeekTokenUsageClient(settingsStore: settingsStore),
            .openai: OpenAITokenUsageClient(settingsStore: settingsStore),
            .qwen: QwenTokenUsageClient(settingsStore: settingsStore)
        ]

        let activeProviders = ProviderID.allCases.filter { providerId in
            guard clients[providerId] != nil else { return false }
            switch providerId {
            case .qwen:
                return settingsStore.qwenAccessKey() != nil && settingsStore.qwenAccessSecret() != nil && settingsStore.qwenMonitoringBaseURL() != nil
            case .openai, .deepseek:
                return settingsStore.apiKey(for: providerId) != nil
            case .zhipu:
                return false
            }
        }
        let providers = activeProviders.map { providerId -> Provider in
            let baseURL: String?
            switch providerId {
            case .qwen:
                baseURL = settingsStore.qwenMonitoringBaseURL()
            default:
                baseURL = ProviderCatalog.baseURL(for: providerId)
            }
            return Provider(id: providerId, apiBaseURL: baseURL)
        }

        return ProviderRegistry(providers: providers, clients: clients)
    }
}
