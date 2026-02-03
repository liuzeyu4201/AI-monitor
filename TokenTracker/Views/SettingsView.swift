import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("DeepSeek"), footer: Text("Balance is pulled from the DeepSeek balance API. Tokens are shown as balance units until a usage endpoint is available.")) {
                    Picker("Model", selection: $viewModel.deepseekModel) {
                        ForEach(ProviderCatalog.models(for: .deepseek), id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }

                    SecureField("API Key", text: $viewModel.deepseekApiKey)

                    if viewModel.deepseekApiKeySaved {
                        Text("API key saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextField("Budget (optional, balance currency)", text: $viewModel.deepseekBudgetText)
                        .keyboardType(.decimalPad)

                    Button("Save") {
                        viewModel.saveDeepSeek()
                        onSave()
                    }

                    if viewModel.deepseekApiKeySaved {
                        Button(action: {
                            viewModel.clearDeepSeekKey()
                        }) {
                            Text("Clear API Key")
                                .foregroundColor(.red)
                        }
                    }

                    if !viewModel.deepseekBudgetText.isEmpty {
                        Button("Clear Budget") {
                            viewModel.clearDeepSeekBudget()
                        }
                    }
                }

                Section(header: Text("Coming Soon")) {
                    Text("OpenAI")
                    Text("Qwen")
                    Text("Zhipu")
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .onAppear {
                viewModel.load()
            }
        }
    }
}
