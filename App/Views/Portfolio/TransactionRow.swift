import SwiftUI

struct TransactionRow: View {
    let transaction: BuyTransaction
    let displayCurrency: DisplayCurrency
    let assetCurrency: AssetCurrency
    let exchangeRateUSDToVND: Double
    let onDeduct: () -> Void

    var body: some View {
        let unitPriceUSD = assetCurrency.usdAmount(from: transaction.unitPrice, exchangeRateUSDToVND: exchangeRateUSDToVND)
        let subtotalUSD = assetCurrency.usdAmount(from: transaction.totalCost, exchangeRateUSDToVND: exchangeRateUSDToVND)

        HStack(spacing: 10) {
            Text(transaction.units.formattedUnits)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 64, alignment: .leading)

            Text(displayCurrency.formatted(fromUSD: unitPriceUSD, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(XQPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(width: 84, alignment: .leading)

            Spacer(minLength: 4)

            Text(displayCurrency.formatted(fromUSD: subtotalUSD, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .frame(width: 86, alignment: .trailing)
                .minimumScaleFactor(0.64)
                .lineLimit(1)

            Button(role: .destructive) {
                onDeduct()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(XQPalette.destructive.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(XQPalette.destructive)
            .accessibilityLabel("Deduct transaction from \(transaction.date)")
            .accessibilityIdentifier(XQAccessibilityIdentifier.deductTransactionButton.rawValue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(XQAccessibilityIdentifier.transactionRow.rawValue)
    }
}
