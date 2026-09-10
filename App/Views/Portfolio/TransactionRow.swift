import SwiftUI

struct TransactionRow: View {
    let transaction: BuyTransaction
    let displayCurrency: DisplayCurrency
    let assetCurrency: AssetCurrency
    let exchangeRateUSDToVND: Double
    let onDeduct: () -> Void
    let onEdit: () -> Void

    var body: some View {
        let unitPriceUSD = assetCurrency.usdAmount(from: transaction.unitPrice, exchangeRateUSDToVND: exchangeRateUSDToVND)
        let subtotalUSD = assetCurrency.usdAmount(from: transaction.totalCost, exchangeRateUSDToVND: exchangeRateUSDToVND)

        HStack(spacing: 6) {
            Text(transaction.units.formattedUnits)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(displayCurrency.formatted(fromUSD: unitPriceUSD, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(XQPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(displayCurrency.formatted(fromUSD: subtotalUSD, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .minimumScaleFactor(0.64)
                .lineLimit(1)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(XQPalette.softFill, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(XQPalette.ink)
            .accessibilityLabel("Edit units for buy lot from \(transaction.date)")
            .accessibilityIdentifier(XQAccessibilityIdentifier.editTransactionButton.rawValue)

            Button(role: .destructive) {
                onDeduct()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 30, height: 30)
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
