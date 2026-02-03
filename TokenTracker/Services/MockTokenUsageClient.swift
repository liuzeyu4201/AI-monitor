import Foundation

protocol TokenUsageClient {
    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void)
}

final class MockTokenUsageClient: TokenUsageClient {
    private let providerId: ProviderID
    private let queue = DispatchQueue(label: "mock-usage", qos: .userInitiated)

    init(providerId: ProviderID) {
        self.providerId = providerId
    }

    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void) {
        // MOCK ONLY: Replace this method with the provider's real token usage API call.
        // Keep the signature intact so the view model and repository don't need changes.
        queue.asyncAfter(deadline: .now() + 0.3) {
            let now = Date()
            let baselineLimit = cached?.limit ?? Double(Int.random(in: 200_000...2_000_000))
            let baselineRemaining = cached?.remaining ?? Double.random(in: baselineLimit * 0.5...baselineLimit)
            let baselineRate = cached?.burnRatePerMinute ?? Double.random(in: 200...1200)

            let elapsedMinutes = max(0, now.timeIntervalSince(cached?.updatedAt ?? now) / 60)
            let consumed = elapsedMinutes * baselineRate
            let remaining = max(0, baselineRemaining - consumed)
            let adjustedRate = max(0, baselineRate * Double.random(in: 0.9...1.1))

            let usage = TokenUsage(
                providerId: self.providerId,
                remaining: remaining,
                limit: baselineLimit,
                updatedAt: now,
                burnRatePerMinute: adjustedRate,
                unit: .tokens
            )

            completion(.success(usage))
        }
    }
}
