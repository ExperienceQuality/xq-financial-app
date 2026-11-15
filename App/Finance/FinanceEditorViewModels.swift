import FinanceCore
import Foundation
import Observation

@MainActor
@Observable
final class AssetEditorViewModel {
    private let store: FinanceStore
    private let coordinator: any FinanceCoordinating

    var code = ""
    var name = ""
    var currency = FinancialCurrency.usd
    var price = "0"
    var errorMessage: String?

    init(store: FinanceStore, coordinator: any FinanceCoordinating) {
        self.store = store
        self.coordinator = coordinator
    }

    func save() {
        guard let parsedPrice = price.decimalInput else {
            errorMessage = FinanceStoreError.assetPriceInvalid.errorDescription
            return
        }
        do {
            try store.send(.createAsset(
                id: UUID(),
                code: code,
                name: name,
                currency: currency,
                price: parsedPrice
            ))
            coordinator.dismissSheet()
        } catch {
            errorMessage = error.financeMessage
        }
    }
}

@MainActor
@Observable
final class PriceEditorViewModel {
    private let store: FinanceStore
    private let coordinator: any FinanceCoordinating
    let assetID: UUID

    var price = ""
    var errorMessage: String?

    init(store: FinanceStore, assetID: UUID, coordinator: any FinanceCoordinating) {
        self.store = store
        self.assetID = assetID
        self.coordinator = coordinator
        price = store.asset(id: assetID)?.price.plainNumber ?? ""
    }

    func save() {
        guard let asset = store.asset(id: assetID), let value = price.decimalInput else {
            errorMessage = FinanceStoreError.assetPriceInvalid.errorDescription
            return
        }
        do {
            try store.send(.updateAsset(
                assetID: asset.id,
                code: asset.code,
                name: asset.name,
                currency: asset.currency,
                price: value
            ))
            coordinator.dismissSheet()
        } catch {
            errorMessage = error.financeMessage
        }
    }
}

@MainActor
@Observable
final class UnitEditorViewModel {
    private let store: FinanceStore
    private let coordinator: any FinanceCoordinating
    let assetID: UUID
    let operation: UnitOperation

    var amount = ""
    var errorMessage: String?

    var availableUnits: Double? {
        store.asset(id: assetID)?.totalUnits
    }

    init(
        store: FinanceStore,
        assetID: UUID,
        operation: UnitOperation,
        coordinator: any FinanceCoordinating
    ) {
        self.store = store
        self.assetID = assetID
        self.operation = operation
        self.coordinator = coordinator
    }

    func save() {
        guard let value = amount.decimalInput else {
            errorMessage = FinanceStoreError.unitsInvalid.errorDescription
            return
        }
        do {
            let transactionID = UUID()
            if operation == .add {
                try store.send(.addUnits(
                    assetID: assetID,
                    transactionID: transactionID,
                    occurredAt: .now,
                    units: value
                ))
            } else {
                try store.send(.subtractUnits(
                    assetID: assetID,
                    transactionID: transactionID,
                    occurredAt: .now,
                    units: value
                ))
            }
            coordinator.dismissSheet()
        } catch {
            errorMessage = error.financeMessage
        }
    }
}

@MainActor
@Observable
final class ExchangeRateEditorViewModel {
    private let store: FinanceStore
    private let coordinator: any FinanceCoordinating

    var rate = ""
    var errorMessage: String?

    init(store: FinanceStore, coordinator: any FinanceCoordinating) {
        self.store = store
        self.coordinator = coordinator
        rate = store.snapshot.exchangeRateUSDToVND.plainNumber
    }

    func save() {
        guard let value = rate.decimalInput else {
            errorMessage = FinanceStoreError.exchangeRateInvalid.errorDescription
            return
        }
        do {
            try store.send(.updateExchangeRate(value))
            coordinator.dismissSheet()
        } catch {
            errorMessage = error.financeMessage
        }
    }
}

extension String {
    var decimalInput: Double? {
        Double(
            trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        )
    }
}

extension Double {
    var plainNumber: String {
        formatted(.number.grouping(.never).precision(.fractionLength(0...6)))
    }

    var unitsDisplay: String { plainNumber }

    var signedUnitsDisplay: String {
        "\(self >= 0 ? "+" : "−")\(abs(self).unitsDisplay)"
    }

    var vndDisplay: String {
        Self.vndFormatter.string(from: NSNumber(value: self)) ?? "₫0"
    }

    func nativeDisplay(currency: FinancialCurrency) -> String {
        switch currency {
        case .usd:
            Self.usdFormatter.string(from: NSNumber(value: self)) ?? "$0"
        case .vnd:
            vndDisplay
        }
    }

    private static let vndFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let usdFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}
