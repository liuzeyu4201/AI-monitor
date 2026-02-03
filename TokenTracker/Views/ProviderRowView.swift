import SwiftUI

struct ProviderRowView: View {
    let item: ProviderUsageItem
    let onAdjust: () -> Void

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.provider.displayName)
                    .font(.headline)
                    .foregroundColor(item.provider.id.accentColor)
                Spacer()
                Button("Adjust", action: onAdjust)
                    .font(.subheadline)
            }

            ProgressView(value: item.usage.remaining, total: max(item.usage.limit, 1))
                .accentColor(item.provider.id.accentColor)

            HStack {
                Text("Remaining: \(format(item.usage.remaining, unit: item.usage.unit))")
                Spacer()
                Text(limitText)
            }
            .font(.subheadline)

            HStack {
                Text("Burn: \(format(item.usage.burnRatePerMinute, unit: item.usage.unit)) / min")
                Spacer()
                if let eta = item.usage.etaDepletion {
                    Text("ETA: \(ProviderRowView.dateFormatter.string(from: eta))")
                } else {
                    Text("ETA: --")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text("Updated: \(ProviderRowView.dateFormatter.string(from: item.usage.updatedAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var limitText: String {
        if item.usage.limit <= 0 {
            return "Limit: --"
        }
        return "Limit: \(format(item.usage.limit, unit: item.usage.unit))"
    }

    private func format(_ value: Double, unit: UsageUnit) -> String {
        ProviderRowView.numberFormatter.maximumFractionDigits = unit.fractionDigits
        ProviderRowView.numberFormatter.minimumFractionDigits = unit.fractionDigits
        let formatted = ProviderRowView.numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted) \(unit.label)"
    }
}
