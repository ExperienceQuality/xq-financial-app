import XCTest
import XQXCUITestSupport

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
    override class var applicationDescriptor: ApplicationDescriptor {
        TestApplication.descriptor
    }

    var financeApp: XCUIApplication {
        guard let application else {
            preconditionFailure("Finance UI tests must launch through shared setUp")
        }
        return application
    }

    override func verifyInitialState(in app: XCUIApplication) {
        PortfolioScreen(application: app).emptyPortfolio.requireExistence()
    }

    @discardableResult
    func relaunchPreservingTestData() -> XCUIApplication {
        relaunchApplication(TestApplication.descriptor, reset: false)
    }

    @discardableResult
    func resetToCleanState() -> XCUIApplication {
        let app = relaunchApplication(TestApplication.descriptor, reset: true)
        PortfolioScreen(application: app).emptyPortfolio.requireExistence()
        return app
    }
}
