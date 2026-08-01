import SwiftUI

struct FinanceAsset: Identifiable {
    let id: UUID
    let symbol: String
    let name: String
    let nativeCurrency: AssetCurrency
    let accent: Color
    var currentPrice: Double
    var transactions: [BuyTransaction]

    var unitsOwned: Double {
        transactions.reduce(0) { $0 + $1.units }
    }

    var totalCost: Double {
        transactions.reduce(0) { $0 + $1.totalCost }
    }

    var currentValue: Double {
        unitsOwned * currentPrice
    }

    func currentValueInUSD(exchangeRateUSDToVND: Double) -> Double {
        nativeCurrency.usdAmount(from: currentValue, exchangeRateUSDToVND: exchangeRateUSDToVND)
    }

    mutating func addBuyLot(units: Double, unitPrice: Double, date: String) {
        let normalizedUnitPrice = max(0, unitPrice)
        let transaction = BuyTransaction(
            id: UUID(),
            date: date,
            units: max(0, units),
            unitPrice: normalizedUnitPrice
        )
        transactions.insert(transaction, at: 0)
        currentPrice = normalizedUnitPrice
    }

    mutating func updateCurrentPrice(_ price: Double) {
        currentPrice = max(0, price)
    }

    mutating func deduct(transactionID: UUID) {
        transactions.removeAll { $0.id == transactionID }
    }
}

extension FinanceAsset {
    static func accent(for symbol: String) -> Color {
        switch symbol.uppercased() {
        case "AAPL":
            return Color(red: 0.06, green: 0.11, blue: 0.2)
        case "BTC":
            return Color(red: 0.98, green: 0.58, blue: 0.04)
        case "ETH":
            return Color(red: 0.29, green: 0.38, blue: 0.83)
        default:
            return XQPalette.ink
        }
    }
}
