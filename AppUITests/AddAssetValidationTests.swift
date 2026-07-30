import XCTest

@MainActor
final class AddAssetValidationTests: FinanceUITestCase {
    func testAddAssetRequiresSymbolAndNameAndCancelKeepsPortfolioEmpty() {
        let portfolio = PortfolioScreen(application: financeApp)
        let editor = portfolio.openAddAsset()

        editor.saveButton.requireExistence()
        XCTAssertFalse(editor.saveButton.isEnabled)

        editor.symbolField.replaceText(with: "   ")
        editor.nameField.replaceText(with: "   ")
        XCTAssertFalse(editor.saveButton.isEnabled)

        editor.symbolField.replaceText(with: "ONLY")
        XCTAssertFalse(editor.saveButton.isEnabled)

        editor.cancel()
        portfolio.emptyPortfolio.requireExistence()
        captureScreenshot(named: "Add-asset cancel keeps portfolio empty")
    }

    func testCanCreateVNDNativeAsset() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(
            symbol: "VCB",
            name: "Vietcombank",
            startingPrice: "90000",
            nativeCurrency: "VND"
        )

        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "VCB")
        portfolio.assetCard.requireExistence()
        captureScreenshot(named: "VND native asset created")
    }
}
