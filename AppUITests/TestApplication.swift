import XCTest

enum TestApplication {
    static let descriptor = ApplicationDescriptor(
        bundleIdentifier: "com.xq.finance.ios-xq-finance-app",
        launchConfiguration: LaunchConfiguration(
            arguments: ["--xq-ui-testing"],
            resetArguments: ["--xq-ui-testing-reset"]
        )
    )
}

@MainActor
class FinanceUITestCase: BaseUITestCase {
    var financeApp: XCUIApplication {
        guard let application else {
            preconditionFailure("Finance UI tests must launch through shared setUp")
        }
        return application
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = launchApplication(TestApplication.descriptor, reset: true)
        PortfolioScreen(application: app).emptyPortfolio.requireExistence()
    }

    @discardableResult
    func relaunchPreservingTestData() -> XCUIApplication {
        relaunchApplication(TestApplication.descriptor)
    }

    @discardableResult
    func resetToCleanState() -> XCUIApplication {
        let app = relaunchApplication(TestApplication.descriptor, reset: true)
        PortfolioScreen(application: app).emptyPortfolio.requireExistence()
        return app
    }
}
