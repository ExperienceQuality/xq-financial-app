import Foundation

extension Double {
    var currency: String {
        Self.currencyFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    var compactCurrency: String {
        Self.compactCurrencyFormatter.string(from: NSNumber(value: self)) ?? "$0"
    }

    var vndCurrency: String {
        "VND \(Self.vndFormatter.string(from: NSNumber(value: self)) ?? "0")"
    }

    var signedCurrency: String {
        let formatted = abs(self).currency
        return self >= 0 ? "+\(formatted)" : "-\(formatted)"
    }

    var signedPercent: String {
        let percent = abs(self) * 100
        return "\(self >= 0 ? "+" : "-")\(String(format: "%.2f", percent))%"
    }

    var formattedUnits: String {
        String(format: "%.3f", self)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let compactCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let vndFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()
}

extension String {
    var decimalNumber: Double? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

extension Date {
    var buyLotDate: String {
        Self.buyLotFormatter.string(from: self)
    }

    private static let buyLotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
