import XCTest

@MainActor
final class PortfolioLifecycleTests: FinanceUITestCase {
    func testPortfolioLifecyclePersistsInIsolatedStorage() {
        var app = financeApp
        var portfolio = PortfolioScreen(application: app)

        portfolio.openAddAsset().add(symbol: "XQTEST", name: "XQ Test Asset", startingPrice: "100")
        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "XQTEST")

        portfolio.openPriceEditor().save(price: "120")
        portfolio.openBuyLotEditor().add(units: "2", price: "120")
        portfolio.transactionRow.requireExistence()
        XCTAssertTrue(portfolio.assetCurrentValue.requireExistence().label.contains("$"))

        portfolio.switchToVNDFromSegmentEdge()
        XCTAssertTrue(portfolio.assetCurrentValue.requireExistence().label.contains("VND"))
        portfolio.switchToUSDFromSegmentEdge()
        XCTAssertTrue(portfolio.assetCurrentValue.requireExistence().label.contains("$"))

        portfolio.deductFirstTransaction()
        XCTAssertTrue(portfolio.transactionRow.waitForNonExistence(timeout: 8))

        app = relaunchPreservingTestData()
        portfolio = PortfolioScreen(application: app)
        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "XQTEST")
        XCTAssertFalse(portfolio.transactionRow.exists)
        captureScreenshot(named: "Persisted portfolio after relaunch")
    }
}
