import XCTest

@MainActor
final class MultiAssetDeckTests: FinanceUITestCase {
    func testMultipleAssetsUpdatePositionAndSwipeAdvancesDeck() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "ONE", name: "First Asset", startingPrice: "10")
        XCTAssertEqual(portfolio.portfolioPosition.requireExistence().label, "1 / 1")
        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "ONE")

        portfolio.openAddAsset().add(symbol: "TWO", name: "Second Asset", startingPrice: "20")
        XCTAssertEqual(portfolio.portfolioPosition.requireExistence().label, "1 / 2")

        portfolio.swipeToNextAsset()
        XCTAssertEqual(portfolio.portfolioPosition.requireExistence().label, "2 / 2")
        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "TWO")
        captureScreenshot(named: "Second asset active after deck swipe")
    }

    func testIsolatedResetClearsPersistedAssets() {
        var portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "TMP", name: "Temporary", startingPrice: "1")
        portfolio.assetSymbol.requireExistence()

        let app = resetToCleanState()
        portfolio = PortfolioScreen(application: app)
        portfolio.emptyPortfolio.requireExistence()
        XCTAssertFalse(portfolio.assetSymbol.exists)
        captureScreenshot(named: "Isolated portfolio storage after reset")
    }
}
