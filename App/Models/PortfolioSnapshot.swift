import Foundation

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
