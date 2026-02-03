import SwiftUI

struct TokenUsageDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summarySection
                modelsSection
            }
            .padding()
        }
        .navigationTitle("用量监控")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("总览")
                .font(.headline)

            LineChartView(series: totalSeries)

            HStack {
                Text("总消耗折线图（按模型）")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let lastRefresh = viewModel.lastRefresh {
                    Text("更新 \(formatTime(lastRefresh))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var modelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模型用量")
                .font(.headline)

            if viewModel.items.isEmpty {
                Text("请在设置页添加 API Key 后显示数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: ModelDetailView(item: item, samples: viewModel.history[item.provider.id] ?? [])) {
                        ModelUsageCardView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                }
            }
        }
    }

    private var totalSeries: [ChartSeries] {
        let series = viewModel.items.map { item -> ChartSeries in
            let points = viewModel.history[item.provider.id]?.sorted { $0.timestamp < $1.timestamp }.map { $0.used } ?? []
            return ChartSeries(id: item.provider.id, name: item.provider.displayName, color: item.provider.id.accentColor, points: points)
        }
        return series
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
