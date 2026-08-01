import SwiftUI

struct ExchangeRateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exchangeRateUSDToVND: Double
    @State var initialText: String

    private var parsedValue: Double? {
        initialText.decimalNumber
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exchange Rate") {
                    TextField("USD to VND", text: $initialText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .accessibilityIdentifier(XQAccessibilityIdentifier.exchangeRateField.rawValue)

                    Text("Set how many VND equal 1 USD.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Update Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let parsedValue, parsedValue > 0 {
                            exchangeRateUSDToVND = parsedValue
                        }
                        dismiss()
                    }
                    .disabled(parsedValue == nil || parsedValue ?? 0 <= 0)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.exchangeRateSaveButton.rawValue)
                }
            }
        }
    }
}
