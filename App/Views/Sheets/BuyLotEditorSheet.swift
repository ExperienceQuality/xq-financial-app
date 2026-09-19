import SwiftUI

struct BuyLotEditorSheet: View {
    enum Mode {
        case add
        case edit(BuyTransaction)
    }

    @Environment(\.dismiss) private var dismiss
    let asset: FinanceAsset
    let mode: Mode
    let onSave: (Double, Double) -> Bool

    @State private var unitsText: String
    @State private var unitPriceText: String

    init(asset: FinanceAsset, mode: Mode, onSave: @escaping (Double, Double) -> Bool) {
        self.asset = asset
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .add:
            _unitsText = State(initialValue: "")
            _unitPriceText = State(initialValue: "")
        case .edit(let transaction):
            _unitsText = State(initialValue: Self.draftText(transaction.units))
            _unitPriceText = State(initialValue: Self.draftText(transaction.unitPrice))
        }
    }

    private var units: Double? {
        unitsText.decimalNumber
    }

    private var unitPrice: Double? {
        unitPriceText.decimalNumber
    }

    private var subtotal: Double? {
        guard let units, let unitPrice else { return nil }
        let value = units * unitPrice
        return value.isFinite ? value : nil
    }

    private var canSave: Bool {
        guard let units, let unitPrice, subtotal != nil else { return false }
        return units.isFinite && unitPrice.isFinite && units > 0 && unitPrice > 0
    }

    private var title: String {
        switch mode {
        case .add: return "Add \(asset.symbol) Lot"
        case .edit: return "Edit \(asset.symbol) Lot"
        }
    }

    private var actionTitle: String {
        switch mode {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }

    private var helpText: String {
        switch mode {
        case .add:
            return "Buy lots are entered in \(asset.nativeCurrency.label). Adding a lot increases units owned and current total value for this asset."
        case .edit:
            return "Buy lots are entered in \(asset.nativeCurrency.label). Updating this lot changes units owned and cost basis without changing the current market price."
        }
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
                    Text(helpText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle) {
                        guard let units, let unitPrice, onSave(units, unitPrice) else { return }
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotSaveButton.rawValue)
                }
            }
        }
    }

    private static func draftText(_ value: Double) -> String {
        let text = String(value)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}
