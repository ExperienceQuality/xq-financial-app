import XCTest

@MainActor
struct AddAssetScreen: ScreenObject {
    let application: XCUIApplication

    var symbolField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.symbolField.rawValue]
    }

    var nameField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.nameField.rawValue]
    }

    var startingPriceField: XCUIElement {
        application.textFields[XQAccessibilityIdentifier.startingPriceField.rawValue]
    }

    var saveButton: XCUIElement {
        application.buttons[XQAccessibilityIdentifier.addAssetSaveButton.rawValue]
    }

    var nativeCurrencyPicker: XCUIElement {
        application.descendants(matching: .any)[XQAccessibilityIdentifier.assetNativeCurrencyPicker.rawValue]
    }

    func add(
        symbol: String,
        name: String,
        startingPrice: String,
        nativeCurrency: String? = nil
    ) {
        symbolField.replaceText(with: symbol)
        nameField.replaceText(with: name)
        if let nativeCurrency {
            nativeCurrencyPicker.requireExistence()
            application.buttons[nativeCurrency].firstMatch.tapWhenHittable()
        }
        startingPriceField.replaceText(with: startingPrice)
        saveButton.tapWhenHittable()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}
