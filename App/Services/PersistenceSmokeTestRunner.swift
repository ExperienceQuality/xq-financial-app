#if DEBUG
import Darwin
import Foundation

enum PersistenceSmokeTestRunner {
    private static let flag = "--xq-persistence-smoke"
    private static let seedCommand = "seed"
    private static let verifyCommand = "verify"
    private static let restoreCommand = "restore"
    private static let backupAccount = "reinstallPersistenceSmokeBackup"
    private static let smokeAssetID = UUID(uuidString: "5AE61D43-67EE-4C1F-8ED4-B5D5A3799825")!
    private static let smokeTransactionID = UUID(uuidString: "F3117862-9382-44A2-8407-1EAD34F70A5D")!
    private static let smokeSymbol = "XQSMOKE"
    private static let smokePrice = 1234.56
    private static let smokeUnits = 7.5
    private static let smokeUnitPrice = 11.22

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
            status = restoreOriginalPortfolio()
        default:
            status = 64
        }

        exit(status)
    }

    private static func seed() -> Int32 {
        let originalSnapshot = PortfolioStore.loadPortfolio()
        guard let backupData = PortfolioStore.encode(originalSnapshot) else { return 65 }
        KeychainPortfolioSnapshot.save(backupData, account: backupAccount)

        var snapshot = originalSnapshot
        snapshot.assets.removeAll { $0.symbol == smokeSymbol }
        snapshot.assets.insert(PortfolioAssetSnapshot(asset: smokeAsset), at: 0)
        PortfolioStore.save(snapshot)
        return 0
    }

    private static func verifyAndRestore() -> Int32 {
        let snapshot = PortfolioStore.loadPortfolio()
        guard let asset = snapshot.financeAssets.first(where: { $0.id == smokeAssetID && $0.symbol == smokeSymbol }) else {
            return 66
        }
        guard asset.currentPrice == smokePrice else { return 67 }
        guard let transaction = asset.transactions.first(where: { $0.id == smokeTransactionID }) else {
            return 68
        }
        guard transaction.units == smokeUnits && transaction.unitPrice == smokeUnitPrice else {
            return 69
        }

        return restoreOriginalPortfolio()
    }

    private static func restoreOriginalPortfolio() -> Int32 {
        guard let backupData = KeychainPortfolioSnapshot.load(account: backupAccount) else {
            return 70
        }
        guard let snapshot = PortfolioStore.decode(backupData) else {
            return 71
        }

        PortfolioStore.save(snapshot)
        KeychainPortfolioSnapshot.delete(account: backupAccount)
        return 0
    }

    private static var smokeAsset: FinanceAsset {
        FinanceAsset(
            id: smokeAssetID,
            symbol: smokeSymbol,
            name: "XQ Persistence Smoke",
            nativeCurrency: .usd,
            accent: FinanceAsset.accent(for: smokeSymbol),
            currentPrice: smokePrice,
            transactions: [
                BuyTransaction(
                    id: smokeTransactionID,
                    date: "Jun 16, 2026",
                    units: smokeUnits,
                    unitPrice: smokeUnitPrice
                )
            ]
        )
    }
}

#endif
