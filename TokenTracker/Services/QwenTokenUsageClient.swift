import Foundation

final class QwenTokenUsageClient: TokenUsageClient {
    private let settingsStore: ProviderSettingsStore
    private let accessKeyOverride: String?
    private let accessSecretOverride: String?
    private let baseURLOverride: String?
    private let modelOverride: String?
    private let session: URLSession

    init(settingsStore: ProviderSettingsStore = .shared, accessKeyOverride: String? = nil, accessSecretOverride: String? = nil, baseURLOverride: String? = nil, modelOverride: String? = nil, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.accessKeyOverride = accessKeyOverride
        self.accessSecretOverride = accessSecretOverride
        self.baseURLOverride = baseURLOverride
        self.modelOverride = modelOverride
        self.session = session
    }

    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void) {
        let accessKey = accessKeyOverride ?? settingsStore.qwenAccessKey()
        let accessSecret = accessSecretOverride ?? settingsStore.qwenAccessSecret()
        let baseURL = baseURLOverride ?? settingsStore.qwenMonitoringBaseURL()

        guard let accessKey = accessKey, let accessSecret = accessSecret, let baseURL = baseURL, !baseURL.isEmpty else {
            completion(.failure(TokenUsageClientError.missingApiKey))
            return
        }

        let now = Date()
        let endTime = Int(now.timeIntervalSince1970)
        let startTime = endTime - 5 * 60

        var query = "model_usage"
        let model = modelOverride ?? settingsStore.selectedModel(for: .qwen)
        if !model.isEmpty {
            query += "{model=\"\(model)\"}"
        }

        var trimmedBase = baseURL
        if trimmedBase.hasSuffix("/") {
            trimmedBase.removeLast()
        }

        guard var components = URLComponents(string: trimmedBase + "/api/v1/query_range") else {
            completion(.failure(TokenUsageClientError.invalidResponse))
            return
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "start", value: String(startTime)),
            URLQueryItem(name: "end", value: String(endTime)),
            URLQueryItem(name: "step", value: "60s")
        ]

        guard let url = components.url else {
            completion(.failure(TokenUsageClientError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        let credentials = "\(accessKey):\(accessSecret)"
        if let credentialData = credentials.data(using: .utf8) {
            let base64 = credentialData.base64EncodedString()
            request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data else {
                completion(.failure(TokenUsageClientError.invalidResponse))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PrometheusResponse.self, from: data)
                let lastValues = decoded.data.result.flatMap { $0.values }.sorted { $0.timestamp < $1.timestamp }
                let usedTokens: Double
                if lastValues.count >= 2 {
                    let last = lastValues[lastValues.count - 1]
                    let prev = lastValues[lastValues.count - 2]
                    usedTokens = max(0, last.value - prev.value)
                } else if let last = lastValues.last {
                    usedTokens = max(0, last.value)
                } else {
                    usedTokens = 0
                }

                let budget = self.settingsStore.budget(for: .qwen)
                let limit = max(budget ?? 0, usedTokens)
                let remaining = max(0, limit - usedTokens)

                let previousUsed = cached?.used ?? 0
                let minutes = max(1.0 / 60.0, now.timeIntervalSince(cached?.updatedAt ?? now) / 60)
                let burnRate = max(0, usedTokens - previousUsed) / minutes

                let usage = TokenUsage(
                    providerId: .qwen,
                    remaining: remaining,
                    limit: limit,
                    updatedAt: now,
                    burnRatePerMinute: burnRate,
                    unit: .tokens
                )

                completion(.success(usage))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

private struct PrometheusResponse: Codable {
    let status: String
    let data: PrometheusData
}

private struct PrometheusData: Codable {
    let resultType: String
    let result: [PrometheusResult]
}

private struct PrometheusResult: Codable {
    let values: [PrometheusValue]
}

private struct PrometheusValue: Codable {
    let timestamp: Double
    let value: Double

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let timestampValue = try DoubleOrString(from: &container).doubleValue
        let valueValue = try DoubleOrString(from: &container).doubleValue
        self.timestamp = timestampValue
        self.value = valueValue
    }
}

private struct DoubleOrString: Codable {
    let doubleValue: Double

    init(from decoder: Decoder) throws {
        if let double = try? decoder.singleValueContainer().decode(Double.self) {
            doubleValue = double
        } else {
            let string = try decoder.singleValueContainer().decode(String.self)
            doubleValue = Double(string) ?? 0
        }
    }

    init(from container: inout UnkeyedDecodingContainer) throws {
        if let double = try? container.decode(Double.self) {
            doubleValue = double
        } else {
            let string = try container.decode(String.self)
            doubleValue = Double(string) ?? 0
        }
    }
}
