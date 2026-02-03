import Foundation

final class TokenUsageRepository {
    private let store: TokenUsageStore
    private var registry: ProviderRegistry
    private let historyStore: TokenUsageHistoryStore
    private var cache: [ProviderID: TokenUsage]
    private var history: [ProviderID: [TokenUsageSample]]
    private let queue = DispatchQueue(label: "token-usage-repo")
    private let retentionDays = 7.0

    init(store: TokenUsageStore = LocalTokenUsageStore(), historyStore: TokenUsageHistoryStore = LocalTokenUsageHistoryStore(), registry: ProviderRegistry = .default()) {
        self.store = store
        self.historyStore = historyStore
        self.registry = registry
        self.cache = store.load()
        self.history = historyStore.load()
        pruneHistory()
        historyStore.save(history)
    }

    func updateRegistry(_ registry: ProviderRegistry) {
        self.registry = registry
    }

    func loadCached() -> [ProviderID: TokenUsage] {
        cache
    }

    func loadHistory() -> [ProviderID: [TokenUsageSample]] {
        history
    }

    func refreshAll(completion: @escaping ([ProviderID: TokenUsage]) -> Void) {
        let providers = registry.providers
        if providers.isEmpty {
            completion(cache)
            return
        }

        var updated = cache
        let group = DispatchGroup()

        for provider in providers {
            guard let client = registry.clients[provider.id] else { continue }
            group.enter()
            client.fetchUsage(for: provider, cached: cache[provider.id]) { result in
                switch result {
                case .success(let usage):
                    self.queue.async {
                        updated[provider.id] = usage
                        group.leave()
                    }
                case .failure:
                    self.queue.async {
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: queue) {
            self.cache = updated
            self.store.save(updated)
            self.recordSamples(from: updated)
            DispatchQueue.main.async {
                completion(updated)
            }
        }
    }

    func updateManual(providerId: ProviderID, remaining: Double, limit: Double) {
        let usage = TokenUsage(
            providerId: providerId,
            remaining: max(0, remaining),
            limit: max(0, limit),
            updatedAt: Date(),
            burnRatePerMinute: cache[providerId]?.burnRatePerMinute ?? 0,
            unit: cache[providerId]?.unit ?? .tokens
        )
        cache[providerId] = usage
        store.save(cache)
        recordSamples(from: [providerId: usage])
    }

    private func recordSamples(from usage: [ProviderID: TokenUsage]) {
        for entry in usage.values {
            appendSample(for: entry)
        }
        pruneHistory()
        historyStore.save(history)
    }

    private func appendSample(for usage: TokenUsage) {
        var samples = history[usage.providerId] ?? []
        samples.append(TokenUsageSample(providerId: usage.providerId, remaining: usage.remaining, limit: usage.limit, timestamp: usage.updatedAt))
        history[usage.providerId] = samples
    }

    private func pruneHistory() {
        let cutoff = Date().addingTimeInterval(-retentionDays * 24 * 60 * 60)
        for (providerId, samples) in history {
            let pruned = samples.filter { $0.timestamp >= cutoff }
            history[providerId] = pruned
        }
    }
}
