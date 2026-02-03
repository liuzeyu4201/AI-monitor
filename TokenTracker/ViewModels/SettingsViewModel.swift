import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var deepseekModel: String = ""
    @Published var deepseekApiKey: String = ""
    @Published var deepseekApiKeySaved: Bool = false
    @Published var deepseekBudgetText: String = ""

    private let store: ProviderSettingsStore
    private let formatter: NumberFormatter

    init(store: ProviderSettingsStore = .shared) {
        self.store = store
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        self.formatter = formatter
        load()
    }

    func load() {
        let selected = store.selectedModel(for: .deepseek)
        deepseekModel = selected.isEmpty ? ProviderCatalog.defaultModel(for: .deepseek) : selected
        deepseekApiKeySaved = store.apiKey(for: .deepseek) != nil
        if let budget = store.budget(for: .deepseek) {
            deepseekBudgetText = formatter.string(from: NSNumber(value: budget)) ?? ""
        } else {
            deepseekBudgetText = ""
        }
    }

    func saveDeepSeek() {
        if !deepseekApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.saveApiKey(for: .deepseek, value: deepseekApiKey)
            deepseekApiKey = ""
        }
        store.setSelectedModel(deepseekModel, for: .deepseek)
        store.setBudget(parseBudget(text: deepseekBudgetText), for: .deepseek)
        deepseekApiKeySaved = store.apiKey(for: .deepseek) != nil
    }

    func clearDeepSeekKey() {
        store.clearApiKey(for: .deepseek)
        deepseekApiKeySaved = false
    }

    func clearDeepSeekBudget() {
        store.setBudget(nil, for: .deepseek)
        deepseekBudgetText = ""
    }

    private func parseBudget(text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: "")
        return Double(normalized)
    }
}
