import XCTest

@MainActor
final class BuyLotEditingTests: FinanceUITestCase {
    func testEditingSecondLotPrefillsLosslesslyAndSavesOnlyThatLot() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio
            .openAddAsset()
            .add(symbol: "AAPL", name: "Apple", startingPrice: "150")
        
        portfolio
            .openBuyLotEditor()
            .add(units: "0.123456789", price: "12.3456789")
        
        portfolio
            .openBuyLotEditor()
            .add(units: "2", price: "100")

        let editor = BuyLotEditingScreen(application: financeApp)
        
        editor
            .openEditor(at: 1)
            .assertDraft(units: "0.123456789", price: "12.3456789")
        
        editor.save(units: "0.987654321", price: "23.4567891")

        editor
            .openEditor(at: 1)
            .assertDraft(units: "0.987654321", price: "23.4567891")
        
        editor.cancel()

        editor
            .openEditor(at: 0)
            .assertDraft(units: "2", price: "100")
        editor.cancel()

        portfolio
            .openPriceEditor()
            .save(price: "200")

        portfolio.assertPortfolioTotal("$597.53")
    }

    func testInvalidDraftDisablesSaveAndCancelDiscardsValidDraft() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "MSFT", name: "Microsoft", startingPrice: "150")
        portfolio.openBuyLotEditor().add(units: "2", price: "100")

        let editor = BuyLotEditingScreen(application: financeApp)
        editor.openEditor(at: 0)
        editor.replaceDraft(units: "0", price: "999")
        XCTAssertFalse(editor.saveButton.isEnabled)

        editor.replaceDraft(units: "3", price: "110")
        XCTAssertTrue(editor.saveButton.isEnabled)
        editor.cancel()

        editor.openEditor(at: 0)
        editor.assertDraft(units: "2", price: "100")
        editor.cancel()
    }

    func testEditedLotPersistsAcrossRelaunchAndCanBeDeductedWithoutRemovingSibling() {
        var app = financeApp
        var portfolio = PortfolioScreen(application: app)
        portfolio.openAddAsset().add(symbol: "AAPL", name: "Apple", startingPrice: "150")
        portfolio.openBuyLotEditor().add(units: "0.5", price: "25")
        portfolio.openBuyLotEditor().add(units: "2", price: "100")

        var editor = BuyLotEditingScreen(application: app)
        editor.openEditor(at: 1)
        editor.save(units: "0.75", price: "30")

        app = relaunchPreservingTestData()
        portfolio = PortfolioScreen(application: app)
        XCTAssertEqual(portfolio.assetSymbol.requireExistence().label, "AAPL")
        editor = BuyLotEditingScreen(application: app)
        editor.openEditor(at: 1)
        editor.assertDraft(units: "0.75", price: "30")
        editor.cancel()

        editor.deduct(at: 1)
        editor.openEditor(at: 0)
        editor.assertDraft(units: "2", price: "100")
        editor.cancel()
    }

    func testEditControlHasStableIdentityVoiceOverLabelAndMinimumHitTarget() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "AAPL", name: "Apple", startingPrice: "150")
        portfolio.openBuyLotEditor().add(units: "2", price: "100")

        let editor = BuyLotEditingScreen(application: financeApp)
        let editButton = editor.editButton(at: 0).requireExistence()

        XCTAssertEqual(editButton.identifier, "xq.transaction.edit")
        XCTAssertEqual(editButton.label, "Edit buy lot from \(Self.currentBuyLotDate)")
        XCTAssertGreaterThanOrEqual(editButton.frame.width, 44)
        XCTAssertGreaterThanOrEqual(editButton.frame.height, 44)
        XCTAssertTrue(editButton.isHittable)
    }

    func testAccessibilityDynamicTypeSupportsRowScrollingEditingAndDeckSwipe() {
        let app = financeApp
        var portfolio = PortfolioScreen(application: app)
        portfolio.openAddAsset().add(symbol: "LOTS", name: "Lots Asset", startingPrice: "150")
        portfolio.openBuyLotEditor().add(units: "1", price: "10")
        portfolio.openBuyLotEditor().add(units: "2", price: "20")
        portfolio.openBuyLotEditor().add(units: "3", price: "30")
        portfolio.openBuyLotEditor().add(units: "4", price: "40")
        portfolio.openAddAsset().add(symbol: "BASE", name: "Base Asset", startingPrice: "50")

        app.terminate()
        app.launchArguments = TestApplication.descriptor.launchConfiguration.arguments(reset: false) + [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launchEnvironment = TestApplication.descriptor.launchConfiguration.environment
        app.launch()
        portfolio = PortfolioScreen(application: app)
        portfolio.waitForAsset(symbol: "BASE", position: "1 / 2")
        portfolio.swipeToNextAsset()
        portfolio.waitForAsset(symbol: "LOTS", position: "2 / 2")

        let editor = BuyLotEditingScreen(application: app)
        editor.scrollToEditor(at: 3)
        editor.assertDraft(units: "1", price: "10")
        editor.cancel()

        portfolio = PortfolioScreen(application: app)
        portfolio.swipeToPreviousAsset()
        portfolio.waitForAsset(symbol: "BASE", position: "1 / 2")
    }

    private static var currentBuyLotDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: .now)
    }
}
