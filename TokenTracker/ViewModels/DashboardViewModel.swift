import Foundation

struct ProviderUsageItem: Identifiable {
    let provider: Provider
    let usage: TokenUsage

    var id: ProviderID { provider.id }
}

final class DashboardViewModel: ObservableObject {
    @Published var items: [ProviderUsageItem] = []
    @Published var lastRefresh: Date?
    @Published var history: [ProviderID: [TokenUsageSample]] = [:]

    private var registry: ProviderRegistry
    private var repository: TokenUsageRepository
    private var timer: Timer?

    init(registry: ProviderRegistry = .default(), repository: TokenUsageRepository? = nil) {
        self.registry = registry
        self.repository = repository ?? TokenUsageRepository(registry: registry)
        rebuildItems(from: self.repository.loadCached())
        history = self.repository.loadHistory()
    }

    func start() {
        refresh()
        startAutoRefresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        repository.refreshAll { [weak self] usage in
            self?.rebuildItems(from: usage)
            self?.history = self?.repository.loadHistory() ?? [:]
            self?.lastRefresh = Date()
        }
    }

    func reloadProviders() {
        registry = .default()
        repository.updateRegistry(registry)
        rebuildItems(from: repository.loadCached())
        history = repository.loadHistory()
    }

    private func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func rebuildItems(from usage: [ProviderID: TokenUsage]) {
        items = registry.providers.map { provider in
            ProviderUsageItem(provider: provider, usage: usage[provider.id] ?? TokenUsage.empty(for: provider.id))
        }
    }
}
