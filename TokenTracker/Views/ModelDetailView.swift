import SwiftUI

struct ModelDetailView: View {
    let item: ProviderUsageItem
    let samples: [TokenUsageSample]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                LineChartView(series: [chartSeries])

                HStack {
                    statBlock(title: "已用", value: format(item.usage.used))
                    statBlock(title: "剩余", value: format(item.usage.remaining))
                    statBlock(title: "上限", value: limitValue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("最近记录")
                        .font(.headline)

                    ForEach(recentSamples) { sample in
                        HStack {
                            Text(sample.timestamp, style: .time)
                            Spacer()
                            Text("已用: \(format(sample.used))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(item.provider.displayName)
    }

    private var chartSeries: ChartSeries {
        ChartSeries(
            id: item.provider.id,
            name: item.provider.displayName,
            color: item.provider.id.accentColor,
            points: samples.sorted { $0.timestamp < $1.timestamp }.map { $0.used }
        )
    }

    private var recentSamples: [TokenUsageSample] {
        let sorted = samples.sorted { $0.timestamp > $1.timestamp }
        return Array(sorted.prefix(10))
    }

    private var limitValue: String {
        if item.usage.limit <= 0 {
            return "--"
        }
        return format(item.usage.limit)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("单位: \(item.usage.unit.label)")
                .font(.caption)
                .foregroundColor(.secondary)
            if let eta = item.usage.etaDepletion {
                Text("预计耗尽: \(formatTime(eta))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = item.usage.unit.fractionDigits
        formatter.minimumFractionDigits = item.usage.unit.fractionDigits
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted) \(item.usage.unit.label)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
