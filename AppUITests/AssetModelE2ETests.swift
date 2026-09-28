import XCTest

@MainActor
final class AssetModelE2ETests: FinanceUITestCase {
    func testEmptyPortfolioShowsVNDHeaderAndAddAssetAction() {
        let portfolio = AssetModelPortfolioScreen(application: financeApp)

        portfolio.emptyState.requireExistence()
        XCTAssertEqual(portfolio.summaryTotalVND.requireExistence().label, "₫0")
        portfolio.summaryExchangeRate.requireExistence()
        portfolio.addAssetButton.requireExistence()
    }

    func testCreateUSDAndVNDAssetsStartsAtZeroAndCardsUseNativeCurrency() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "USD1", name: "Dollar Asset", currency: "USD")
        portfolio.openAddAsset().create(code: "VND1", name: "Dong Asset", currency: "VND")

        portfolio.assetCard(code: "USD1").requireExistence()
        portfolio.assetCard(code: "VND1").requireExistence()
        _ = portfolio.openAsset(code: "USD1")
        XCTAssertTrue(portfolio.assetCard(code: "USD1").requireExistence().label.contains("$0"))
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        _ = portfolio.openAsset(code: "VND1")
        XCTAssertTrue(portfolio.assetCard(code: "VND1").requireExistence().label.contains("₫0"))
    }

    func testPriceEditUpdatesNativeCardAndPortfolioSummary() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "PRICE", name: "Priced Asset", currency: "VND")
        let detail = portfolio.openAsset(code: "PRICE")
        detail.openPriceEditor().save(price: "100000")

        XCTAssertTrue(detail.price.requireExistence().label.contains("100000"))
        XCTAssertEqual(AssetModelPortfolioScreen(application: financeApp).summaryTotalVND.requireExistence().label, "₫0")
    }

    func testExchangeRateChangeRecalculatesUSDContributionButNotVNDAsset() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "USD", name: "Dollar Asset", currency: "USD", price: "100")
        portfolio.openAsset(code: "USD").openUnits(operation: AssetModelAccessibility.addUnits)
            .save(amount: "2")
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "VND", name: "Dong Asset", currency: "VND", price: "100000")
        portfolio.openAsset(code: "VND").openUnits(operation: AssetModelAccessibility.addUnits)
            .save(amount: "3")

        portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openExchangeRate().save(rate: "25000")
        XCTAssertEqual(portfolio.summaryTotalVND.requireExistence().label, "₫5,300,000")
        portfolio.openExchangeRate().save(rate: "26000")
        XCTAssertEqual(portfolio.summaryTotalVND.requireExistence().label, "₫5,500,000")
    }

    func testAddAndSubtractUnitsCreateTransactionsAndRecalculateSummary() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "UNIT", name: "Unit Asset", currency: "VND", price: "100")
        var detail = portfolio.openAsset(code: "UNIT")
        detail.openUnits(operation: AssetModelAccessibility.addUnits).save(amount: "5")
        XCTAssertTrue(AssetModelPortfolioScreen(application: financeApp)
            .assetCard(code: "UNIT").requireExistence().label.contains("5"))
        detail.scrollToTransaction()
        XCTAssertTrue(detail.transactionRows.element(boundBy: 0).requireExistence().label.contains("5"))
        XCTAssertEqual(AssetModelPortfolioScreen(application: financeApp).summaryTotalVND.requireExistence().label, "₫500")

        detail = AssetModelPortfolioScreen(application: financeApp).openAsset(code: "UNIT")
        detail.openUnits(operation: AssetModelAccessibility.subtractUnits).save(amount: "2")
        XCTAssertTrue(AssetModelPortfolioScreen(application: financeApp)
            .assetCard(code: "UNIT").requireExistence().label.contains("3"))
        XCTAssertEqual(AssetModelPortfolioScreen(application: financeApp).summaryTotalVND.requireExistence().label, "₫300")
    }

    func testSubtractingMoreThanAvailableIsRejectedWithoutMutation() {
        let portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "LIMIT", name: "Limited Asset", currency: "VND", price: "100")
        let detail = portfolio.openAsset(code: "LIMIT")
        detail.openUnits(operation: AssetModelAccessibility.addUnits).save(amount: "1")
        detail.openUnits(operation: AssetModelAccessibility.subtractUnits).save(amount: "2")

        financeApp.descendants(matching: .any)[AssetModelAccessibility.validationError].requireExistence()
        financeApp.buttons["Cancel"].tapWhenHittable()
        XCTAssertTrue(AssetModelPortfolioScreen(application: financeApp)
            .assetCard(code: "LIMIT").requireExistence().label.contains("1"))
        detail.scrollToTransaction()
        XCTAssertEqual(detail.transactionRows.count, 1)
    }

    func testUnitAndPriceChangesPersistAfterRelaunch() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "RELAUNCH", name: "Persistent Asset", currency: "USD", price: "12")
        portfolio.openAsset(code: "RELAUNCH").openUnits(operation: AssetModelAccessibility.addUnits).save(amount: "4")

        _ = relaunchPreservingTestData()
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        let detail = portfolio.openAsset(code: "RELAUNCH")
        XCTAssertTrue(portfolio.assetCard(code: "RELAUNCH").requireExistence().label.contains("4"))
        XCTAssertTrue(detail.price.requireExistence().label.contains("12"))
    }

    func testDeleteCancelPreservesAssetAndConfirmRemovesOnlySelectedAsset() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "KEEP", name: "Keep Asset", currency: "VND")
        portfolio.openAddAsset().create(code: "REMOVE", name: "Remove Asset", currency: "VND")
        portfolio.openAsset(code: "REMOVE").delete(confirm: false)
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.assetCard(code: "REMOVE").requireExistence()
        portfolio.openAsset(code: "REMOVE").delete(confirm: true)
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        XCTAssertTrue(portfolio.assetCard(code: "REMOVE").waitForNonExistence(timeout: 4))
        portfolio.assetCard(code: "KEEP").requireExistence()
    }

    func testAssetCardIsDirectlyTappableAndActionsAreNotSwipeOnly() {
        let portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "TAP", name: "Tap Asset", currency: "VND")
        let card = portfolio.assetCard(code: "TAP").requireExistence()
        XCTAssertTrue(card.isHittable)
        let detail = portfolio.openAsset(code: "TAP")
        detail.addUnitsButton.requireExistence()
        detail.subtractUnitsButton.requireExistence()
        detail.editPriceButton.requireExistence()
    }

    func testAccessibilityContractsExposeLabelsForSummaryAndAssetActions() {
        let portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.summaryTotalVND.requireExistence()
        portfolio.summaryExchangeRate.requireExistence()
        portfolio.addAssetButton.requireExistence()
        portfolio.openAddAsset().cancel()
        XCTAssertFalse(financeApp.buttons["Add Units"].exists)
    }

    func testUITestResetClearsOnlyDeterministicTestNamespace() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(code: "RESET", name: "Reset Asset", currency: "VND")

        _ = resetToCleanState()
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.emptyState.requireExistence()
        XCTAssertFalse(portfolio.assetCard(code: "RESET").exists)
    }
}
