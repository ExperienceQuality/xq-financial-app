import SwiftUI

struct PriceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var asset: FinanceAsset
    @State private var priceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Price") {
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .accessibilityIdentifier(XQAccessibilityIdentifier.currentPriceField.rawValue)

                    Text("Current price is entered in \(asset.nativeCurrency.label). Updating price changes total value only; it does not change units owned.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Update \(asset.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let price = priceText.decimalNumber {
                            asset.updateCurrentPrice(price)
                        }
                        dismiss()
                    }
                    .disabled(priceText.decimalNumber == nil)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.priceSaveButton.rawValue)
                }
            }
            .onAppear {
                priceText = String(format: "%.2f", asset.currentPrice)
            }
        }
    }
}
