import XCTest
import XQXCUITestSupport

extension XCUIElement {
    /// Waits until `label` equals `expected`, then returns self. Fails with the actual label.
    @discardableResult
    func requireLabel(
        _ expected: String,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        let actual = label
        XCTAssertEqual(
            result,
            .completed,
            "Expected label '\(expected)' within \(timeout)s, got '\(actual)'",
            file: file,
            line: line
        )
        return self
    }
}

enum AssetModelAccessibility {
    static let emptyState = "xq.portfolio.empty-state"
    static let addAsset = "xq.portfolio.add-asset"
    static let summaryTotalVND = "xq.portfolio.summary.total-vnd"
    static let summaryExchangeRate = "xq.portfolio.summary.exchange-rate"
    static let editExchangeRate = "xq.portfolio.summary.edit-exchange-rate"
    static let assetCode = "xq.asset.code"
    static let assetName = "xq.asset.name"
    static let assetCurrency = "xq.asset.currency"
    static let assetUnits = "xq.asset.units"
    static let assetPrice = "xq.asset.price"
    static let assetNativeTotal = "xq.asset.native-total"
    static let assetCard = "xq.asset.card"
    static let editPrice = "xq.asset.edit-price"
    static let priceEditorField = "xq.price-editor.price"
    static let priceEditorSave = "xq.price-editor.save"
    static let addUnits = "xq.asset.add-units"
    static let subtractUnits = "xq.asset.subtract-units"
    static let transactionRow = "xq.asset.unit-transaction"
    static let deleteAsset = "xq.asset.delete"
    static let codeField = "xq.asset-editor.code"
    static let nameField = "xq.asset-editor.name"
    static let currencyPicker = "xq.asset-editor.currency"
    static let priceField = "xq.asset-editor.price"
    static let assetSave = "xq.asset-editor.save"
    static let unitAmountField = "xq.unit-editor.amount"
    static let unitSave = "xq.unit-editor.save"
    static let exchangeRateField = "xq.exchange-rate-editor.rate"
    static let exchangeRateSave = "xq.exchange-rate-editor.save"
    static let validationError = "xq.validation.error"
    static let persistenceError = "xq.persistence.error"
    static let dataUnavailable = "xq.persistence.data-unavailable"
    static let deleteConfirm = "xq.asset.delete-confirm"
    static let deleteCancel = "xq.asset.delete-cancel"
}

@MainActor
struct AssetModelPortfolioScreen: ScreenObject {
    let application: XCUIApplication

    var emptyState: XCUIElement { element(AssetModelAccessibility.emptyState) }
    var summaryTotalVND: XCUIElement { element(AssetModelAccessibility.summaryTotalVND) }
    var summaryExchangeRate: XCUIElement { element(AssetModelAccessibility.summaryExchangeRate) }
    var editExchangeRateButton: XCUIElement {
        application.buttons[AssetModelAccessibility.editExchangeRate].firstMatch
    }
    var addAssetButton: XCUIElement {
        application.buttons[AssetModelAccessibility.addAsset].firstMatch
    }

    func assetCard(code: String) -> XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: "\(AssetModelAccessibility.assetCard).\(code)")
            .firstMatch
    }

    func assetCardContaining(code: String) -> XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: AssetModelAccessibility.assetCard)
            .containing(.staticText, identifier: code)
            .firstMatch
    }

    func openAddAsset() -> AssetModelEditorScreen {
        addAssetButton.tapWhenHittable()
        return AssetModelEditorScreen(application: application)
    }

    func openAsset(code: String) -> AssetModelDetailScreen {
        revealAsset(code: code)
        let card = assetCard(code: code)
        if card.exists {
            if (card.value as? String) != "expanded" {
                card.tapWhenHittable()
            }
        } else {
            assetCardContaining(code: code).tapWhenHittable()
        }
        return AssetModelDetailScreen(application: application)
    }

    func openExchangeRate() -> AssetModelExchangeRateScreen {
        revealSummary()
        editExchangeRateButton.tapWhenHittable()
        return AssetModelExchangeRateScreen(application: application)
    }

    /// Scrolls toward the portfolio header until Edit Rate is hittable (max 8 swipeDown).
    @discardableResult
    func revealSummary(timeout: TimeInterval = 8) -> Self {
        for _ in 0..<8 where !editExchangeRateButton.isHittable {
            application.swipeDown()
        }
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: editExchangeRateButton
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected Edit Rate to become hittable after revealSummary"
        )
        return self
    }

    /// Scrolls the list until the asset card exists and is hittable (bounded swipes).
    /// Recovers from unit-editor `swipeUp` first (toward header), then scrolls down if needed.
    @discardableResult
    func revealAsset(code: String, timeout: TimeInterval = 8) -> Self {
        let card = assetCard(code: code)
        for _ in 0..<4 where !card.exists || !card.isHittable {
            application.swipeDown()
        }
        for _ in 0..<8 where !card.exists || !card.isHittable {
            application.swipeUp()
        }
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: card)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected asset card '\(code)' to become hittable after revealAsset"
        )
        return self
    }

    private func element(_ identifier: String) -> XCUIElement {
        application.descendants(matching: .any)[identifier].firstMatch
    }
}

@MainActor
struct AssetModelEditorScreen: ScreenObject {
    let application: XCUIApplication

    var codeField: XCUIElement { application.textFields[AssetModelAccessibility.codeField] }
    var nameField: XCUIElement { application.textFields[AssetModelAccessibility.nameField] }
    var currencyPicker: XCUIElement {
        application.descendants(matching: .any)[AssetModelAccessibility.currencyPicker]
    }
    var priceField: XCUIElement { application.textFields[AssetModelAccessibility.priceField] }
    var saveButton: XCUIElement { application.buttons[AssetModelAccessibility.assetSave] }

    func create(code: String, name: String, currency: String, price: String = "0") {
        codeField.replaceText(with: code)
        nameField.replaceText(with: name)
        currencyPicker.tapWhenHittable()
        application.buttons[currency].firstMatch.tapWhenHittable()
        priceField.replaceText(with: price)
        saveButton.tapWhenHittable()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}

@MainActor
struct AssetModelDetailScreen: ScreenObject {
    let application: XCUIApplication

    var code: XCUIElement { application.staticTexts[AssetModelAccessibility.assetCode] }
    var units: XCUIElement { application.descendants(matching: .any)[AssetModelAccessibility.assetUnits] }
    var price: XCUIElement { application.descendants(matching: .any)[AssetModelAccessibility.assetPrice] }
    var nativeTotal: XCUIElement {
        application.descendants(matching: .any)[AssetModelAccessibility.assetNativeTotal]
    }
    var editPriceButton: XCUIElement { application.buttons[AssetModelAccessibility.editPrice] }
    var addUnitsButton: XCUIElement { application.buttons[AssetModelAccessibility.addUnits] }
    var subtractUnitsButton: XCUIElement { application.buttons[AssetModelAccessibility.subtractUnits] }
    var deleteButton: XCUIElement { application.buttons[AssetModelAccessibility.deleteAsset] }
    var transactionRows: XCUIElementQuery {
        application.descendants(matching: .any)
            .matching(identifier: AssetModelAccessibility.transactionRow)
    }

    @discardableResult
    func scrollToTransaction(at index: Int = 0) -> Self {
        let row = transactionRows.element(boundBy: index)
        scrollUntilHittable(row)
        return self
    }

    func openUnits(operation: String) -> AssetModelUnitEditorScreen {
        let operationButton = application.buttons[operation]
        scrollUntilHittable(operationButton)
        operationButton.tapWhenHittable()
        return AssetModelUnitEditorScreen(application: application)
    }

    func openPriceEditor() -> AssetModelPriceEditorScreen {
        let matchingButtons = application.buttons.matching(
            identifier: AssetModelAccessibility.editPrice
        )
        let hittableButton = (0..<matchingButtons.count)
            .map { matchingButtons.element(boundBy: $0) }
            .first(where: { $0.isHittable })
        XCTAssertNotNil(hittableButton, "Expected a visible Edit Price button")
        hittableButton?.tap()
        return AssetModelPriceEditorScreen(application: application)
    }

    func delete(confirm: Bool) {
        let matchingButtons = application.buttons.matching(
            identifier: AssetModelAccessibility.deleteAsset
        )
        let hittableButton = (0..<matchingButtons.count)
            .map { matchingButtons.element(boundBy: $0) }
            .first(where: { $0.isHittable })
        XCTAssertNotNil(hittableButton, "Expected a visible Delete Asset button")
        hittableButton?.tap()
        let alert = application.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 8), "Expected delete confirmation alert")
        tapAlertButton(confirm ? "Delete Asset" : "Cancel", in: alert)
    }

    private func scrollUntilHittable(_ element: XCUIElement) {
        let collectionView = application.collectionViews.firstMatch
        let scrollContainer = collectionView.exists ? collectionView : application.scrollViews.firstMatch
        XCTAssertTrue(scrollContainer.exists, "Expected a scrollable asset detail container")
        for _ in 0..<8 where !element.isHittable {
            application.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Expected element to become hittable after scrolling")
    }

    private func tapAlertButton(_ label: String, in alert: XCUIElement) {
        let alertButton = alert.buttons[label]
        if alertButton.waitForExistence(timeout: 2) {
            alertButton.tapWhenHittable()
            return
        }

        // SwiftUI may expose alert actions in the application button tree on a physical device.
        application.buttons[label].tapWhenHittable(timeout: 6)
    }
}

@MainActor
struct AssetModelPriceEditorScreen: ScreenObject {
    let application: XCUIApplication

    var priceField: XCUIElement { application.textFields[AssetModelAccessibility.priceEditorField] }
    var saveButton: XCUIElement { application.buttons[AssetModelAccessibility.priceEditorSave] }

    func save(price: String) {
        priceField.replaceText(with: price)
        saveButton.tapWhenHittable()
    }
}

@MainActor
struct AssetModelUnitEditorScreen: ScreenObject {
    let application: XCUIApplication

    var amountField: XCUIElement { application.textFields[AssetModelAccessibility.unitAmountField] }
    var saveButton: XCUIElement { application.buttons[AssetModelAccessibility.unitSave] }

    func save(amount: String) {
        amountField.replaceText(with: amount)
        saveButton.tapWhenHittable()
    }

    /// Saves and waits for the amount field (sheet) to leave the hierarchy.
    func saveExpectingDismissal(amount: String, timeout: TimeInterval = 8) {
        save(amount: amount)
        XCTAssertTrue(
            amountField.waitForNonExistence(timeout: timeout),
            "Expected unit editor sheet to dismiss after save"
        )
    }
}

@MainActor
struct AssetModelExchangeRateScreen: ScreenObject {
    let application: XCUIApplication

    var rateField: XCUIElement { application.textFields[AssetModelAccessibility.exchangeRateField] }
    var saveButton: XCUIElement { application.buttons[AssetModelAccessibility.exchangeRateSave] }

    func save(rate: String) {
        rateField.replaceText(with: rate)
        saveButton.tapWhenHittable()
    }

    /// Saves and waits for the rate field (sheet) to leave the hierarchy.
    func saveExpectingDismissal(rate: String, timeout: TimeInterval = 8) {
        save(rate: rate)
        XCTAssertTrue(
            rateField.waitForNonExistence(timeout: timeout),
            "Expected exchange-rate sheet to dismiss after save"
        )
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}
