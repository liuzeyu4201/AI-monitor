import Foundation

final class OpenAITokenUsageClient: TokenUsageClient {
    private let settingsStore: ProviderSettingsStore
    private let apiKeyOverride: String?
    private let modelOverride: String?
    private let session: URLSession

    init(settingsStore: ProviderSettingsStore = .shared, apiKeyOverride: String? = nil, modelOverride: String? = nil, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.apiKeyOverride = apiKeyOverride
        self.modelOverride = modelOverride
        self.session = session
    }

    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void) {
        let apiKey = apiKeyOverride ?? settingsStore.apiKey(for: .openai)
        guard let apiKey = apiKey else {
            completion(.failure(TokenUsageClientError.missingApiKey))
            return
        }

        let now = Date()
        let endTime = Int(now.timeIntervalSince1970)
        let startTime = endTime - 5 * 60

        guard var components = URLComponents(string: "https://api.openai.com/v1/organization/usage/completions") else {
            completion(.failure(TokenUsageClientError.invalidResponse))
            return
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "start_time", value: String(startTime)),
            URLQueryItem(name: "end_time", value: String(endTime)),
            URLQueryItem(name: "bucket_width", value: "1m"),
            URLQueryItem(name: "limit", value: "5")
        ]

        let model = modelOverride ?? settingsStore.selectedModel(for: .openai)
        if !model.isEmpty {
            queryItems.append(URLQueryItem(name: "models", value: model))
        }

        components.queryItems = queryItems
        guard let url = components.url else {
            completion(.failure(TokenUsageClientError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
                let decoded = try JSONDecoder().decode(OpenAIUsageResponse.self, from: data)
                let bucket = decoded.data.max { $0.start_time < $1.start_time }
                let usedTokens = bucket?.results.reduce(0) { partial, result in
                    partial + result.totalTokens
                } ?? 0

                let used = Double(usedTokens)
                let budget = self.settingsStore.budget(for: .openai)
                let limit = max(budget ?? 0, used)
                let remaining = max(0, limit - used)

                let previousUsed = cached?.used ?? 0
                let minutes = max(1.0 / 60.0, now.timeIntervalSince(cached?.updatedAt ?? now) / 60)
                let burnRate = max(0, used - previousUsed) / minutes

                let usage = TokenUsage(
                    providerId: .openai,
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

private struct OpenAIUsageResponse: Codable {
    let data: [OpenAIUsageBucket]
}

private struct OpenAIUsageBucket: Codable {
    let start_time: Int
    let end_time: Int
    let results: [OpenAIUsageResult]
}

private struct OpenAIUsageResult: Codable {
    let input_tokens: Int?
    let output_tokens: Int?
    let input_audio_tokens: Int?
    let output_audio_tokens: Int?

    var totalTokens: Int {
        (input_tokens ?? 0) + (output_tokens ?? 0) + (input_audio_tokens ?? 0) + (output_audio_tokens ?? 0)
    }
}
