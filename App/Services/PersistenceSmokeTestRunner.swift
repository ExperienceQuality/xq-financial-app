#if DEBUG
import Darwin
import FinanceCore
import Foundation

/// Local device-only persistence smoke for `scripts/verify-device-reinstall-persistence.sh`.
/// Seeds/verifies a marker through `ProductionFinancePersistence` (CHAR-08 / D2).
enum PersistenceSmokeTestRunner {
    private static let flag = "--xq-persistence-smoke"
    private static let seedCommand = "seed"
    private static let verifyCommand = "verify"
    private static let restoreCommand = "restore"
    private static let backupAccount = "reinstallPersistenceSmokeBackup"
    private static let smokeAssetID = UUID(uuidString: "5AE61D43-67EE-4C1F-8ED4-B5D5A3799825")!
    private static let smokeTransactionID = UUID(uuidString: "F3117862-9382-44A2-8407-1EAD34F70A5D")!
    private static let smokeCode = "XQSMOKE"
    private static let smokePrice = 1234.56
    private static let smokeUnits = 7.5
    private static let smokeOccurredAt = Date(timeIntervalSince1970: 1_781_596_800) // 2026-06-16 UTC

    static func runIfRequested(arguments: [String] = CommandLine.arguments) {
        guard
            let flagIndex = arguments.firstIndex(of: flag),
            arguments.indices.contains(flagIndex + 1)
        else {
            return
        }

        let status: Int32
        switch arguments[flagIndex + 1] {
        case seedCommand:
            status = seed()
        case verifyCommand:
            status = verifyAndRestore()
        case restoreCommand:
            status = restoreOriginalSnapshot()
        default:
            status = 64
        }

        exit(status)
    }

    private static func seed() -> Int32 {
        do {
            let context = try makeContext()
            let original = try context.persistence.load() ?? FinancialSnapshot()
            let backupData = try encode(original)
            try context.keychain.save(backupData, account: backupAccount)

            var snapshot = original
            snapshot.assets.removeAll { $0.code == smokeCode }
            snapshot.assets.insert(smokeAsset, at: 0)
            try context.persistence.save(snapshot)
            return 0
        } catch {
            return 65
        }
    }

    private static func verifyAndRestore() -> Int32 {
        do {
            let context = try makeContext()
            let snapshot = try context.persistence.load() ?? FinancialSnapshot()
            guard let asset = snapshot.assets.first(where: { $0.id == smokeAssetID && $0.code == smokeCode }) else {
                return 66
            }
            guard asset.price == smokePrice else { return 67 }
            guard let transaction = asset.transactions.first(where: { $0.id == smokeTransactionID }) else {
                return 68
            }
            guard transaction.units == smokeUnits else { return 69 }
            return restoreOriginalSnapshot()
        } catch {
            return 66
        }
    }

    private static func restoreOriginalSnapshot() -> Int32 {
        do {
            let context = try makeContext()
            guard let backupData = try context.keychain.load(account: backupAccount) else {
                return 70
            }
            let snapshot = try decode(backupData)
            try context.persistence.save(snapshot)
            try context.keychain.delete(account: backupAccount)
            return 0
        } catch {
            return 71
        }
    }

    private static func makeContext() throws -> (
        persistence: ProductionFinancePersistence,
        keychain: KeychainSnapshotStore
    ) {
        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw FinancePersistenceError.unreadableSnapshot
        }
        let namespace = FinanceStorage.normalNamespace
        let directory = FinanceStorage.directory(baseURL: applicationSupport, namespace: namespace)
        let persistence = ProductionFinancePersistence(
            directory: directory,
            keychainService: namespace.keychainService
        )
        let keychain = KeychainSnapshotStore(service: namespace.keychainService)
        return (persistence, keychain)
    }

    private static func encode(_ snapshot: FinancialSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    private static func decode(_ data: Data) throws -> FinancialSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FinancialSnapshot.self, from: data)
    }

    private static var smokeAsset: FinancialAsset {
        FinancialAsset(
            id: smokeAssetID,
            code: smokeCode,
            name: "XQ Persistence Smoke",
            currency: .usd,
            price: smokePrice,
            transactions: [
                UnitTransaction(
                    id: smokeTransactionID,
                    occurredAt: smokeOccurredAt,
                    units: smokeUnits
                )
            ]
        )
    }
}

#endif
