import SwiftUI

struct ManualAdjustView: View {
    let provider: Provider
    let initialRemaining: Double
    let initialLimit: Double
    let unit: UsageUnit
    let onSave: (Double, Double) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var remainingText: String
    @State private var limitText: String

    init(provider: Provider, initialRemaining: Double, initialLimit: Double, unit: UsageUnit, onSave: @escaping (Double, Double) -> Void) {
        self.provider = provider
        self.initialRemaining = initialRemaining
        self.initialLimit = initialLimit
        self.unit = unit
        self.onSave = onSave
        _remainingText = State(initialValue: ManualAdjustView.formatValue(initialRemaining, unit: unit))
        _limitText = State(initialValue: ManualAdjustView.formatValue(initialLimit, unit: unit))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Manual Override")) {
                    TextField("Remaining (\(unit.label))", text: $remainingText)
                        .keyboardType(.decimalPad)
                    TextField("Limit (\(unit.label))", text: $limitText)
                        .keyboardType(.decimalPad)
                }

                Section(footer: Text("These values are stored locally. Replace with real API data later.")) {
                    Button("Save") {
                        let remaining = parse(remainingText) ?? initialRemaining
                        let limit = parse(limitText) ?? initialLimit
                        onSave(remaining, limit)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationBarTitle(provider.displayName, displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func parse(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: "")
        return Double(normalized)
    }

    private static func formatValue(_ value: Double, unit: UsageUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = unit.fractionDigits
        formatter.minimumFractionDigits = unit.fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
