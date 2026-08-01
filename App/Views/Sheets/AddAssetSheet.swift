import SwiftUI

struct AddAssetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var name = ""
    @State private var nativeCurrency = AssetCurrency.usd
    @State private var startingPriceText = "0"

    let onAdd: (String, String, AssetCurrency, Double) -> Void

    private var canSave: Bool {
        !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Symbol", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.symbolField.rawValue)

                    TextField("Name", text: $name)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.nameField.rawValue)

                    Picker("Native currency", selection: $nativeCurrency) {
                        ForEach(AssetCurrency.allCases) { currency in
                            Text(currency.label).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.assetNativeCurrencyPicker.rawValue)
                }

                Section("Starting Price") {
                    TextField("Price", text: $startingPriceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.startingPriceField.rawValue)

                    Text("The price is stored in \(nativeCurrency.label). You can update it later.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(
                            symbol.trimmingCharacters(in: .whitespacesAndNewlines),
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            nativeCurrency,
                            startingPriceText.decimalNumber ?? 0
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.addAssetSaveButton.rawValue)
                }
            }
        }
    }
}
