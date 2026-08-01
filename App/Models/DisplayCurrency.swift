import Foundation

enum DisplayCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case vnd = "VND"

    var id: String {
        rawValue
    }

    func amount(fromUSD amount: Double, exchangeRateUSDToVND: Double) -> Double {
        switch self {
        case .usd:
            return amount
        case .vnd:
            return amount * exchangeRateUSDToVND
        }
    }

    func formatted(fromUSD amount: Double, exchangeRateUSDToVND: Double) -> String {
        switch self {
        case .usd:
            return amount.currency
        case .vnd:
            return self.amount(fromUSD: amount, exchangeRateUSDToVND: exchangeRateUSDToVND).vndCurrency
        }
    }
}
