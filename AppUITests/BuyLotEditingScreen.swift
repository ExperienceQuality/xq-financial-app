import XCTest

@MainActor
struct BuyLotEditingScreen: ScreenObject {
    let application: XCUIApplication

    private var editButtons: XCUIElementQuery {
        application.buttons.matching(identifier: "xq.transaction.edit")
    }

    private var deductButtons: XCUIElementQuery {
        application.buttons.matching(
            identifier: XQAccessibilityIdentifier.deductTransactionButton.rawValue
        )
    }

    var unitsField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.buyLotUnitsField.rawValue]
    }

    var priceField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.buyLotPriceField.rawValue]
    }

    var saveButton: XCUIElement {
        application.buttons[XQAccessibilityIdentifier.buyLotSaveButton.rawValue]
    }

    var cancelButton: XCUIElement {
        application.buttons["Cancel"]
    }

    func editButton(at index: Int) -> XCUIElement {
        XCTAssertGreaterThan(
            editButtons.count,
            index,
            "Expected buy-lot edit button at row \(index)"
        )
        return editButtons.element(boundBy: index)
    }

    func deductButton(at index: Int) -> XCUIElement {
        XCTAssertGreaterThan(
            deductButtons.count,
            index,
            "Expected buy-lot deduction button at row \(index)"
        )
        return deductButtons.element(boundBy: index)
    }

    @discardableResult
    func openEditor(at index: Int) -> Self {
        editButton(at: index).tapWhenHittable()
        unitsField.requireExistence()
        priceField.requireExistence()
        return self
    }

    @discardableResult
    func scrollToEditor(at index: Int) -> Self {
        let button = editButton(at: index)
        let scrollView = application.scrollViews.firstMatch.requireExistence()

        for _ in 0..<5 where !button.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(button.isHittable, "Buy-lot edit button at row \(index) did not become hittable")
        button.tapWhenHittable()
        unitsField.requireExistence()
        priceField.requireExistence()
        return self
    }

    func assertDraft(
        units expectedUnits: String,
        price expectedPrice: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(unitsField.requireExistence().value as? String, expectedUnits, file: file, line: line)
        XCTAssertEqual(priceField.requireExistence().value as? String, expectedPrice, file: file, line: line)
    }

    func save(units: String, price: String) {
        replaceDraft(units: units, price: price)
        saveButton.tapWhenHittable()
        XCTAssertTrue(unitsField.waitForNonExistence(timeout: 8))
    }

    func replaceDraft(units: String, price: String) {
        unitsField.replaceText(with: units)
        priceField.replaceText(with: price)
    }

    func cancel() {
        cancelButton.tapWhenHittable()
        XCTAssertTrue(unitsField.waitForNonExistence(timeout: 8))
    }

    func deduct(at index: Int) {
        let button = deductButton(at: index)
        button.tapWhenHittable()

        let identifier = XQAccessibilityIdentifier.confirmDeductionButton.rawValue
        let identifiedButton = application.alerts.buttons[identifier].firstMatch
        let confirmButton = identifiedButton.waitForExistence(timeout: 2)
            ? identifiedButton
            : application.alerts.buttons["Confirm Deduction"].firstMatch
        confirmButton.tapWhenHittable()
        XCTAssertTrue(button.waitForNonExistence(timeout: 8))
    }
}
