import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var editingItem: ProviderUsageItem?

    var body: some View {
        NavigationView {
            List {
                Section(header: headerView) {
                    ForEach(viewModel.items) { item in
                        ProviderRowView(item: item) {
                            editingItem = item
                        }
                    }
                }

                Section(header: Text("Trends")) {
                    ForEach(viewModel.items) { item in
                        TrendCardView(
                            item: item,
                            samples: viewModel.history[item.provider.id] ?? []
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Token Tracker", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: viewModel.refresh) {
                Image(systemName: "arrow.clockwise")
            })
        }
        .sheet(item: $editingItem) { item in
            ManualAdjustView(
                provider: item.provider,
                initialRemaining: item.usage.remaining,
                initialLimit: item.usage.limit,
                unit: item.usage.unit
            ) { remaining, limit in
                viewModel.updateManual(providerId: item.provider.id, remaining: remaining, limit: limit)
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Providers")
                .font(.headline)
            if let lastRefresh = viewModel.lastRefresh {
                Text("Last refresh: \(formatted(date: lastRefresh))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Last refresh: --")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .textCase(nil)
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
