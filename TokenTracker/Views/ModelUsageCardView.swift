import SwiftUI

struct ModelUsageCardView: View {
    let item: ProviderUsageItem

    var body: some View {
        HStack(spacing: 16) {
            UsageDonutView(usedFraction: usedFraction, color: item.provider.id.accentColor)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.provider.displayName)
                    .font(.headline)
                    .foregroundColor(item.provider.id.accentColor)

                Text("已用: \(format(item.usage.used, unit: item.usage.unit))")
                    .font(.subheadline)

                Text("剩余: \(format(item.usage.remaining, unit: item.usage.unit))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(limitLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var usedFraction: Double {
        guard item.usage.limit > 0 else { return 0 }
        return min(max(item.usage.used / item.usage.limit, 0), 1)
    }

    private var limitLabel: String {
        if item.usage.limit <= 0 {
            return "上限: --"
        }
        return "上限: \(format(item.usage.limit, unit: item.usage.unit))"
    }

    private func format(_ value: Double, unit: UsageUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = unit.fractionDigits
        formatter.minimumFractionDigits = unit.fractionDigits
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted) \(unit.label)"
    }
}
