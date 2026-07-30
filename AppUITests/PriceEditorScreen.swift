import XCTest

@MainActor
struct PriceEditorScreen: ScreenObject {
    let application: XCUIApplication

    var priceField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.currentPriceField.rawValue]
    }

    var saveButton: XCUIElement {
        application.buttons[XQAccessibilityIdentifier.priceSaveButton.rawValue]
    }

    func save(price: String) {
        priceField.replaceText(with: price)
        saveButton.tapWhenHittable()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}
