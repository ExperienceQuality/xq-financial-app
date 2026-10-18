import XCTest

@MainActor
final class AssetDeletionTests: FinanceUITestCase {
    func testCancelingAssetDeletionKeepsAsset() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "AAPL", name: "Apple", currency: "USD", price: "100")

        portfolio.openAsset(code: "AAPL").delete(confirm: false)

        portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.assetCard(code: "AAPL").requireExistence()
        XCTAssertFalse(portfolio.emptyState.exists)
    }

    func testConfirmingAssetDeletionRemovesAssetAndPersists() {
        var app = financeApp
        var portfolio = AssetModelPortfolioScreen(application: app)
        portfolio.openAddAsset().create(code: "AAPL", name: "Apple", currency: "USD", price: "100")

        portfolio.openAsset(code: "AAPL").delete(confirm: true)

        portfolio.emptyState.requireExistence()
        XCTAssertTrue(portfolio.assetCard(code: "AAPL").waitForNonExistence(timeout: 4))

        app = relaunchPreservingTestData()
        portfolio = AssetModelPortfolioScreen(application: app)
        portfolio.emptyState.requireExistence()
        XCTAssertFalse(portfolio.assetCard(code: "AAPL").exists)
    }
}
