import XCTest

@MainActor
final class SheetValidationTests: FinanceUITestCase {
    func testPriceAndBuyLotValidationAndCancelLeaveStateUnchanged() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "AAPL", name: "Apple", startingPrice: "100")
        let originalValue = portfolio.assetCurrentValue.requireExistence().label

        let priceEditor = portfolio.openPriceEditor()
        priceEditor.priceField.replaceText(with: "abc")
        XCTAssertFalse(priceEditor.saveButton.isEnabled)
        priceEditor.cancel()
        XCTAssertEqual(portfolio.assetCurrentValue.requireExistence().label, originalValue)

        let buyLot = portfolio.openBuyLotEditor()
        buyLot.unitsField.replaceText(with: "0")
        buyLot.priceField.replaceText(with: "10")
        XCTAssertFalse(buyLot.saveButton.isEnabled)
        buyLot.cancel()
        XCTAssertFalse(portfolio.transactionRow.exists)
        captureScreenshot(named: "Sheet cancel and validation leave portfolio unchanged")
    }
}
