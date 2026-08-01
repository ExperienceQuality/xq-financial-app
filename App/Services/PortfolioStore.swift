import Foundation

enum PortfolioStore {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    static let normalNamespace = PortfolioStorageNamespace(
        directoryName: "XQFinance",
        keychainService: "com.xq.finance.ios-xq-finance-app.portfolio"
    )
    static let uiTestNamespace = PortfolioStorageNamespace(
        directoryName: "XQFinanceUITests",
        keychainService: "com.xq.finance.ios-xq-finance-app.portfolio.uitests"
    )

    static func namespace(arguments: [String] = CommandLine.arguments) -> PortfolioStorageNamespace {
        arguments.contains("--xq-ui-testing") ? uiTestNamespace : normalNamespace
    }

    private static var portfolioURL: URL? {
        portfolioURL(namespace: namespace())
    }

    static func portfolioURL(namespace: PortfolioStorageNamespace, baseURL: URL? = nil) -> URL? {
        let resolvedBaseURL: URL
        if let baseURL {
            resolvedBaseURL = baseURL
        } else if let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            resolvedBaseURL = applicationSupportURL
        } else {
            return nil
        }
        return resolvedBaseURL
            .appendingPathComponent(namespace.directoryName, isDirectory: true)
            .appendingPathComponent("portfolio.json")
    }

    static func resetUITestDataIfRequested(arguments: [String] = CommandLine.arguments) {
        guard shouldResetUITestData(arguments: arguments) else { return }
        if let url = portfolioURL(namespace: uiTestNamespace) {
            try? FileManager.default.removeItem(at: url)
        }
        KeychainPortfolioSnapshot.delete(service: uiTestNamespace.keychainService)
    }

    static func shouldResetUITestData(arguments: [String]) -> Bool {
        arguments.contains("--xq-ui-testing") && arguments.contains("--xq-ui-testing-reset")
    }

    static func loadPortfolio() -> PortfolioSnapshot {
        if let data = loadPrimarySnapshotData(), let snapshot = decode(data) {
            return migrate(snapshot)
        }

        if let data = KeychainPortfolioSnapshot.load(service: namespace().keychainService), let snapshot = decode(data) {
            let migrated = migrate(snapshot)
            if let migratedData = encode(migrated) {
                writePrimarySnapshotData(migratedData)
                KeychainPortfolioSnapshot.save(migratedData, service: namespace().keychainService)
            } else {
                writePrimarySnapshotData(data)
            }
            return migrated
        }

        return PortfolioSnapshot(assets: [], exchangeRateUSDToVND: PortfolioSnapshot.defaultExchangeRateUSDToVND)
    }

    static func loadAssets() -> [FinanceAsset] {
        loadPortfolio().financeAssets
    }

    static func save(_ snapshot: PortfolioSnapshot) {
        guard let data = encode(snapshot) else { return }
        writePrimarySnapshotData(data)
        KeychainPortfolioSnapshot.save(data, service: namespace().keychainService)
    }

    static func save(assets: [FinanceAsset], exchangeRateUSDToVND: Double) {
        save(PortfolioSnapshot(assets: assets, exchangeRateUSDToVND: exchangeRateUSDToVND))
    }

    static func signature(for snapshot: PortfolioSnapshot) -> String {
        guard let data = encode(snapshot) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    static func signature(for assets: [FinanceAsset], exchangeRateUSDToVND: Double = PortfolioSnapshot.defaultExchangeRateUSDToVND) -> String {
        signature(for: PortfolioSnapshot(assets: assets, exchangeRateUSDToVND: exchangeRateUSDToVND))
    }

    static func encode(_ snapshot: PortfolioSnapshot) -> Data? {
        try? encoder.encode(snapshot)
    }

    static func decode(_ data: Data) -> PortfolioSnapshot? {
        try? decoder.decode(PortfolioSnapshot.self, from: data)
    }

    private static func migrate(_ snapshot: PortfolioSnapshot) -> PortfolioSnapshot {
        guard snapshot.version < 2, snapshot.looksLikeLegacySeededPortfolio else {
            return snapshot
        }

        return PortfolioSnapshot(
            version: 2,
            exchangeRateUSDToVND: snapshot.exchangeRateUSDToVND,
            assets: []
        )
    }
}

extension PortfolioStore {
    static func loadPrimarySnapshotData() -> Data? {
        guard let portfolioURL else { return nil }
        return try? Data(contentsOf: portfolioURL)
    }

    static func writePrimarySnapshotData(_ data: Data) {
        guard let portfolioURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: portfolioURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: portfolioURL, options: [.atomic])
        } catch {
            // Keychain fallback still gives the app a recovery path if file write fails.
        }
    }
}
