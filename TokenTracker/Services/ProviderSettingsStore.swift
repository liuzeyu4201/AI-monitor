import Foundation

final class ProviderSettingsStore {
    static let shared = ProviderSettingsStore()

    private let defaults = UserDefaults.standard
    private let keychain = KeychainStore()

    func apiKey(for providerId: ProviderID) -> String? {
        keychain.read(account: apiKeyAccount(for: providerId))
    }

    func saveApiKey(for providerId: ProviderID, value: String) {
        keychain.save(account: apiKeyAccount(for: providerId), value: value)
    }

    func clearApiKey(for providerId: ProviderID) {
        keychain.delete(account: apiKeyAccount(for: providerId))
    }

    func selectedModel(for providerId: ProviderID) -> String {
        defaults.string(forKey: modelKey(for: providerId)) ?? ProviderCatalog.defaultModel(for: providerId)
    }

    func setSelectedModel(_ model: String, for providerId: ProviderID) {
        defaults.setValue(model, forKey: modelKey(for: providerId))
    }

    func budget(for providerId: ProviderID) -> Double? {
        let key = budgetKey(for: providerId)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.double(forKey: key)
    }

    func setBudget(_ value: Double?, for providerId: ProviderID) {
        let key = budgetKey(for: providerId)
        if let value = value {
            defaults.setValue(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func apiKeyAccount(for providerId: ProviderID) -> String {
        "provider.\(providerId.rawValue).apikey"
    }

    private func modelKey(for providerId: ProviderID) -> String {
        "provider.\(providerId.rawValue).model"
    }

    private func budgetKey(for providerId: ProviderID) -> String {
        "provider.\(providerId.rawValue).budget"
    }
}
