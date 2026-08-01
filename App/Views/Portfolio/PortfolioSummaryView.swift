import SwiftUI

struct PortfolioSummaryView: View {
    let totalValue: Double
    let displayCurrency: DisplayCurrency
    let exchangeRateUSDToVND: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Portfolio total")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(XQPalette.muted)

            Text(displayCurrency.formatted(fromUSD: totalValue, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: displayCurrency == .usd ? 31 : 25, weight: .heavy, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            Text("1 USD = \(String(format: "%.0f", exchangeRateUSDToVND)) VND")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(XQPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(XQPalette.divider, lineWidth: 1)
        )
    }
}
