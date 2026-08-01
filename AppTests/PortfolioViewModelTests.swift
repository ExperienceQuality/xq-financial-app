import XCTest
@testable import ios_xq_finance_app

@MainActor
final class PortfolioViewModelTests: XCTestCase {
    func testAddAssetInsertsAtFrontAndResetsDeckIndex() {
        let existing = FinanceAsset(
            id: UUID(),
            symbol: "AAPL",
            name: "Apple Inc.",
            nativeCurrency: .usd,
            accent: FinanceAsset.accent(for: "AAPL"),
            currentPrice: 100,
            transactions: []
        )
        let viewModel = PortfolioViewModel(
            portfolio: PortfolioSnapshot(assets: [existing], exchangeRateUSDToVND: 25_500)
        )
        viewModel.activeIndex = 0

        viewModel.addAsset(
            symbol: " vcb ",
            name: " Vietcombank ",
            nativeCurrency: .vnd,
            startingPrice: 90_000
        )

        XCTAssertEqual(viewModel.assets.count, 2)
        XCTAssertEqual(viewModel.assets[0].symbol, "VCB")
        XCTAssertEqual(viewModel.assets[0].name, "Vietcombank")
        XCTAssertEqual(viewModel.assets[0].nativeCurrency, .vnd)
        XCTAssertEqual(viewModel.assets[0].currentPrice, 90_000, accuracy: 0.001)
        XCTAssertEqual(viewModel.activeIndex, 0)
        XCTAssertEqual(viewModel.deckPositionLabel, 1)
    }

    func testPortfolioTotalValueSumsAssetsInUSD() {
        let usd = FinanceAsset(
            id: UUID(),
            symbol: "AAPL",
            name: "Apple",
            nativeCurrency: .usd,
            accent: .black,
            currentPrice: 100,
            transactions: [
                BuyTransaction(id: UUID(), date: "Jan 1, 2026", units: 2, unitPrice: 100)
            ]
        )
        let vnd = FinanceAsset(
            id: UUID(),
            symbol: "XAU",
            name: "Gold",
            nativeCurrency: .vnd,
            accent: .yellow,
            currentPrice: 25_500,
            transactions: [
                BuyTransaction(id: UUID(), date: "Jan 1, 2026", units: 1, unitPrice: 25_500)
            ]
        )
        let viewModel = PortfolioViewModel(
            portfolio: PortfolioSnapshot(assets: [usd, vnd], exchangeRateUSDToVND: 25_500)
        )

        // 2 * 100 USD + (25_500 VND / 25_500) USD
        XCTAssertEqual(viewModel.portfolioTotalValue, 201, accuracy: 0.001)
    }
}
