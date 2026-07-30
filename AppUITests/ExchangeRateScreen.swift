import XCTest

@MainActor
struct ExchangeRateScreen: ScreenObject {
    let application: XCUIApplication

    var rateField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.exchangeRateField.rawValue]
    }

    var saveButton: XCUIElement {
        application.buttons[XQAccessibilityIdentifier.exchangeRateSaveButton.rawValue]
    }

    func save(rate: String) {
        rateField.replaceText(with: rate)
        saveButton.tapWhenHittable()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}
