import Foundation
import Observation

public enum UnitOperation: String, Equatable, Sendable {
    case add
    case subtract
}

public enum FinanceCommand: Equatable, Sendable {
    case createAsset(
        id: UUID,
        code: String,
        name: String,
        currency: FinancialCurrency,
        price: Double
    )
    case updateAsset(
        assetID: UUID,
        code: String,
        name: String,
        currency: FinancialCurrency,
        price: Double
    )
    case deleteAsset(assetID: UUID)
    case addUnits(assetID: UUID, transactionID: UUID, occurredAt: Date, units: Double)
    case subtractUnits(assetID: UUID, transactionID: UUID, occurredAt: Date, units: Double)
    case updateExchangeRate(Double)
}

public enum FinanceStoreError: Error, Equatable, LocalizedError {
    case assetCodeRequired
    case assetNameRequired
    case assetPriceInvalid
    case assetNotFound
    case duplicateAssetID
    case duplicateTransactionID
    case unitsInvalid
    case insufficientUnits
    case exchangeRateInvalid

    public var errorDescription: String? {
        switch self {
        case .assetCodeRequired:
            "Enter an asset code."
        case .assetNameRequired:
            "Enter an asset name."
        case .assetPriceInvalid:
            "Price must be zero or greater."
        case .assetNotFound:
            "The asset could not be found."
        case .duplicateAssetID:
            "The asset already exists."
        case .duplicateTransactionID:
            "The unit transaction already exists."
        case .unitsInvalid:
            "Units must be greater than zero."
        case .insufficientUnits:
            "Subtracting these units would make the balance negative."
        case .exchangeRateInvalid:
            "Exchange rate must be greater than zero."
        }
    }
}

public protocol FinancePersisting {
    func load() throws -> FinancialSnapshot?
    func save(_ snapshot: FinancialSnapshot) throws
}

@Observable
public final class FinanceStore {
    public private(set) var snapshot: FinancialSnapshot

    private let persistence: any FinancePersisting

    public init(persistence: any FinancePersisting) throws {
        self.persistence = persistence
        let loaded = try persistence.load() ?? FinancialSnapshot()
        guard loaded.schemaVersion <= FinancialSnapshot.currentSchemaVersion else {
            throw FinancePersistenceError.unsupportedSchemaVersion(loaded.schemaVersion)
        }
        snapshot = loaded
    }

    public func asset(id: UUID) -> FinancialAsset? {
        snapshot.assets.first { $0.id == id }
    }

    public func send(_ command: FinanceCommand) throws {
        var candidate = snapshot

        switch command {
        case let .createAsset(id, code, name, currency, price):
            guard !candidate.assets.contains(where: { $0.id == id }) else {
                throw FinanceStoreError.duplicateAssetID
            }
            candidate.assets.append(
                try Self.asset(id: id, code: code, name: name, currency: currency, price: price)
            )

        case let .updateAsset(assetID, code, name, currency, price):
            guard let index = candidate.assets.firstIndex(where: { $0.id == assetID }) else {
                throw FinanceStoreError.assetNotFound
            }
            let previous = candidate.assets[index]
            var updated = try Self.asset(
                id: assetID,
                code: code,
                name: name,
                currency: currency,
                price: price
            )
            updated.transactions = previous.transactions
            candidate.assets[index] = updated

        case let .deleteAsset(assetID):
            guard let index = candidate.assets.firstIndex(where: { $0.id == assetID }) else {
                throw FinanceStoreError.assetNotFound
            }
            candidate.assets.remove(at: index)

        case let .addUnits(assetID, transactionID, occurredAt, units):
            try Self.recordUnits(
                in: &candidate,
                assetID: assetID,
                transactionID: transactionID,
                occurredAt: occurredAt,
                magnitude: units,
                operation: .add
            )

        case let .subtractUnits(assetID, transactionID, occurredAt, units):
            try Self.recordUnits(
                in: &candidate,
                assetID: assetID,
                transactionID: transactionID,
                occurredAt: occurredAt,
                magnitude: units,
                operation: .subtract
            )

        case .updateExchangeRate(let rate):
            guard rate.isFinite, rate > 0 else {
                throw FinanceStoreError.exchangeRateInvalid
            }
            candidate.exchangeRateUSDToVND = rate
        }

        try persistence.save(candidate)
        snapshot = candidate
    }

    private static func asset(
        id: UUID,
        code: String,
        name: String,
        currency: FinancialCurrency,
        price: Double
    ) throws -> FinancialAsset {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCode.isEmpty else { throw FinanceStoreError.assetCodeRequired }
        guard !normalizedName.isEmpty else { throw FinanceStoreError.assetNameRequired }
        guard price.isFinite, price >= 0 else { throw FinanceStoreError.assetPriceInvalid }
        return FinancialAsset(
            id: id,
            code: normalizedCode,
            name: normalizedName,
            currency: currency,
            price: price
        )
    }

    private static func recordUnits(
        in snapshot: inout FinancialSnapshot,
        assetID: UUID,
        transactionID: UUID,
        occurredAt: Date,
        magnitude: Double,
        operation: UnitOperation
    ) throws {
        guard magnitude.isFinite, magnitude > 0 else { throw FinanceStoreError.unitsInvalid }
        guard let index = snapshot.assets.firstIndex(where: { $0.id == assetID }) else {
            throw FinanceStoreError.assetNotFound
        }
        guard !snapshot.assets[index].transactions.contains(where: { $0.id == transactionID }) else {
            throw FinanceStoreError.duplicateTransactionID
        }
        if operation == .subtract, snapshot.assets[index].totalUnits - magnitude < 0 {
            throw FinanceStoreError.insufficientUnits
        }
        let signedUnits = operation == .add ? magnitude : -magnitude
        snapshot.assets[index].transactions.insert(
            UnitTransaction(id: transactionID, occurredAt: occurredAt, units: signedUnits),
            at: 0
        )
    }
}

public final class InMemoryFinancePersistence: FinancePersisting {
    public var snapshot: FinancialSnapshot?
    public var loadError: Error?
    public var saveError: Error?
    public private(set) var savedSnapshots: [FinancialSnapshot] = []

    public init(
        snapshot: FinancialSnapshot? = nil,
        loadError: Error? = nil,
        saveError: Error? = nil
    ) {
        self.snapshot = snapshot
        self.loadError = loadError
        self.saveError = saveError
    }

    public func load() throws -> FinancialSnapshot? {
        if let loadError { throw loadError }
        return snapshot
    }

    public func save(_ snapshot: FinancialSnapshot) throws {
        if let saveError { throw saveError }
        self.snapshot = snapshot
        savedSnapshots.append(snapshot)
    }
}
