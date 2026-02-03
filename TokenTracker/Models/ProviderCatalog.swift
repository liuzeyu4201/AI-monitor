import Foundation

struct ProviderCatalog {
    static func models(for providerId: ProviderID) -> [String] {
        switch providerId {
        case .deepseek:
            return ["deepseek-chat", "deepseek-reasoner"]
        case .openai, .qwen, .zhipu:
            return []
        }
    }

    static func defaultModel(for providerId: ProviderID) -> String {
        models(for: providerId).first ?? ""
    }

    static func baseURL(for providerId: ProviderID) -> String? {
        switch providerId {
        case .deepseek:
            return "https://api.deepseek.com"
        case .openai, .qwen, .zhipu:
            return nil
        }
    }
}
