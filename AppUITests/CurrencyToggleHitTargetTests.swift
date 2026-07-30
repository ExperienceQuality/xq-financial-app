import XCTest

@MainActor
final class CurrencyToggleHitTargetTests: FinanceUITestCase {
    func testCurrencyToggleRespondsToEdgeTaps() {
        let app = financeApp
        let toggle = app.descendants(matching: .any)[XQAccessibilityIdentifier.displayCurrencyToggle.rawValue]
            .requireExistence()

        XCTAssertEqual(toggle.value as? String, "USD")
        captureScreenshot(named: "Currency toggle starts on USD")

        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.requireExistence().value as? String, "VND")
        captureScreenshot(named: "Currency toggle after right edge tap")

        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        XCTAssertEqual(toggle.requireExistence().value as? String, "USD")
        captureScreenshot(named: "Currency toggle after left edge tap")
    }
}
