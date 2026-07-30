import XCTest

@MainActor
struct BuyLotScreen: ScreenObject {
    let application: XCUIApplication

    var unitsField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.buyLotUnitsField.rawValue]
    }

    var priceField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.buyLotPriceField.rawValue]
    }

    var saveButton: XCUIElement {
        application.buttons[XQAccessibilityIdentifier.buyLotSaveButton.rawValue]
    }

    func add(units: String, price: String) {
        unitsField.replaceText(with: units)
        priceField.replaceText(with: price)
        saveButton.tapWhenHittable()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}
