import SwiftUI

struct TrendCardView: View {
    let item: ProviderUsageItem
    let samples: [TokenUsageSample]

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var latestSample: TokenUsageSample? {
        samples.max { $0.timestamp < $1.timestamp }
    }

    private var minRemaining: Double? {
        samples.map { $0.remaining }.min()
    }

    private var maxRemaining: Double? {
        samples.map { $0.remaining }.max()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.provider.displayName)
                    .font(.headline)
                    .foregroundColor(item.provider.id.accentColor)
                Spacer()
                Text("Samples: \(samples.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TrendChartView(samples: samples, lineColor: item.provider.id.accentColor)

            HStack {
                Text("Latest: \(format(latestSample?.remaining ?? 0, unit: item.usage.unit))")
                Spacer()
                if let minRemaining = minRemaining, let maxRemaining = maxRemaining {
                    Text("Min/Max: \(format(minRemaining, unit: item.usage.unit)) / \(format(maxRemaining, unit: item.usage.unit))")
                } else {
                    Text("Min/Max: --")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func format(_ value: Double, unit: UsageUnit) -> String {
        TrendCardView.numberFormatter.maximumFractionDigits = unit.fractionDigits
        TrendCardView.numberFormatter.minimumFractionDigits = unit.fractionDigits
        let formatted = TrendCardView.numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted) \(unit.label)"
    }
}
