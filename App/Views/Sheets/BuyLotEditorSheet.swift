import SwiftUI

struct BuyLotEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var asset: FinanceAsset
    @State private var unitsText = ""
    @State private var unitPriceText = ""

    private var units: Double? {
        unitsText.decimalNumber
    }

    private var unitPrice: Double? {
        unitPriceText.decimalNumber
    }

    private var subtotal: Double? {
        guard let units, let unitPrice else { return nil }
        return units * unitPrice
    }

    private var canSave: Bool {
        guard let units, let unitPrice else { return false }
        return units > 0 && unitPrice > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Buy Lot") {
                    TextField("Units", text: $unitsText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotUnitsField.rawValue)

                    TextField("Price per unit (\(asset.nativeCurrency.label))", text: $unitPriceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotPriceField.rawValue)

                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(asset.nativeCurrency.formatted(subtotal ?? 0))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }

                Section {
                    Text("Buy lots are entered in \(asset.nativeCurrency.label). Adding a lot increases units owned and current total value for this asset.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add \(asset.symbol) Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let units, let unitPrice else { return }
                        asset.addBuyLot(
                            units: units,
                            unitPrice: unitPrice,
                            date: Date.now.buyLotDate
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotSaveButton.rawValue)
                }
            }
        }
    }
}
