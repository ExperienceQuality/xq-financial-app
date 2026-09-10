import SwiftUI

struct BuyLotEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var asset: FinanceAsset
    private let transaction: BuyTransaction?
    @State private var unitsText: String
    @State private var unitPriceText: String

    init(asset: Binding<FinanceAsset>, transaction: BuyTransaction? = nil) {
        _asset = asset
        self.transaction = transaction
        _unitsText = State(initialValue: transaction.map { String($0.units) } ?? "")
        _unitPriceText = State(initialValue: transaction.map { String($0.unitPrice) } ?? "")
    }

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
                        .disabled(transaction != nil)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotPriceField.rawValue)

                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(asset.nativeCurrency.formatted(subtotal ?? 0))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }

                Section {
                    Text(transaction == nil
                        ? "Buy lots are entered in \(asset.nativeCurrency.label). Adding a lot increases units owned and current total value for this asset."
                        : "Updating units changes the asset's total units and current total value. The lot's date and price stay unchanged.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(transaction == nil ? "Add \(asset.symbol) Lot" : "Edit \(asset.symbol) Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(transaction == nil ? "Add" : "Save") {
                        guard let units, let unitPrice else { return }
                        if let transaction {
                            asset.updateBuyLotUnits(transactionID: transaction.id, units: units)
                        } else {
                            asset.addBuyLot(units: units, unitPrice: unitPrice, date: Date.now.buyLotDate)
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotSaveButton.rawValue)
                }
            }
        }
    }
}
