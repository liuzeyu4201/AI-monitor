import Foundation

final class DeepSeekTokenUsageClient: TokenUsageClient {
    private let settingsStore: ProviderSettingsStore
    private let apiKeyOverride: String?
    private let session: URLSession

    init(settingsStore: ProviderSettingsStore = .shared, apiKeyOverride: String? = nil, session: URLSession? = nil) {
        self.settingsStore = settingsStore
        self.apiKeyOverride = apiKeyOverride
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.waitsForConnectivity = false
            config.timeoutIntervalForRequest = 12
            config.timeoutIntervalForResource = 12
            self.session = URLSession(configuration: config)
        }
    }

    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void) {
        let apiKey = apiKeyOverride ?? settingsStore.apiKey(for: .deepseek)
        guard let apiKey = apiKey else {
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
        request.timeoutInterval = 12
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(TokenUsageClientError.invalidResponse))
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) }
                let trimmed: String?
                if let body = body, body.count > 300 {
                    trimmed = String(body.prefix(300)) + "..."
                } else {
                    trimmed = body
                }
                completion(.failure(TokenUsageClientError.httpStatus(http.statusCode, trimmed)))
                return
            }

            guard let data = data else {
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
                let previousLimit = previous?.limit ?? 0
                let limit = max(budget ?? 0, balanceValue, previousLimit)

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
