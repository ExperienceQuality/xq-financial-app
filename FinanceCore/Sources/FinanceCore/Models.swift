import Foundation

public enum FinancialCurrency: String, Codable, CaseIterable, Identifiable, Sendable {
    case usd = "USD"
    case vnd = "VND"

    public var id: String { rawValue }
}

public struct UnitTransaction: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let units: Double

    public init(id: UUID, occurredAt: Date, units: Double) {
        self.id = id
        self.occurredAt = occurredAt
        self.units = units
    }
}

public struct FinancialAsset: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var code: String
    public var name: String
    public var currency: FinancialCurrency
    public var price: Double
    public var transactions: [UnitTransaction]

    public init(
        id: UUID,
        code: String,
        name: String,
        currency: FinancialCurrency,
        price: Double,
        transactions: [UnitTransaction] = []
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.currency = currency
        self.price = price
        self.transactions = transactions
    }

    public var totalUnits: Double {
        transactions.reduce(0) { $0 + $1.units }
    }

    public var nativeValue: Double {
        totalUnits * price
    }

    public func valueInVND(exchangeRateUSDToVND: Double) -> Double {
        switch currency {
        case .usd:
            nativeValue * exchangeRateUSDToVND
        case .vnd:
            nativeValue
        }
    }
}

public struct FinancialSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 3
    public static let defaultExchangeRateUSDToVND = 25_500.0

    public var schemaVersion: Int
    public var exchangeRateUSDToVND: Double
    public var assets: [FinancialAsset]

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        exchangeRateUSDToVND: Double = Self.defaultExchangeRateUSDToVND,
        assets: [FinancialAsset] = []
    ) {
        self.schemaVersion = schemaVersion
        self.exchangeRateUSDToVND = exchangeRateUSDToVND
        self.assets = assets
    }

    public var totalValueInVND: Double {
        assets.reduce(0) {
            $0 + $1.valueInVND(exchangeRateUSDToVND: exchangeRateUSDToVND)
        }
    }
}
