import Foundation

enum AssetCurrency: String, CaseIterable, Codable, Identifiable {
    case usd = "USD"
    case vnd = "VND"

    var id: String {
        rawValue
    }

    var label: String {
        rawValue
    }

    func formatted(_ amount: Double) -> String {
        switch self {
        case .usd:
            return amount.currency
        case .vnd:
            return amount.vndCurrency
        }
    }

    func amount(fromUSD amount: Double, exchangeRateUSDToVND: Double) -> Double {
        switch self {
        case .usd:
            return amount
        case .vnd:
            return amount * exchangeRateUSDToVND
        }
    }

    func usdAmount(from amount: Double, exchangeRateUSDToVND: Double) -> Double {
        guard exchangeRateUSDToVND > 0 else { return 0 }
        switch self {
        case .usd:
            return amount
        case .vnd:
            return amount / exchangeRateUSDToVND
        }
    }
}
