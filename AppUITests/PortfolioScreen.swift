import XCTest

@MainActor
struct PortfolioScreen: ScreenObject {
    let application: XCUIApplication

    var emptyPortfolio: XCUIElement {
        application.descendants(matching: .any)[XQAccessibilityIdentifier.emptyPortfolio.rawValue]
    }

    var assetCard: XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: XQAccessibilityIdentifier.assetCard.rawValue)
            .firstMatch
    }

    var assetSymbol: XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: XQAccessibilityIdentifier.assetSymbol.rawValue)
            .firstMatch
    }

    var assetCurrentValue: XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: XQAccessibilityIdentifier.assetCurrentValue.rawValue)
            .firstMatch
    }

    var transactionRow: XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: XQAccessibilityIdentifier.transactionRow.rawValue)
            .firstMatch
    }

    var portfolioPosition: XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: XQAccessibilityIdentifier.portfolioPosition.rawValue)
            .firstMatch
    }

    var exchangeRateEditButton: XCUIElement {
        application.buttons[XQAccessibilityIdentifier.exchangeRateEditButton.rawValue]
    }

    func openAddAsset() -> AddAssetScreen {
        application.buttons[XQAccessibilityIdentifier.addAssetButton.rawValue].firstMatch.tapWhenHittable()
        return AddAssetScreen(application: application)
    }

    func openPriceEditor() -> PriceEditorScreen {
        application.buttons[XQAccessibilityIdentifier.editPriceButton.rawValue].tapWhenHittable()
        return PriceEditorScreen(application: application)
    }

    func openBuyLotEditor() -> BuyLotScreen {
        application.buttons[XQAccessibilityIdentifier.addBuyLotButton.rawValue].tapWhenHittable()
        return BuyLotScreen(application: application)
    }

    func openExchangeRateEditor() -> ExchangeRateScreen {
        exchangeRateEditButton.tapWhenHittable()
        return ExchangeRateScreen(application: application)
    }

    func switchToVND() {
        tapDisplayCurrencyToggle(normalizedX: 0.75)
    }

    func switchToUSD() {
        tapDisplayCurrencyToggle(normalizedX: 0.25)
    }

    func switchToVNDFromSegmentEdge() {
        tapDisplayCurrencyToggle(normalizedX: 0.95)
    }

    func switchToUSDFromSegmentEdge() {
        tapDisplayCurrencyToggle(normalizedX: 0.05)
    }

    private func tapDisplayCurrencyToggle(normalizedX: CGFloat) {
        let toggle = application.descendants(matching: .any)[XQAccessibilityIdentifier.displayCurrencyToggle.rawValue]
            .requireExistence()
        toggle.coordinate(withNormalizedOffset: CGVector(dx: normalizedX, dy: 0.5)).tap()
    }

    func deductFirstTransaction(confirm: Bool = true) {
        application.buttons[XQAccessibilityIdentifier.deductTransactionButton.rawValue].firstMatch.tapWhenHittable()
        if confirm {
            confirmDeductionButton().tapWhenHittable()
        } else {
            cancelButtonInPresentedDialog().tapWhenHittable()
        }
    }

    func swipeToNextAsset() {
        assetCard.requireExistence().swipeLeft()
    }

    private func confirmDeductionButton() -> XCUIElement {
        let identifier = XQAccessibilityIdentifier.confirmDeductionButton.rawValue
        let alertButton = application.alerts.buttons[identifier].firstMatch
        if alertButton.waitForExistence(timeout: 2) {
            return alertButton
        }
        return application.alerts.buttons["Confirm Deduction"].firstMatch
    }

    private func cancelButtonInPresentedDialog() -> XCUIElement {
        let identifier = XQAccessibilityIdentifier.cancelDeductionButton.rawValue
        let alertButton = application.alerts.buttons[identifier].firstMatch
        if alertButton.waitForExistence(timeout: 2) {
            return alertButton
        }
        return application.alerts.buttons["Cancel"].firstMatch
    }
}
