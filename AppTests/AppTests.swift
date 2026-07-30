import XCTest
@testable import ios_xq_finance_app

final class AppTests: XCTestCase {
    func testDefaultSummaryNamesFinanceApp() throws {
        let summary = FinanceAppSummary.default

        XCTAssertEqual(summary.title, "XQ Finance")
        XCTAssertEqual(summary.subtitle, "Swipe through assets, update prices, and deduct sold lots.")
    }

    func testPortfolioSnapshotStartsEmptyWhenNoAssetsAreLoaded() throws {
        let snapshot = PortfolioSnapshot(assets: [], exchangeRateUSDToVND: PortfolioSnapshot.defaultExchangeRateUSDToVND)

        XCTAssertTrue(snapshot.financeAssets.isEmpty)
        XCTAssertEqual(snapshot.exchangeRateUSDToVND, PortfolioSnapshot.defaultExchangeRateUSDToVND, accuracy: 0.001)
    }

    func testCurrentValueConvertsFromNativeCurrencyUsingExchangeRate() throws {
        let asset = makeVNDAsset()

        XCTAssertEqual(asset.currentValueInUSD(exchangeRateUSDToVND: 25_500), 10_000_000 / 25_500, accuracy: 0.001)
    }

    func testUpdatingCurrentPriceChangesValuationOnly() throws {
        var asset = makeUSDAsset()
        let units = asset.unitsOwned
        let totalCost = asset.totalCost

        asset.updateCurrentPrice(200)

        XCTAssertEqual(asset.unitsOwned, units, accuracy: 0.001)
        XCTAssertEqual(asset.totalCost, totalCost, accuracy: 0.001)
        XCTAssertEqual(asset.currentValue, units * 200, accuracy: 0.001)
    }

    func testAddingBuyLotUpdatesUnitsCostAndValuation() throws {
        var asset = makeUSDAsset()
        let initialUnits = asset.unitsOwned
        let initialCost = asset.totalCost
        let initialTransactionCount = asset.transactions.count

        asset.addBuyLot(units: 2.5, unitPrice: 170, date: "Jun 16, 2026")

        XCTAssertEqual(asset.transactions.count, initialTransactionCount + 1)
        XCTAssertEqual(asset.transactions.first?.units, 2.5)
        XCTAssertEqual(asset.transactions.first?.unitPrice, 170)
        XCTAssertEqual(asset.transactions.first?.date, "Jun 16, 2026")
        XCTAssertEqual(asset.unitsOwned, initialUnits + 2.5, accuracy: 0.001)
        XCTAssertEqual(asset.totalCost, initialCost + 425, accuracy: 0.001)
        XCTAssertEqual(asset.currentPrice, 170, accuracy: 0.001)
        XCTAssertEqual(asset.currentValue, (initialUnits + 2.5) * 170, accuracy: 0.001)
    }

    func testDeductingTransactionRemovesBuyLot() throws {
        var asset = makeUSDAsset()
        let transaction = try XCTUnwrap(asset.transactions.last)

        asset.deduct(transactionID: transaction.id)

        XCTAssertFalse(asset.transactions.contains(transaction))
        XCTAssertEqual(asset.unitsOwned, 60, accuracy: 0.001)
    }

    func testDecimalCommaInputIsAccepted() throws {
        XCTAssertEqual("0,5".decimalNumber, 0.5)
        XCTAssertEqual(" 170,25 ".decimalNumber, 170.25)
        XCTAssertEqual("0.75".decimalNumber, 0.75)
    }

    func testPortfolioSnapshotRoundTripsAssetsAndExchangeRate() throws {
        var asset = makeVNDAsset()
        asset.updateCurrentPrice(9_800_000)
        asset.addBuyLot(units: 0.25, unitPrice: 9_500_000, date: "Jun 16, 2026")

        let snapshot = PortfolioSnapshot(assets: [asset], exchangeRateUSDToVND: 25_500)
        let data = try XCTUnwrap(PortfolioStore.encode(snapshot))
        let decoded = try XCTUnwrap(PortfolioStore.decode(data))
        let restoredAsset = try XCTUnwrap(decoded.financeAssets.first)

        XCTAssertEqual(decoded.version, 2)
        XCTAssertEqual(decoded.exchangeRateUSDToVND, 25_500, accuracy: 0.001)
        XCTAssertEqual(restoredAsset.id, asset.id)
        XCTAssertEqual(restoredAsset.symbol, "XAU")
        XCTAssertEqual(restoredAsset.name, "VND Gold")
        XCTAssertEqual(restoredAsset.nativeCurrency, .vnd)
        XCTAssertEqual(restoredAsset.currentPrice, asset.currentPrice, accuracy: 0.001)
        XCTAssertEqual(restoredAsset.transactions.count, asset.transactions.count)
        XCTAssertEqual(restoredAsset.transactions.first?.units, 0.25)
        XCTAssertEqual(restoredAsset.transactions.first?.unitPrice, 9_500_000)
    }

    func testPortfolioStoreSignatureChangesWhenExchangeRateChanges() throws {
        let assets = [makeUSDAsset()]
        let originalSignature = PortfolioStore.signature(for: assets, exchangeRateUSDToVND: 25_500)

        let updatedSignature = PortfolioStore.signature(for: assets, exchangeRateUSDToVND: 26_000)

        XCTAssertNotEqual(updatedSignature, originalSignature)
    }

    func testPortfolioSnapshotDecodesLegacyVersionWithoutExchangeRate() throws {
        let legacyJSON = """
        {
          "version": 1,
          "assets": [
            {
              "id": "46C64E8D-039F-4E41-8E0C-7D6D970E3F91",
              "symbol": "AAPL",
              "name": "Apple Inc.",
              "currentPrice": 174.65,
              "transactions": [
                {
                  "id": "52AD1788-4E1C-4797-9BD9-F5B77C9388E2",
                  "date": "May 6, 2024",
                  "units": 10,
                  "unitPrice": 169.21
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let snapshot = try XCTUnwrap(PortfolioStore.decode(legacyJSON))

        XCTAssertEqual(snapshot.exchangeRateUSDToVND, PortfolioSnapshot.defaultExchangeRateUSDToVND, accuracy: 0.001)
        XCTAssertEqual(snapshot.financeAssets.first?.nativeCurrency, .usd)
    }

    func testLegacySeededPortfolioIsDetectedForMigration() throws {
        let snapshot = PortfolioSnapshot(
            version: 1,
            exchangeRateUSDToVND: PortfolioSnapshot.defaultExchangeRateUSDToVND,
            assets: [
                PortfolioAssetSnapshot(asset: makeUSDAsset()),
                PortfolioAssetSnapshot(asset: makeLegacyBTCAsset()),
                PortfolioAssetSnapshot(asset: makeLegacyETHAsset())
            ]
        )

        XCTAssertTrue(snapshot.looksLikeLegacySeededPortfolio)
    }

    func testNonSeededPortfolioDoesNotMatchLegacySeedMigration() throws {
        let snapshot = PortfolioSnapshot(
            version: 1,
            exchangeRateUSDToVND: PortfolioSnapshot.defaultExchangeRateUSDToVND,
            assets: [
                PortfolioAssetSnapshot(asset: makeUSDAsset()),
                PortfolioAssetSnapshot(asset: makeVNDAsset())
            ]
        )

        XCTAssertFalse(snapshot.looksLikeLegacySeededPortfolio)
    }

    func testUITestStorageIsIsolatedFromNormalPortfolioStorage() throws {
        let baseURL = URL(fileURLWithPath: "/tmp/xq-storage-tests", isDirectory: true)
        let normalURL = try XCTUnwrap(PortfolioStore.portfolioURL(namespace: PortfolioStore.normalNamespace, baseURL: baseURL))
        let uiTestURL = try XCTUnwrap(PortfolioStore.portfolioURL(namespace: PortfolioStore.uiTestNamespace, baseURL: baseURL))

        XCTAssertNotEqual(normalURL, uiTestURL)
        XCTAssertNotEqual(PortfolioStore.normalNamespace.keychainService, PortfolioStore.uiTestNamespace.keychainService)
        XCTAssertEqual(PortfolioStore.namespace(arguments: ["app"]), PortfolioStore.normalNamespace)
        XCTAssertEqual(PortfolioStore.namespace(arguments: ["app", "--xq-ui-testing"]), PortfolioStore.uiTestNamespace)
    }

    func testUITestResetRequiresBothIsolationAndResetFlags() {
        XCTAssertFalse(PortfolioStore.shouldResetUITestData(arguments: ["app", "--xq-ui-testing-reset"]))
        XCTAssertFalse(PortfolioStore.shouldResetUITestData(arguments: ["app", "--xq-ui-testing"]))
        XCTAssertTrue(PortfolioStore.shouldResetUITestData(arguments: ["app", "--xq-ui-testing", "--xq-ui-testing-reset"]))
    }

    private func makeUSDAsset() -> FinanceAsset {
        FinanceAsset(
            id: UUID(uuidString: "46C64E8D-039F-4E41-8E0C-7D6D970E3F91")!,
            symbol: "AAPL",
            name: "Apple Inc.",
            nativeCurrency: .usd,
            accent: FinanceAsset.accent(for: "AAPL"),
            currentPrice: 174.65,
            transactions: [
                BuyTransaction(id: UUID(uuidString: "52AD1788-4E1C-4797-9BD9-F5B77C9388E2")!, date: "May 6, 2024", units: 10.000, unitPrice: 169.21),
                BuyTransaction(id: UUID(uuidString: "4A8E62BF-6FDE-482A-9F56-768440E28A5D")!, date: "Apr 15, 2024", units: 15.000, unitPrice: 165.32),
                BuyTransaction(id: UUID(uuidString: "16D2410E-4110-480A-8E83-11DB28DA44E3")!, date: "Mar 1, 2024", units: 20.000, unitPrice: 155.10),
                BuyTransaction(id: UUID(uuidString: "F9403430-4133-491E-84E9-1172DD6D9C5D")!, date: "Jan 16, 2024", units: 15.000, unitPrice: 145.85),
                BuyTransaction(id: UUID(uuidString: "52EC4676-C263-4F45-83F5-7E0F355BF2F3")!, date: "Dec 1, 2023", units: 12.342, unitPrice: 124.56)
            ]
        )
    }

    private func makeVNDAsset() -> FinanceAsset {
        FinanceAsset(
            id: UUID(uuidString: "87A05B55-3282-49EA-98E4-3A2C05B34B20")!,
            symbol: "XAU",
            name: "VND Gold",
            nativeCurrency: .vnd,
            accent: FinanceAsset.accent(for: "XAU"),
            currentPrice: 10_000_000,
            transactions: [
                BuyTransaction(id: UUID(uuidString: "3AE792AC-4B1E-4712-A302-33E6D9F1D1BD")!, date: "May 5, 2024", units: 1.0, unitPrice: 10_000_000)
            ]
        )
    }

    private func makeLegacyBTCAsset() -> FinanceAsset {
        FinanceAsset(
            id: UUID(uuidString: "87A05B55-3282-49EA-98E4-3A2C05B34B20")!,
            symbol: "BTC",
            name: "Bitcoin",
            nativeCurrency: .usd,
            accent: FinanceAsset.accent(for: "BTC"),
            currentPrice: 68_420.00,
            transactions: [
                BuyTransaction(id: UUID(uuidString: "3AE792AC-4B1E-4712-A302-33E6D9F1D1BD")!, date: "May 5, 2024", units: 0.080, unitPrice: 64_210.00)
            ]
        )
    }

    private func makeLegacyETHAsset() -> FinanceAsset {
        FinanceAsset(
            id: UUID(uuidString: "2B90ACF5-4B3D-4F57-9E70-A3363A1F515C")!,
            symbol: "ETH",
            name: "Ethereum",
            nativeCurrency: .usd,
            accent: FinanceAsset.accent(for: "ETH"),
            currentPrice: 3_520.25,
            transactions: [
                BuyTransaction(id: UUID(uuidString: "68BC655E-1F43-4D68-9227-78C4BAA5E7ED")!, date: "May 2, 2024", units: 1.200, unitPrice: 3_120.40)
            ]
        )
    }
}
