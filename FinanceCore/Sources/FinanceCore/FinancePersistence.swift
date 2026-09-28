import Foundation
#if canImport(Security)
import Security
#endif

public enum FinancePersistenceError: Error, Equatable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case unreadableSnapshot
    case invalidLegacyData(String)
    case keychainFailure(Int32)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            "This financial data uses unsupported schema version \(version)."
        case .unreadableSnapshot:
            "The financial data and its recovery copies could not be read."
        case .invalidLegacyData(let reason):
            "The legacy portfolio could not be migrated: \(reason)"
        case .keychainFailure(let status):
            "Secure portfolio storage failed with status \(status)."
        }
    }
}

public struct FinanceStorageNamespace: Equatable, Sendable {
    public let directoryName: String
    public let keychainService: String

    public init(directoryName: String, keychainService: String) {
        self.directoryName = directoryName
        self.keychainService = keychainService
    }
}

public enum FinanceStorage {
    public static let normalNamespace = FinanceStorageNamespace(
        directoryName: "XQFinance",
        keychainService: "com.xq.finance.ios-xq-finance-app.portfolio"
    )
    public static let uiTestNamespace = FinanceStorageNamespace(
        directoryName: "XQFinanceUITests",
        // UI-test bundles do not carry production keychain entitlements. Keep
        // this namespace deterministic and file-backed instead.
        keychainService: ""
    )

    public static func namespace(arguments: [String]) -> FinanceStorageNamespace {
        arguments.contains("--xq-ui-testing") ? uiTestNamespace : normalNamespace
    }

    public static func directory(
        baseURL: URL,
        namespace: FinanceStorageNamespace
    ) -> URL {
        baseURL.appendingPathComponent(namespace.directoryName, isDirectory: true)
    }

    public static func shouldReset(arguments: [String]) -> Bool {
        arguments.contains("--xq-ui-testing") &&
            arguments.contains("--xq-ui-testing-reset")
    }

    public static func resetUITestDataIfRequested(
        directory: URL,
        namespace: FinanceStorageNamespace,
        arguments: [String],
        fileManager: FileManager = .default
    ) throws {
        guard shouldReset(arguments: arguments), namespace == uiTestNamespace else { return }
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try KeychainSnapshotStore(service: namespace.keychainService).deleteAllSnapshots()
    }
}

public struct KeychainSnapshotStore {
    public static let currentAccount = "latestFinancialSnapshotV3"
    public static let legacyAccount = "latestPortfolioSnapshot"

    public let service: String

    public init(service: String) {
        self.service = service
    }

    public func load(account: String) throws -> Data? {
        guard !service.isEmpty else { return nil }
        #if canImport(Security)
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw FinancePersistenceError.keychainFailure(status)
        }
        return result as? Data
        #else
        return nil
        #endif
    }

    public func save(_ data: Data, account: String) throws {
        guard !service.isEmpty else { return }
        #if canImport(Security)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let updateStatus = SecItemUpdate(
            baseQuery(account: account) as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw FinancePersistenceError.keychainFailure(updateStatus)
        }
        var query = baseQuery(account: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw FinancePersistenceError.keychainFailure(addStatus)
        }
        #endif
    }

    public func deleteAllSnapshots() throws {
        try delete(account: Self.currentAccount)
        try delete(account: Self.legacyAccount)
    }

    public func delete(account: String) throws {
        guard !service.isEmpty else { return }
        #if canImport(Security)
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw FinancePersistenceError.keychainFailure(status)
        }
        #endif
    }

    #if canImport(Security)
    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
    #endif
}

public final class ProductionFinancePersistence: FinancePersisting {
    public let directory: URL
    public let primaryURL: URL
    public let recoveryURL: URL
    public let legacyURL: URL

    private let keychain: KeychainSnapshotStore
    private let fileManager: FileManager

    public init(
        directory: URL,
        keychainService: String,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        primaryURL = directory.appendingPathComponent("financial-v3.json")
        recoveryURL = directory.appendingPathComponent("financial-v3-recovery.json")
        legacyURL = directory.appendingPathComponent("portfolio.json")
        keychain = KeychainSnapshotStore(service: keychainService)
        self.fileManager = fileManager
    }

    public func load() throws -> FinancialSnapshot? {
        let primaryExists = fileManager.fileExists(atPath: primaryURL.path)
        let recoveryExists = fileManager.fileExists(atPath: recoveryURL.path)

        if primaryExists {
            do {
                return try decodeCurrent(Data(contentsOf: primaryURL))
            } catch let error as FinancePersistenceError {
                if case .unsupportedSchemaVersion = error { throw error }
            } catch {
                // Corrupt primary data may fall back to another current copy.
            }
        }
        if recoveryExists {
            do {
                let snapshot = try decodeCurrent(Data(contentsOf: recoveryURL))
                try? writePrimaryOnly(snapshot)
                return snapshot
            } catch let error as FinancePersistenceError {
                if case .unsupportedSchemaVersion = error { throw error }
            } catch {
                // Corrupt recovery data may fall back to the current Keychain copy.
            }
        }
        if let secureData = try keychain.load(account: KeychainSnapshotStore.currentAccount) {
            let snapshot = try decodeCurrent(secureData)
            try? writeFiles(snapshot)
            return snapshot
        }
        if primaryExists || recoveryExists {
            throw FinancePersistenceError.unreadableSnapshot
        }

        if fileManager.fileExists(atPath: legacyURL.path) {
            let migrated = try LegacyPortfolioMigrator.migrate(Data(contentsOf: legacyURL))
            try save(migrated)
            return migrated
        }
        if let legacyData = try keychain.load(account: KeychainSnapshotStore.legacyAccount) {
            let migrated = try LegacyPortfolioMigrator.migrate(legacyData)
            try save(migrated)
            return migrated
        }
        return nil
    }

    public func save(_ snapshot: FinancialSnapshot) throws {
        guard snapshot.schemaVersion <= FinancialSnapshot.currentSchemaVersion else {
            throw FinancePersistenceError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }
        let data = try Self.encoder.encode(snapshot)
        let previousPrimary = try? Data(contentsOf: primaryURL)
        let previousRecovery = try? Data(contentsOf: recoveryURL)
        let previousSecure = try keychain.load(account: KeychainSnapshotStore.currentAccount)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: primaryURL, options: .atomic)
            try data.write(to: recoveryURL, options: .atomic)
            try keychain.save(data, account: KeychainSnapshotStore.currentAccount)
        } catch {
            restore(previousPrimary, at: primaryURL)
            restore(previousRecovery, at: recoveryURL)
            if let previousSecure {
                try? keychain.save(previousSecure, account: KeychainSnapshotStore.currentAccount)
            } else {
                try? keychain.delete(account: KeychainSnapshotStore.currentAccount)
            }
            throw error
        }
    }

    private func decodeCurrent(_ data: Data) throws -> FinancialSnapshot {
        let snapshot = try Self.decoder.decode(FinancialSnapshot.self, from: data)
        guard snapshot.schemaVersion <= FinancialSnapshot.currentSchemaVersion else {
            throw FinancePersistenceError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }
        return snapshot
    }

    private func writeFiles(_ snapshot: FinancialSnapshot) throws {
        let data = try Self.encoder.encode(snapshot)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: primaryURL, options: .atomic)
        try data.write(to: recoveryURL, options: .atomic)
    }

    private func writePrimaryOnly(_ snapshot: FinancialSnapshot) throws {
        let data = try Self.encoder.encode(snapshot)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: primaryURL, options: .atomic)
    }

    private func restore(_ data: Data?, at url: URL) {
        if let data {
            try? data.write(to: url, options: .atomic)
        } else if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

public enum LegacyPortfolioMigrator {
    public static func migrate(_ data: Data) throws -> FinancialSnapshot {
        let legacy: LegacyPortfolioSnapshot
        do {
            legacy = try JSONDecoder().decode(LegacyPortfolioSnapshot.self, from: data)
        } catch {
            throw FinancePersistenceError.invalidLegacyData("The JSON structure is invalid.")
        }

        if legacy.version < 2, legacy.looksLikeSeededDemo {
            return FinancialSnapshot(exchangeRateUSDToVND: legacy.exchangeRateUSDToVND)
        }
        guard legacy.exchangeRateUSDToVND.isFinite, legacy.exchangeRateUSDToVND > 0 else {
            throw FinancePersistenceError.invalidLegacyData("The exchange rate is invalid.")
        }

        var assetIDs = Set<UUID>()
        var transactionIDs = Set<UUID>()
        let assets = try legacy.assets.map { asset -> FinancialAsset in
            guard assetIDs.insert(asset.id).inserted else {
                throw FinancePersistenceError.invalidLegacyData("An asset ID is duplicated.")
            }
            guard asset.currentPrice.isFinite, asset.currentPrice >= 0 else {
                throw FinancePersistenceError.invalidLegacyData("An asset price is invalid.")
            }
            let transactions = try asset.transactions.map { transaction -> UnitTransaction in
                guard transactionIDs.insert(transaction.id).inserted else {
                    throw FinancePersistenceError.invalidLegacyData("A transaction ID is duplicated.")
                }
                guard transaction.units.isFinite, transaction.units > 0 else {
                    throw FinancePersistenceError.invalidLegacyData("Transaction units are invalid.")
                }
                guard let occurredAt = legacyDateFormatter.date(from: transaction.date) else {
                    throw FinancePersistenceError.invalidLegacyData("A transaction date is invalid.")
                }
                return UnitTransaction(id: transaction.id, occurredAt: occurredAt, units: transaction.units)
            }
            return FinancialAsset(
                id: asset.id,
                code: asset.symbol,
                name: asset.name,
                currency: asset.nativeCurrency,
                price: asset.currentPrice,
                transactions: transactions
            )
        }
        return FinancialSnapshot(
            exchangeRateUSDToVND: legacy.exchangeRateUSDToVND,
            assets: assets
        )
    }

    private static let legacyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

private struct LegacyPortfolioSnapshot: Decodable {
    let version: Int
    let exchangeRateUSDToVND: Double
    let assets: [LegacyAsset]

    private enum CodingKeys: String, CodingKey {
        case version, exchangeRateUSDToVND, assets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        exchangeRateUSDToVND = try container.decodeIfPresent(
            Double.self,
            forKey: .exchangeRateUSDToVND
        ) ?? FinancialSnapshot.defaultExchangeRateUSDToVND
        assets = try container.decode([LegacyAsset].self, forKey: .assets)
    }

    var looksLikeSeededDemo: Bool {
        guard assets.count == 3 else { return false }
        return Set(assets.map(\.id)) == [
            UUID(uuidString: "46C64E8D-039F-4E41-8E0C-7D6D970E3F91")!,
            UUID(uuidString: "87A05B55-3282-49EA-98E4-3A2C05B34B20")!,
            UUID(uuidString: "2B90ACF5-4B3D-4F57-9E70-A3363A1F515C")!
        ] && Set(assets.map(\.symbol)) == ["AAPL", "BTC", "ETH"]
    }
}

private struct LegacyAsset: Decodable {
    let id: UUID
    let symbol: String
    let name: String
    let nativeCurrency: FinancialCurrency
    let currentPrice: Double
    let transactions: [LegacyTransaction]

    private enum CodingKeys: String, CodingKey {
        case id, symbol, name, nativeCurrency, currentPrice, transactions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        nativeCurrency = try container.decodeIfPresent(
            FinancialCurrency.self,
            forKey: .nativeCurrency
        ) ?? .usd
        currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        transactions = try container.decode([LegacyTransaction].self, forKey: .transactions)
    }
}

private struct LegacyTransaction: Decodable {
    let id: UUID
    let date: String
    let units: Double
    // Legacy unitPrice deliberately omitted. Decoder ignores it.
}
