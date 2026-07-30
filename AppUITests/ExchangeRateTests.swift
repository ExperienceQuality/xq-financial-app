import XCTest

@MainActor
final class ExchangeRateTests: FinanceUITestCase {
    func testExchangeRateUpdatePersistsAndAffectsVNDDisplay() {
        var app = financeApp
        var portfolio = PortfolioScreen(application: app)
        portfolio.openAddAsset().add(symbol: "RATE", name: "Rate Asset", startingPrice: "100")
        portfolio.openBuyLotEditor().add(units: "1", price: "100")

        portfolio.openExchangeRateEditor().save(rate: "30000")
        XCTAssertTrue(
            portfolio.exchangeRateEditButton.requireExistence().label.contains("30000")
                || app.staticTexts["1 USD = 30000 VND"].waitForExistence(timeout: 4)
        )

        portfolio.switchToVND()
        XCTAssertTrue(portfolio.assetCurrentValue.requireExistence().label.contains("VND"))

        app = relaunchPreservingTestData()
        portfolio = PortfolioScreen(application: app)
        XCTAssertTrue(
            portfolio.exchangeRateEditButton.requireExistence().label.contains("30000")
                || app.staticTexts["1 USD = 30000 VND"].waitForExistence(timeout: 4)
        )
        captureScreenshot(named: "Exchange rate persists after relaunch")
    }

    func testExchangeRateCancelLeavesRateUnchanged() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "KEEP", name: "Keep Rate", startingPrice: "50")
        let before = portfolio.exchangeRateEditButton.requireExistence().label

        let editor = portfolio.openExchangeRateEditor()
        editor.rateField.replaceText(with: "99999")
        editor.cancel()
        XCTAssertEqual(portfolio.exchangeRateEditButton.requireExistence().label, before)
        captureScreenshot(named: "Exchange rate cancel leaves display unchanged")
    }
}
