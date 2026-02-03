import Foundation

final class DeepSeekTokenUsageClient: TokenUsageClient {
    private let settingsStore: ProviderSettingsStore
    private let session: URLSession

    init(settingsStore: ProviderSettingsStore = .shared, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.session = session
    }

    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void) {
        guard let apiKey = settingsStore.apiKey(for: .deepseek) else {
            completion(.failure(TokenUsageClientError.missingApiKey))
            return
        }

        let baseURL = ProviderCatalog.baseURL(for: .deepseek) ?? "https://api.deepseek.com"
        guard let url = URL(string: baseURL + "/user/balance") else {
            completion(.failure(TokenUsageClientError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data else {
                completion(.failure(TokenUsageClientError.invalidResponse))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
                guard let balances = decoded.balance_infos, !balances.isEmpty else {
                    completion(.failure(TokenUsageClientError.invalidBalance))
                    return
                }

                let preferred = balances.first { $0.currency.uppercased() == "USD" } ?? balances[0]
                guard let balanceValue = preferred.totalBalanceValue else {
                    completion(.failure(TokenUsageClientError.invalidBalance))
                    return
                }

                let now = Date()
                let previous = cached
                let delta = max(0, (previous?.remaining ?? balanceValue) - balanceValue)
                let minutes = max(1.0 / 60.0, now.timeIntervalSince(previous?.updatedAt ?? now) / 60)
                let burnRate = delta / minutes

                let budget = self.settingsStore.budget(for: .deepseek)
                let limit = max(budget ?? 0, balanceValue)

                let usage = TokenUsage(
                    providerId: .deepseek,
                    remaining: balanceValue,
                    limit: limit,
                    updatedAt: now,
                    burnRatePerMinute: burnRate,
                    unit: .currency(preferred.currency)
                )

                completion(.success(usage))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

private struct DeepSeekBalanceResponse: Codable {
    let balance_infos: [DeepSeekBalanceInfo]?
}

private struct DeepSeekBalanceInfo: Codable {
    let currency: String
    let total_balance: String?

    var totalBalanceValue: Double? {
        guard let total_balance = total_balance else { return nil }
        return Double(total_balance)
    }
}
