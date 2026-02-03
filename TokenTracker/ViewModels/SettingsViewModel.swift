import Foundation

struct ProviderSettingsState {
    var model: String
    var apiKey: String
    var apiKeySaved: Bool
    var budgetText: String
    var accessKey: String
    var accessSecret: String
    var monitoringBaseURL: String

    static func empty() -> ProviderSettingsState {
        ProviderSettingsState(model: "", apiKey: "", apiKeySaved: false, budgetText: "", accessKey: "", accessSecret: "", monitoringBaseURL: "")
    }
}

final class SettingsViewModel: ObservableObject {
    @Published private(set) var providerStates: [ProviderID: ProviderSettingsState] = [:]
    @Published var alertMessage: String?
    @Published var alertIsSuccess: Bool = false
    @Published var savingProviders: Set<ProviderID> = []

    var onSaveSuccess: (() -> Void)?

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
        ProviderID.allCases.forEach { providerId in
            let selected = store.selectedModel(for: providerId)
            let model = selected.isEmpty ? ProviderCatalog.defaultModel(for: providerId) : selected
            let saved = isConfigured(providerId)
            let budgetText: String
            if let budget = store.budget(for: providerId) {
                budgetText = formatter.string(from: NSNumber(value: budget)) ?? ""
            } else {
                budgetText = ""
            }

            providerStates[providerId] = ProviderSettingsState(
                model: model,
                apiKey: "",
                apiKeySaved: saved,
                budgetText: budgetText,
                accessKey: "",
                accessSecret: "",
                monitoringBaseURL: providerId == .qwen ? (store.qwenMonitoringBaseURL() ?? "") : ""
            )
        }
    }

    func bindingModel(for providerId: ProviderID) -> String {
        providerStates[providerId]?.model ?? ""
    }

    func setModel(_ value: String, for providerId: ProviderID) {
        var state = providerStates[providerId] ?? .empty()
        state.model = value
        providerStates[providerId] = state
    }

    func bindingApiKey(for providerId: ProviderID) -> String {
        providerStates[providerId]?.apiKey ?? ""
    }

    func setApiKey(_ value: String, for providerId: ProviderID) {
        var state = providerStates[providerId] ?? .empty()
        state.apiKey = value
        providerStates[providerId] = state
    }

    func bindingBudget(for providerId: ProviderID) -> String {
        providerStates[providerId]?.budgetText ?? ""
    }

    func setBudget(_ value: String, for providerId: ProviderID) {
        var state = providerStates[providerId] ?? .empty()
        state.budgetText = value
        providerStates[providerId] = state
    }

    func bindingAccessKey(for providerId: ProviderID) -> String {
        providerStates[providerId]?.accessKey ?? ""
    }

    func setAccessKey(_ value: String, for providerId: ProviderID) {
        var state = providerStates[providerId] ?? .empty()
        state.accessKey = value
        providerStates[providerId] = state
    }

    func bindingAccessSecret(for providerId: ProviderID) -> String {
        providerStates[providerId]?.accessSecret ?? ""
    }

    func setAccessSecret(_ value: String, for providerId: ProviderID) {
        var state = providerStates[providerId] ?? .empty()
        state.accessSecret = value
        providerStates[providerId] = state
    }

    func bindingMonitoringBaseURL(for providerId: ProviderID) -> String {
        providerStates[providerId]?.monitoringBaseURL ?? ""
    }

    func setMonitoringBaseURL(_ value: String, for providerId: ProviderID) {
        var state = providerStates[providerId] ?? .empty()
        state.monitoringBaseURL = value
        providerStates[providerId] = state
    }

    func apiKeySaved(for providerId: ProviderID) -> Bool {
        providerStates[providerId]?.apiKeySaved ?? false
    }

    func providersWithApiKey() -> [ProviderID] {
        ProviderID.allCases.filter { apiKeySaved(for: $0) }
    }

    func providersWithoutApiKey() -> [ProviderID] {
        ProviderID.allCases.filter { !apiKeySaved(for: $0) }
    }

    func save(providerId: ProviderID) {
        let state = providerStates[providerId] ?? .empty()
        savingProviders.insert(providerId)

        validateConfiguration(providerId: providerId, state: state) { [weak self] result in
            guard let self = self else { return }
            self.savingProviders.remove(providerId)
            switch result {
            case .success:
                self.persist(providerId: providerId, state: state)

                var updated = state
                updated.apiKey = ""
                updated.accessKey = ""
                updated.accessSecret = ""
                updated.apiKeySaved = true
                self.providerStates[providerId] = updated

                self.alertIsSuccess = true
                self.alertMessage = "已连接成功并保存"
                self.onSaveSuccess?()
            case .failure(let error):
                self.alertIsSuccess = false
                self.alertMessage = error.localizedDescription
            }
        }
    }

    func clearApiKey(for providerId: ProviderID) {
        switch providerId {
        case .qwen:
            store.clearQwenAccessKey()
            store.clearQwenAccessSecret()
            store.setQwenMonitoringBaseURL(nil)
        case .openai, .deepseek, .zhipu:
            store.clearApiKey(for: providerId)
        }
        var state = providerStates[providerId] ?? .empty()
        state.apiKeySaved = false
        providerStates[providerId] = state
    }

    func clearBudget(for providerId: ProviderID) {
        store.setBudget(nil, for: providerId)
        var state = providerStates[providerId] ?? .empty()
        state.budgetText = ""
        providerStates[providerId] = state
    }

    private func parseBudget(text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: "")
        return Double(normalized)
    }

    private func isConfigured(_ providerId: ProviderID) -> Bool {
        switch providerId {
        case .qwen:
            return store.qwenAccessKey() != nil && store.qwenAccessSecret() != nil && store.qwenMonitoringBaseURL() != nil
        case .openai, .deepseek:
            return store.apiKey(for: providerId) != nil
        case .zhipu:
            return false
        }
    }

    private func persist(providerId: ProviderID, state: ProviderSettingsState) {
        switch providerId {
        case .qwen:
            let accessKey = state.accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let accessSecret = state.accessSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseURL = state.monitoringBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !accessKey.isEmpty {
                store.saveQwenAccessKey(accessKey)
            }
            if !accessSecret.isEmpty {
                store.saveQwenAccessSecret(accessSecret)
            }
            if !baseURL.isEmpty {
                store.setQwenMonitoringBaseURL(baseURL)
            }
            store.setSelectedModel(state.model, for: providerId)
            store.setBudget(parseBudget(text: state.budgetText), for: providerId)
        case .openai, .deepseek:
            let apiKey = state.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !apiKey.isEmpty {
                store.saveApiKey(for: providerId, value: apiKey)
            }
            store.setSelectedModel(state.model, for: providerId)
            store.setBudget(parseBudget(text: state.budgetText), for: providerId)
        case .zhipu:
            break
        }
    }

    private func validateConfiguration(providerId: ProviderID, state: ProviderSettingsState, completion: @escaping (Result<Void, ValidationError>) -> Void) {
        switch providerId {
        case .deepseek:
            let trimmedKey = state.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let apiKey = trimmedKey.isEmpty ? (store.apiKey(for: .deepseek) ?? "") : trimmedKey
            guard !apiKey.isEmpty else {
                completion(.failure(.custom("请先填写 API Key")))
                return
            }
            let client = DeepSeekTokenUsageClient(apiKeyOverride: apiKey)
            let provider = Provider(id: .deepseek, apiBaseURL: ProviderCatalog.baseURL(for: .deepseek))
            var finished = false
            func finish(_ result: Result<Void, ValidationError>) {
                guard !finished else { return }
                finished = true
                completion(result)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                finish(.failure(.custom("验证超时，请检查网络或 API Key")))
            }
            client.fetchUsage(for: provider, cached: nil) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        finish(.success(()))
                    case .failure(let error):
                        finish(.failure(.custom("连接失败：\(error.localizedDescription)")))
                    }
                }
            }
        case .openai:
            let trimmedKey = state.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let apiKey = trimmedKey.isEmpty ? (store.apiKey(for: .openai) ?? "") : trimmedKey
            guard !apiKey.isEmpty else {
                completion(.failure(.custom("请先填写 Admin API Key")))
                return
            }
            let client = OpenAITokenUsageClient(apiKeyOverride: apiKey, modelOverride: state.model)
            let provider = Provider(id: .openai, apiBaseURL: ProviderCatalog.baseURL(for: .openai))
            var finished = false
            func finish(_ result: Result<Void, ValidationError>) {
                guard !finished else { return }
                finished = true
                completion(result)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                finish(.failure(.custom("验证超时，请检查网络或 API Key")))
            }
            client.fetchUsage(for: provider, cached: nil) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        finish(.success(()))
                    case .failure(let error):
                        finish(.failure(.custom("连接失败：\(error.localizedDescription)")))
                    }
                }
            }
        case .qwen:
            let accessKeyInput = state.accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let accessSecretInput = state.accessSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseURLInput = state.monitoringBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            let accessKey = accessKeyInput.isEmpty ? (store.qwenAccessKey() ?? "") : accessKeyInput
            let accessSecret = accessSecretInput.isEmpty ? (store.qwenAccessSecret() ?? "") : accessSecretInput
            let baseURL = baseURLInput.isEmpty ? (store.qwenMonitoringBaseURL() ?? "") : baseURLInput
            guard !accessKey.isEmpty, !accessSecret.isEmpty, !baseURL.isEmpty else {
                completion(.failure(.custom("请填写 AccessKey / AccessKeySecret / Monitoring URL")))
                return
            }
            let client = QwenTokenUsageClient(accessKeyOverride: accessKey, accessSecretOverride: accessSecret, baseURLOverride: baseURL, modelOverride: state.model)
            let provider = Provider(id: .qwen, apiBaseURL: baseURL)
            var finished = false
            func finish(_ result: Result<Void, ValidationError>) {
                guard !finished else { return }
                finished = true
                completion(result)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                finish(.failure(.custom("验证超时，请检查网络或 AccessKey")))
            }
            client.fetchUsage(for: provider, cached: nil) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        finish(.success(()))
                    case .failure(let error):
                        finish(.failure(.custom("连接失败：\(error.localizedDescription)")))
                    }
                }
            }
        case .zhipu:
            completion(.failure(.custom("该模型暂未接入 usage 接口，无法校验")))
        }
    }
}

enum ValidationError: LocalizedError {
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .custom(let message):
            return message
        }
    }
}
