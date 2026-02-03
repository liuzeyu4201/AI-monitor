import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                DisclosureGroup("添加 API") {
                    let candidates = viewModel.providersWithoutApiKey()
                    if candidates.isEmpty {
                        Text("所有模型都已添加")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(candidates, id: \.self) { providerId in
                            providerSection(providerId)
                        }
                    }
                }

                DisclosureGroup("已有 API") {
                    let existing = viewModel.providersWithApiKey()
                    if existing.isEmpty {
                        Text("暂无已保存的 API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(existing, id: \.self) { providerId in
                            providerSection(providerId)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .onAppear { viewModel.load() }
            .alert(isPresented: Binding(get: { viewModel.alertMessage != nil }, set: { _ in viewModel.alertMessage = nil })) {
                Alert(
                    title: Text(viewModel.alertIsSuccess ? "成功" : "失败"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("好的"))
                )
            }
        }
    }

    private func providerSection(_ providerId: ProviderID) -> some View {
        let showBudget = providerId == .deepseek || providerId == .openai || providerId == .qwen
        let footer = providerFooter(providerId)

        return Section(header: Text(providerTitle(providerId)), footer: Text(footer)) {
            TextField("模型", text: Binding(
                get: { viewModel.bindingModel(for: providerId) },
                set: { viewModel.setModel($0, for: providerId) }
            ))

            if providerId == .qwen {
                TextField("AccessKey", text: Binding(
                    get: { viewModel.bindingAccessKey(for: providerId) },
                    set: { viewModel.setAccessKey($0, for: providerId) }
                ))

                SecureField("AccessKeySecret", text: Binding(
                    get: { viewModel.bindingAccessSecret(for: providerId) },
                    set: { viewModel.setAccessSecret($0, for: providerId) }
                ))

                TextField("Monitoring API Base URL", text: Binding(
                    get: { viewModel.bindingMonitoringBaseURL(for: providerId) },
                    set: { viewModel.setMonitoringBaseURL($0, for: providerId) }
                ))
            } else {
                SecureField(providerId == .openai ? "Admin API Key" : "API Key", text: Binding(
                    get: { viewModel.bindingApiKey(for: providerId) },
                    set: { viewModel.setApiKey($0, for: providerId) }
                ))
            }

            if viewModel.apiKeySaved(for: providerId) {
                Text("已保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if showBudget {
                TextField("预算（可选，余额单位）", text: Binding(
                    get: { viewModel.bindingBudget(for: providerId) },
                    set: { viewModel.setBudget($0, for: providerId) }
                ))
                .keyboardType(.decimalPad)
            }

            Button("保存") {
                viewModel.save(providerId: providerId)
            }
            .disabled(viewModel.savingProviders.contains(providerId))

            if viewModel.savingProviders.contains(providerId) {
                Text("正在验证...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.apiKeySaved(for: providerId) {
                Button(action: {
                    viewModel.clearApiKey(for: providerId)
                    onSave()
                }) {
                    Text("清除配置")
                        .foregroundColor(.red)
                }
            }

            if showBudget && !viewModel.bindingBudget(for: providerId).isEmpty {
                Button("清除预算") {
                    viewModel.clearBudget(for: providerId)
                }
            }
        }
    }

    private func providerTitle(_ providerId: ProviderID) -> String {
        switch providerId {
        case .deepseek: return "DeepSeek"
        case .openai: return "OpenAI"
        case .qwen: return "Qwen"
        case .zhipu: return "Zhipu"
        }
    }

    private func providerFooter(_ providerId: ProviderID) -> String {
        switch providerId {
        case .deepseek:
            return "余额来自 DeepSeek balance API。"
        case .openai:
            return "使用 OpenAI 组织 usage 接口（需 Admin API Key）。"
        case .qwen:
            return "使用 Qwen Model Monitoring Prometheus API（需 AccessKey/Secret + HTTP API URL）。"
        case .zhipu:
            return "暂未接入 usage 接口。"
        }
    }
}
