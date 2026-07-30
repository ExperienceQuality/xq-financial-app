#if DEBUG
import Darwin
#endif
import Security
import SwiftUI

@main
struct XQFinanceApp: App {
    init() {
        PortfolioStore.resetUITestDataIfRequested()
        #if DEBUG
        PersistenceSmokeTestRunner.runIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(summary: FinanceAppSummary.default)
        }
    }
}

struct FinanceAppSummary {
    let title: String
    let subtitle: String

    static let `default` = FinanceAppSummary(
        title: "XQ Finance",
        subtitle: "Swipe through assets, update prices, and deduct sold lots."
    )
}

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

struct BuyTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let date: String
    let units: Double
    let unitPrice: Double

    var totalCost: Double {
        units * unitPrice
    }

    var shortDate: String {
        date
            .replacingOccurrences(of: ", 2024", with: "")
            .replacingOccurrences(of: ", 2023", with: "")
    }
}

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

struct PortfolioStorageNamespace: Equatable {
    let directoryName: String
    let keychainService: String
}

struct PortfolioSnapshot: Codable, Equatable {
    static let defaultExchangeRateUSDToVND = 25_500.0

    var version: Int
    var exchangeRateUSDToVND: Double
    var assets: [PortfolioAssetSnapshot]

    init(version: Int = 2, exchangeRateUSDToVND: Double = Self.defaultExchangeRateUSDToVND, assets: [PortfolioAssetSnapshot]) {
        self.version = version
        self.exchangeRateUSDToVND = exchangeRateUSDToVND
        self.assets = assets
    }

    init(assets: [FinanceAsset], exchangeRateUSDToVND: Double = Self.defaultExchangeRateUSDToVND) {
        self.init(
            version: 2,
            exchangeRateUSDToVND: exchangeRateUSDToVND,
            assets: assets.map(PortfolioAssetSnapshot.init(asset:))
        )
    }

    enum CodingKeys: String, CodingKey {
        case version
        case exchangeRateUSDToVND
        case assets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        exchangeRateUSDToVND = try container.decodeIfPresent(Double.self, forKey: .exchangeRateUSDToVND) ?? Self.defaultExchangeRateUSDToVND
        assets = try container.decode([PortfolioAssetSnapshot].self, forKey: .assets)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(exchangeRateUSDToVND, forKey: .exchangeRateUSDToVND)
        try container.encode(assets, forKey: .assets)
    }

    var financeAssets: [FinanceAsset] {
        assets.map(\.financeAsset)
    }

    var looksLikeLegacySeededPortfolio: Bool {
        guard assets.count == 3 else { return false }
        return Set(assets.map(\.id)) == Self.legacySeededAssetIDs
            && Set(assets.map(\.symbol)) == Self.legacySeededSymbols
            && Set(assets.map(\.name)) == Self.legacySeededNames
    }

    private static let legacySeededAssetIDs: Set<UUID> = [
        UUID(uuidString: "46C64E8D-039F-4E41-8E0C-7D6D970E3F91")!,
        UUID(uuidString: "87A05B55-3282-49EA-98E4-3A2C05B34B20")!,
        UUID(uuidString: "2B90ACF5-4B3D-4F57-9E70-A3363A1F515C")!
    ]

    private static let legacySeededSymbols: Set<String> = ["AAPL", "BTC", "ETH"]
    private static let legacySeededNames: Set<String> = ["Apple Inc.", "Bitcoin", "Ethereum"]
}

struct PortfolioAssetSnapshot: Codable, Equatable {
    let id: UUID
    let symbol: String
    let name: String
    let nativeCurrency: AssetCurrency
    let currentPrice: Double
    let transactions: [BuyTransaction]

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case nativeCurrency
        case currentPrice
        case transactions
    }

    init(asset: FinanceAsset) {
        id = asset.id
        symbol = asset.symbol
        name = asset.name
        nativeCurrency = asset.nativeCurrency
        currentPrice = asset.currentPrice
        transactions = asset.transactions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        nativeCurrency = try container.decodeIfPresent(AssetCurrency.self, forKey: .nativeCurrency) ?? .usd
        currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        transactions = try container.decode([BuyTransaction].self, forKey: .transactions)
    }

    var financeAsset: FinanceAsset {
        FinanceAsset(
            id: id,
            symbol: symbol,
            name: name,
            nativeCurrency: nativeCurrency,
            accent: FinanceAsset.accent(for: symbol),
            currentPrice: currentPrice,
            transactions: transactions
        )
    }
}

private extension PortfolioStore {
    static func loadPrimarySnapshotData() -> Data? {
        guard let portfolioURL else { return nil }
        return try? Data(contentsOf: portfolioURL)
    }

    private static func writePrimarySnapshotData(_ data: Data) {
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

private enum KeychainPortfolioSnapshot {
    private static let defaultAccount = "latestPortfolioSnapshot"

    static func load(account: String = defaultAccount, service: String = PortfolioStore.namespace().keychainService) -> Data? {
        var query = baseQuery(account: account, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func save(_ data: Data, account: String = defaultAccount, service: String = PortfolioStore.namespace().keychainService) {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let updateStatus = SecItemUpdate(baseQuery(account: account, service: service) as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = baseQuery(account: account, service: service)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func delete(account: String = defaultAccount, service: String = PortfolioStore.namespace().keychainService) {
        SecItemDelete(baseQuery(account: account, service: service) as CFDictionary)
    }

    private static func baseQuery(account: String, service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

#if DEBUG
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

struct ContentView: View {
    let summary: FinanceAppSummary

    @State private var assets: [FinanceAsset]
    @State private var exchangeRateUSDToVND: Double
    @State private var activeIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var selectedTransaction: TransactionSelection?
    @State private var isShowingDeductConfirmation = false
    @State private var activeSheet: AssetSheet?
    @State private var displayCurrency = DisplayCurrency.usd

    init(summary: FinanceAppSummary, portfolio: PortfolioSnapshot? = nil) {
        self.summary = summary
        let snapshot = portfolio ?? PortfolioStore.loadPortfolio()
        _assets = State(initialValue: snapshot.financeAssets)
        _exchangeRateUSDToVND = State(initialValue: snapshot.exchangeRateUSDToVND)
    }

    private var portfolioTotalValue: Double {
        assets.reduce(0) { $0 + $1.currentValueInUSD(exchangeRateUSDToVND: exchangeRateUSDToVND) }
    }

    private var persistenceSignature: String {
        PortfolioStore.signature(for: PortfolioSnapshot(assets: assets, exchangeRateUSDToVND: exchangeRateUSDToVND))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                XQPalette.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    HeaderView(
                        title: summary.title,
                        position: assets.isEmpty ? 0 : activeIndex + 1,
                        count: assets.count,
                        onAddAsset: { activeSheet = .addAsset }
                    )

                    CurrencyToggleView(displayCurrency: $displayCurrency)

                    PortfolioSummaryView(
                        totalValue: portfolioTotalValue,
                        displayCurrency: displayCurrency,
                        exchangeRateUSDToVND: exchangeRateUSDToVND
                    )

                    ExchangeRateEditorView(
                        exchangeRateUSDToVND: $exchangeRateUSDToVND
                    )

                    AssetDeckView(
                        assets: assets,
                        activeIndex: activeIndex,
                        dragOffset: dragOffset,
                        displayCurrency: displayCurrency,
                        exchangeRateUSDToVND: exchangeRateUSDToVND,
                        onAddAsset: { activeSheet = .addAsset },
                        onEditPrice: { activeSheet = .editPrice($0.id) },
                        onAddBuyLot: { activeSheet = .addBuyLot($0.id) },
                        onSelectTransaction: { asset, transaction in
                            selectedTransaction = TransactionSelection(
                                assetID: asset.id,
                                transaction: transaction
                            )
                            isShowingDeductConfirmation = true
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { value in
                                handleDragEnd(value.translation)
                            }
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 54)
                .padding(.bottom, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: persistenceSignature) { _, _ in
            PortfolioStore.save(PortfolioSnapshot(assets: assets, exchangeRateUSDToVND: exchangeRateUSDToVND))
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addAsset:
                AddAssetSheet { symbol, name, nativeCurrency, startingPrice in
                    addAsset(
                        symbol: symbol,
                        name: name,
                        nativeCurrency: nativeCurrency,
                        startingPrice: startingPrice
                    )
                }
                .presentationDetents([.medium])

            case .editPrice(let assetID):
                if let index = assets.firstIndex(where: { $0.id == assetID }) {
                    PriceEditorSheet(asset: $assets[index])
                        .presentationDetents([.medium])
                } else {
                    Text("Asset unavailable")
                        .presentationDetents([.medium])
                }

            case .addBuyLot(let assetID):
                if let index = assets.firstIndex(where: { $0.id == assetID }) {
                    BuyLotEditorSheet(asset: $assets[index])
                        .presentationDetents([.medium])
                } else {
                    Text("Asset unavailable")
                        .presentationDetents([.medium])
                }
            }
        }
        .alert(
            "Deduct this transaction?",
            isPresented: $isShowingDeductConfirmation,
            presenting: selectedTransaction
        ) { selection in
            Button("Confirm Deduction", role: .destructive) {
                deduct(selection)
            }
            .accessibilityIdentifier(XQAccessibilityIdentifier.confirmDeductionButton.rawValue)
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier(XQAccessibilityIdentifier.cancelDeductionButton.rawValue)
        } message: { selection in
            Text("This removes \(selection.transaction.units.formattedUnits) units from the asset's buy lots.")
        }
    }

    private func handleDragEnd(_ translation: CGSize) {
        guard assets.count > 1 else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                dragOffset = .zero
            }
            return
        }

        if translation.width > 90 {
            moveToNextCard(direction: .right)
        } else if translation.width < -90 {
            moveToNextCard(direction: .left)
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                dragOffset = .zero
            }
        }
    }

    private func moveToNextCard(direction: SwipeDirection) {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            dragOffset = CGSize(width: direction == .right ? 520 : -520, height: -20)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard !assets.isEmpty else {
                dragOffset = .zero
                return
            }
            activeIndex = (activeIndex + 1) % assets.count
            dragOffset = .zero
        }
    }

    private func deduct(_ selection: TransactionSelection) {
        guard let index = assets.firstIndex(where: { $0.id == selection.assetID }) else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            assets[index].deduct(transactionID: selection.transaction.id)
        }
    }

    private func addAsset(symbol: String, name: String, nativeCurrency: AssetCurrency, startingPrice: Double) {
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let newAsset = FinanceAsset(
            id: UUID(),
            symbol: trimmedSymbol,
            name: trimmedName,
            nativeCurrency: nativeCurrency,
            accent: FinanceAsset.accent(for: trimmedSymbol),
            currentPrice: max(0, startingPrice),
            transactions: []
        )

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            assets.insert(newAsset, at: 0)
            activeIndex = 0
            dragOffset = .zero
        }
    }
}

private enum SwipeDirection {
    case left
    case right
}

private enum AssetSheet: Identifiable {
    case addAsset
    case editPrice(UUID)
    case addBuyLot(UUID)

    var id: String {
        switch self {
        case .addAsset:
            return "add-asset"
        case .editPrice(let assetID):
            return "edit-price-\(assetID.uuidString)"
        case .addBuyLot(let assetID):
            return "add-buy-lot-\(assetID.uuidString)"
        }
    }
}

private enum DisplayCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case vnd = "VND"

    var id: String {
        rawValue
    }

    func amount(fromUSD amount: Double, exchangeRateUSDToVND: Double) -> Double {
        switch self {
        case .usd:
            return amount
        case .vnd:
            return amount * exchangeRateUSDToVND
        }
    }

    func formatted(fromUSD amount: Double, exchangeRateUSDToVND: Double) -> String {
        switch self {
        case .usd:
            return amount.currency
        case .vnd:
            return self.amount(fromUSD: amount, exchangeRateUSDToVND: exchangeRateUSDToVND).vndCurrency
        }
    }
}

private struct HeaderView: View {
    let title: String
    let position: Int
    let count: Int
    let onAddAsset: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(XQPalette.ink)

                Text(count == 0 ? "No assets yet" : "\(count) assets")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(XQPalette.muted)
            }

            Spacer()

            HStack(spacing: 10) {
                Text(count == 0 ? "0 / 0" : "\(position) / \(count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(XQPalette.muted)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.portfolioPosition.rawValue)

                Button(action: onAddAsset) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(XQPalette.ink, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .accessibilityLabel("Add asset")
                .accessibilityIdentifier(XQAccessibilityIdentifier.addAssetButton.rawValue)
            }
        }
    }
}

private struct CurrencyToggleView: View {
    @Binding var displayCurrency: DisplayCurrency

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width / CGFloat(DisplayCurrency.allCases.count)
            let thumbWidth = max(0, segmentWidth - 4)
            let thumbX = displayCurrency == .usd ? 4 : segmentWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white)
                    .overlay(Capsule().stroke(XQPalette.divider, lineWidth: 1))

                Capsule()
                    .fill(XQPalette.ink)
                    .shadow(
                        color: XQPalette.shadow.opacity(0.16),
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                    .frame(width: thumbWidth, height: 56)
                    .offset(x: thumbX, y: 0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: displayCurrency)
                    .allowsHitTesting(false)

                HStack(spacing: 0) {
                    ForEach(DisplayCurrency.allCases) { currency in
                        Text(currency.rawValue)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(displayCurrency == currency ? .white : XQPalette.muted)
                            .frame(width: segmentWidth, height: 64)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        selectCurrency(atX: value.location.x, controlWidth: proxy.size.width)
                    }
            )
        }
        .frame(height: 64)
        .sensoryFeedback(.selection, trigger: displayCurrency)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Display currency")
        .accessibilityValue(displayCurrency.rawValue)
        .accessibilityIdentifier(XQAccessibilityIdentifier.displayCurrencyToggle.rawValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                setCurrency(.vnd)
            case .decrement:
                setCurrency(.usd)
            default:
                break
            }
        }
    }

    private func selectCurrency(atX xPosition: CGFloat, controlWidth: CGFloat) {
        setCurrency(xPosition < controlWidth / 2 ? .usd : .vnd)
    }

    private func setCurrency(_ currency: DisplayCurrency) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            displayCurrency = currency
        }
    }
}

private struct PortfolioSummaryView: View {
    let totalValue: Double
    let displayCurrency: DisplayCurrency
    let exchangeRateUSDToVND: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Portfolio total")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(XQPalette.muted)

            Text(displayCurrency.formatted(fromUSD: totalValue, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: displayCurrency == .usd ? 31 : 25, weight: .heavy, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            Text("1 USD = \(String(format: "%.0f", exchangeRateUSDToVND)) VND")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(XQPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(XQPalette.divider, lineWidth: 1)
        )
    }
}

private struct ExchangeRateEditorView: View {
    @Binding var exchangeRateUSDToVND: Double
    @State private var isEditing = false
    @State private var text = ""

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("USD to VND")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(XQPalette.muted)

                Text("1 USD = \(String(format: "%.0f", exchangeRateUSDToVND)) VND")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(XQPalette.ink)
            }

            Spacer()

            Button {
                text = String(format: "%.0f", exchangeRateUSDToVND)
                isEditing = true
            } label: {
                HStack(spacing: 8) {
                    Text(String(format: "%.0f", exchangeRateUSDToVND))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(XQPalette.ink)

                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(XQPalette.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(XQPalette.softFill, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(XQPalette.divider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit exchange rate")
            .accessibilityIdentifier(XQAccessibilityIdentifier.exchangeRateEditButton.rawValue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(XQPalette.divider, lineWidth: 1)
        )
        .onAppear {
            text = String(format: "%.0f", exchangeRateUSDToVND)
        }
        .sheet(isPresented: $isEditing) {
            ExchangeRateSheet(
                exchangeRateUSDToVND: $exchangeRateUSDToVND,
                initialText: text
            )
            .presentationDetents([.medium])
        }
    }
}

private struct ExchangeRateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exchangeRateUSDToVND: Double
    @State var initialText: String

    private var parsedValue: Double? {
        initialText.decimalNumber
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exchange Rate") {
                    TextField("USD to VND", text: $initialText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .accessibilityIdentifier(XQAccessibilityIdentifier.exchangeRateField.rawValue)

                    Text("Set how many VND equal 1 USD.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Update Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let parsedValue, parsedValue > 0 {
                            exchangeRateUSDToVND = parsedValue
                        }
                        dismiss()
                    }
                    .disabled(parsedValue == nil || parsedValue ?? 0 <= 0)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.exchangeRateSaveButton.rawValue)
                }
            }
        }
    }
}

private struct AssetDeckView: View {
    let assets: [FinanceAsset]
    let activeIndex: Int
    let dragOffset: CGSize
    let displayCurrency: DisplayCurrency
    let exchangeRateUSDToVND: Double
    let onAddAsset: () -> Void
    let onEditPrice: (FinanceAsset) -> Void
    let onAddBuyLot: (FinanceAsset) -> Void
    let onSelectTransaction: (FinanceAsset, BuyTransaction) -> Void

    var body: some View {
        ZStack {
            if assets.isEmpty {
                EmptyPortfolioView(onAddAsset: onAddAsset)
            } else {
                ForEach(0..<min(3, assets.count), id: \.self) { deckPosition in
                    let assetIndex = (activeIndex + deckPosition) % assets.count
                    let asset = assets[assetIndex]

                    AssetCardView(
                        asset: asset,
                        isActive: deckPosition == 0,
                        displayCurrency: displayCurrency,
                        exchangeRateUSDToVND: exchangeRateUSDToVND,
                        onEditPrice: { onEditPrice(asset) },
                        onAddBuyLot: { onAddBuyLot(asset) },
                        onSelectTransaction: { onSelectTransaction(asset, $0) }
                    )
                    .offset(x: xOffset(for: deckPosition), y: yOffset(for: deckPosition))
                    .rotationEffect(.degrees(rotation(for: deckPosition)))
                    .scaleEffect(scale(for: deckPosition))
                    .zIndex(Double(3 - deckPosition))
                    .allowsHitTesting(deckPosition == 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 520)
    }

    private func xOffset(for deckPosition: Int) -> CGFloat {
        guard deckPosition == 0 else { return CGFloat(deckPosition) * 44 }
        return dragOffset.width
    }

    private func yOffset(for deckPosition: Int) -> CGFloat {
        guard deckPosition == 0 else { return CGFloat(deckPosition) * 20 }
        return dragOffset.height * 0.16
    }

    private func rotation(for deckPosition: Int) -> Double {
        guard deckPosition == 0 else { return Double(deckPosition) * 3.5 }
        return Double(dragOffset.width / 28)
    }

    private func scale(for deckPosition: Int) -> CGFloat {
        deckPosition == 0 ? 1 : 1 - CGFloat(deckPosition) * 0.045
    }
}

private struct EmptyPortfolioView: View {
    let onAddAsset: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(XQPalette.muted)

            VStack(spacing: 4) {
                Text("Add your first asset")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(XQPalette.ink)

                Text("Start with USD or VND, then add buy lots as you go.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(XQPalette.muted)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddAsset) {
                Label("Add Asset", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(XQPalette.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityIdentifier(XQAccessibilityIdentifier.addAssetButton.rawValue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(XQPalette.divider, lineWidth: 1)
        )
        .accessibilityIdentifier(XQAccessibilityIdentifier.emptyPortfolio.rawValue)
    }
}

private struct AssetCardView: View {
    let asset: FinanceAsset
    let isActive: Bool
    let displayCurrency: DisplayCurrency
    let exchangeRateUSDToVND: Double
    let onEditPrice: () -> Void
    let onAddBuyLot: () -> Void
    let onSelectTransaction: (BuyTransaction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                AssetIconView(asset: asset)

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.symbol)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(XQPalette.ink)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.assetSymbol.rawValue)

                    Text(asset.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(XQPalette.muted)
                }

                Spacer()

                Button {
                    onEditPrice()
                } label: {
                    Label("Edit price", systemImage: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white, in: Capsule())
                        .overlay(
                            Capsule().stroke(XQPalette.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(XQPalette.ink)
                .accessibilityLabel("Update current price for \(asset.symbol)")
                .accessibilityIdentifier(XQAccessibilityIdentifier.editPriceButton.rawValue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(displayCurrency.formatted(fromUSD: asset.currentValueInUSD(exchangeRateUSDToVND: exchangeRateUSDToVND), exchangeRateUSDToVND: exchangeRateUSDToVND))
                    .font(.system(size: displayCurrency == .usd ? 38 : 30, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
                    .foregroundStyle(XQPalette.ink)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.assetCurrentValue.rawValue)

                Text("Current total value")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(XQPalette.muted)
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("Buy Lots")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(XQPalette.ink)

                    Text("\(asset.transactions.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(XQPalette.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(XQPalette.softFill, in: Capsule())

                    Spacer()

                    Button {
                        onAddBuyLot()
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .labelStyle(.titleAndIcon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(XQPalette.ink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .accessibilityLabel("Add buy lot for \(asset.symbol)")
                    .accessibilityIdentifier(XQAccessibilityIdentifier.addBuyLotButton.rawValue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)

                Divider().overlay(XQPalette.divider)

                TransactionHeaderRow()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(asset.transactions) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                displayCurrency: displayCurrency,
                                assetCurrency: asset.nativeCurrency,
                                exchangeRateUSDToVND: exchangeRateUSDToVND,
                                onDeduct: { onSelectTransaction(transaction) }
                            )

                            if transaction.id != asset.transactions.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                                    .overlay(XQPalette.divider)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(XQPalette.divider, lineWidth: 1)
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(isActive ? XQPalette.divider : XQPalette.divider.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: XQPalette.shadow.opacity(isActive ? 0.18 : 0.08), radius: isActive ? 22 : 12, x: 0, y: isActive ? 16 : 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(XQAccessibilityIdentifier.assetCard.rawValue)
    }
}

private struct TransactionHeaderRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Units")
                .frame(width: 64, alignment: .leading)

            Text("Price / unit")
                .frame(width: 84, alignment: .leading)

            Spacer(minLength: 4)

            Text("Subtotal")
                .frame(width: 86, alignment: .trailing)

            Color.clear.frame(width: 38, height: 1)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(XQPalette.muted)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(XQPalette.softFill.opacity(0.72))
    }
}

private struct TransactionRow: View {
    let transaction: BuyTransaction
    let displayCurrency: DisplayCurrency
    let assetCurrency: AssetCurrency
    let exchangeRateUSDToVND: Double
    let onDeduct: () -> Void

    var body: some View {
        let unitPriceUSD = assetCurrency.usdAmount(from: transaction.unitPrice, exchangeRateUSDToVND: exchangeRateUSDToVND)
        let subtotalUSD = assetCurrency.usdAmount(from: transaction.totalCost, exchangeRateUSDToVND: exchangeRateUSDToVND)

        HStack(spacing: 10) {
            Text(transaction.units.formattedUnits)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 64, alignment: .leading)

            Text(displayCurrency.formatted(fromUSD: unitPriceUSD, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(XQPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(width: 84, alignment: .leading)

            Spacer(minLength: 4)

            Text(displayCurrency.formatted(fromUSD: subtotalUSD, exchangeRateUSDToVND: exchangeRateUSDToVND))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(XQPalette.ink)
                .frame(width: 86, alignment: .trailing)
                .minimumScaleFactor(0.64)
                .lineLimit(1)

            Button(role: .destructive) {
                onDeduct()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(XQPalette.destructive.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(XQPalette.destructive)
            .accessibilityLabel("Deduct transaction from \(transaction.date)")
            .accessibilityIdentifier(XQAccessibilityIdentifier.deductTransactionButton.rawValue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(XQAccessibilityIdentifier.transactionRow.rawValue)
    }
}

private struct PriceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var asset: FinanceAsset
    @State private var priceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Price") {
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .accessibilityIdentifier(XQAccessibilityIdentifier.currentPriceField.rawValue)

                    Text("Current price is entered in \(asset.nativeCurrency.label). Updating price changes total value only; it does not change units owned.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Update \(asset.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let price = priceText.decimalNumber {
                            asset.updateCurrentPrice(price)
                        }
                        dismiss()
                    }
                    .disabled(priceText.decimalNumber == nil)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.priceSaveButton.rawValue)
                }
            }
            .onAppear {
                priceText = String(format: "%.2f", asset.currentPrice)
            }
        }
    }
}

private struct BuyLotEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var asset: FinanceAsset
    @State private var unitsText = ""
    @State private var unitPriceText = ""

    private var units: Double? {
        unitsText.decimalNumber
    }

    private var unitPrice: Double? {
        unitPriceText.decimalNumber
    }

    private var subtotal: Double? {
        guard let units, let unitPrice else { return nil }
        return units * unitPrice
    }

    private var canSave: Bool {
        guard let units, let unitPrice else { return false }
        return units > 0 && unitPrice > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Buy Lot") {
                    TextField("Units", text: $unitsText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotUnitsField.rawValue)

                    TextField("Price per unit (\(asset.nativeCurrency.label))", text: $unitPriceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotPriceField.rawValue)

                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(asset.nativeCurrency.formatted(subtotal ?? 0))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }

                Section {
                    Text("Buy lots are entered in \(asset.nativeCurrency.label). Adding a lot increases units owned and current total value for this asset.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add \(asset.symbol) Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let units, let unitPrice else { return }
                        asset.addBuyLot(
                            units: units,
                            unitPrice: unitPrice,
                            date: Date.now.buyLotDate
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.buyLotSaveButton.rawValue)
                }
            }
        }
    }
}

private struct AddAssetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var name = ""
    @State private var nativeCurrency = AssetCurrency.usd
    @State private var startingPriceText = "0"

    let onAdd: (String, String, AssetCurrency, Double) -> Void

    private var canSave: Bool {
        !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Symbol", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.symbolField.rawValue)

                    TextField("Name", text: $name)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.nameField.rawValue)

                    Picker("Native currency", selection: $nativeCurrency) {
                        ForEach(AssetCurrency.allCases) { currency in
                            Text(currency.label).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.assetNativeCurrencyPicker.rawValue)
                }

                Section("Starting Price") {
                    TextField("Price", text: $startingPriceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(XQAccessibilityIdentifier.startingPriceField.rawValue)

                    Text("The price is stored in \(nativeCurrency.label). You can update it later.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(
                            symbol.trimmingCharacters(in: .whitespacesAndNewlines),
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            nativeCurrency,
                            startingPriceText.decimalNumber ?? 0
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.addAssetSaveButton.rawValue)
                }
            }
        }
    }
}

private struct AssetIconView: View {
    let asset: FinanceAsset

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(asset.accent.gradient)

            Text(String(asset.symbol.prefix(1)))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 60, height: 60)
        .shadow(color: asset.accent.opacity(0.24), radius: 10, y: 8)
    }
}

struct TransactionSelection: Identifiable {
    let assetID: UUID
    let transaction: BuyTransaction

    var id: UUID {
        transaction.id
    }
}

private enum XQPalette {
    static let background = Color(red: 0.965, green: 0.974, blue: 0.988)
    static let ink = Color(red: 0.045, green: 0.102, blue: 0.207)
    static let muted = Color(red: 0.394, green: 0.456, blue: 0.578)
    static let divider = Color(red: 0.858, green: 0.887, blue: 0.926)
    static let softFill = Color(red: 0.928, green: 0.944, blue: 0.968)
    static let shadow = Color(red: 0.035, green: 0.068, blue: 0.13)
    static let positive = Color(red: 0.08, green: 0.68, blue: 0.31)
    static let destructive = Color(red: 0.95, green: 0.22, blue: 0.18)
}

private extension Double {
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

private extension Date {
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

#Preview {
    let portfolio = PortfolioSnapshot(
        assets: [
            FinanceAsset(
                id: UUID(uuidString: "46C64E8D-039F-4E41-8E0C-7D6D970E3F91")!,
                symbol: "AAPL",
                name: "Apple Inc.",
                nativeCurrency: .usd,
                accent: FinanceAsset.accent(for: "AAPL"),
                currentPrice: 174.65,
                transactions: [
                    BuyTransaction(id: UUID(uuidString: "52AD1788-4E1C-4797-9BD9-F5B77C9388E2")!, date: "May 6, 2024", units: 10.000, unitPrice: 169.21),
                    BuyTransaction(id: UUID(uuidString: "4A8E62BF-6FDE-482A-9F56-768440E28A5D")!, date: "Apr 15, 2024", units: 15.000, unitPrice: 165.32)
                ]
            ),
            FinanceAsset(
                id: UUID(uuidString: "87A05B55-3282-49EA-98E4-3A2C05B34B20")!,
                symbol: "VNGOLD",
                name: "VND Gold",
                nativeCurrency: .vnd,
                accent: XQPalette.positive,
                currentPrice: 7_850_000,
                transactions: [
                    BuyTransaction(id: UUID(uuidString: "3AE792AC-4B1E-4712-A302-33E6D9F1D1BD")!, date: "May 5, 2024", units: 0.080, unitPrice: 7_420_000)
                ]
            )
        ],
        exchangeRateUSDToVND: 25_500
    )

    ContentView(summary: .default, portfolio: portfolio)
}
