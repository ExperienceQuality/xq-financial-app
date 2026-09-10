import XCTest

@MainActor
final class PortfolioLifecycleTests: FinanceUITestCase {
    func testBuyLotRowAndActionsFitInsideAssetCard() {
        let portfolio = PortfolioScreen(application: financeApp)

        portfolio.openAddAsset().add(symbol: "XQTEST", name: "XQ Test Asset", startingPrice: "100")
        portfolio.openBuyLotEditor().add(units: "2", price: "100")

        let card = portfolio.assetCard.requireExistence()
        let row = portfolio.transactionRow.requireExistence()
        let editButton = portfolio.editTransactionButton.requireExistence()
        let deductButton = portfolio.deductTransactionButton.requireExistence()

        XCTAssertTrue(row.isHittable)
        XCTAssertTrue(editButton.isHittable)
        XCTAssertTrue(deductButton.isHittable)
        XCTAssertGreaterThanOrEqual(row.frame.minX, card.frame.minX)
        XCTAssertLessThanOrEqual(row.frame.maxX, card.frame.maxX)
        XCTAssertLessThanOrEqual(editButton.frame.maxX, card.frame.maxX)
        XCTAssertLessThanOrEqual(deductButton.frame.maxX, card.frame.maxX)
    }

    func testPortfolioLifecyclePersistsInIsolatedStorage() {
        var app = financeApp
        var portfolio = PortfolioScreen(application: app)

        portfolio.openAddAsset().add(symbol: "XQTEST", name: "XQ Test Asset", startingPrice: "100")
        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "XQTEST")

        portfolio.openPriceEditor().save(price: "120")
        portfolio.openBuyLotEditor().add(units: "2", price: "120")
        portfolio.transactionRow.requireExistence()
        XCTAssertTrue(portfolio.assetCurrentValue.requireExistence().label.contains("$"))

        portfolio.openFirstBuyLotEditor().updateUnits(to: "3")
        portfolio.transactionRow.requireExistence()

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
