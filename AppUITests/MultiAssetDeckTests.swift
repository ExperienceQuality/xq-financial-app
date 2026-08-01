import XCTest

@MainActor
final class MultiAssetDeckTests: FinanceUITestCase {
    func testMultipleAssetsUpdatePositionAndSwipeAdvancesDeck() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "ONE", name: "First Asset", startingPrice: "10")
        portfolio.waitForAsset(symbol: "ONE", position: "1 / 1")

        portfolio.openAddAsset().add(symbol: "TWO", name: "Second Asset", startingPrice: "20")
        portfolio.waitForAsset(symbol: "TWO", position: "1 / 2")

        portfolio.swipeToNextAsset()
        portfolio.waitForAsset(symbol: "ONE", position: "2 / 2")
        captureScreenshot(named: "Second asset active after deck swipe")
    }

    func testThreeAssetsSwipeLeftAndRightStayInOrder() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "AAA", name: "Asset A", startingPrice: "1")
        portfolio.openAddAsset().add(symbol: "BBB", name: "Asset B", startingPrice: "2")
        portfolio.openAddAsset().add(symbol: "CCC", name: "Asset C", startingPrice: "3")
        // Newest insert is front of deck.
        portfolio.waitForAsset(symbol: "CCC", position: "1 / 3")

        portfolio.swipeToNextAsset()
        portfolio.waitForAsset(symbol: "BBB", position: "2 / 3")

        portfolio.swipeToNextAsset()
        portfolio.waitForAsset(symbol: "AAA", position: "3 / 3")

        portfolio.swipeToPreviousAsset()
        portfolio.waitForAsset(symbol: "BBB", position: "2 / 3")

        portfolio.swipeToPreviousAsset()
        portfolio.waitForAsset(symbol: "CCC", position: "1 / 3")
        captureScreenshot(named: "Deck order after left and right swipes")
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
