import SwiftUI

struct ExchangeRateEditorView: View {
    let exchangeRateUSDToVND: Double
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("USD to VND")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(XQPalette.muted)

                Text("1 USD = \(String(format: "%.0f", exchangeRateUSDToVND)) VND")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(XQPalette.ink)
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                HStack(spacing: 8) {
                    Text(String(format: "%.0f", exchangeRateUSDToVND))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(XQPalette.ink)

                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(XQPalette.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(XQPalette.softFill, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(XQPalette.divider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit exchange rate")
            .accessibilityIdentifier(XQAccessibilityIdentifier.exchangeRateEditButton.rawValue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(XQPalette.divider, lineWidth: 1)
        )
    }
}
