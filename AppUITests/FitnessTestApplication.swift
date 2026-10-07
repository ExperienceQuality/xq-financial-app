import XCTest
import XQXCUITestSupport

enum FitnessTestApplication {
    static let descriptor = ApplicationDescriptor(
        bundleIdentifier: "com.xq.finance.ios-xq-finance-app",
        launchConfiguration: LaunchConfiguration(
            arguments: ["--xq-ui-testing"],
            resetArguments: ["--xq-fitness-ui-testing-reset"]
        )
    )
}

enum SuperAppTestApplication {
    static let descriptor = ApplicationDescriptor(
        bundleIdentifier: "com.xq.finance.ios-xq-finance-app",
        launchConfiguration: LaunchConfiguration(
            arguments: ["--xq-ui-testing"],
            resetArguments: [
                "--xq-ui-testing-reset",
                "--xq-fitness-ui-testing-reset"
            ]
        )
    )
}

@MainActor
class FitnessUITestCase: BaseUITestCase {
    override class var applicationDescriptor: ApplicationDescriptor {
        FitnessTestApplication.descriptor
    }

    var fitnessApp: XCUIApplication {
        guard let application else {
            preconditionFailure("Fitness UI tests must launch through shared setUp")
        }
        return application
    }

    override func verifyInitialState(in application: XCUIApplication) {
        selectFitnessTab(in: application)
        RoutineListScreen(application: application).emptyState.requireExistence()
    }

    @discardableResult
    func relaunchPreservingTestData() -> XCUIApplication {
        let app = relaunchApplication(FitnessTestApplication.descriptor, reset: false)
        selectFitnessTab(in: app)
        return app
    }

    @discardableResult
    func resetToCleanState() -> XCUIApplication {
        let app = relaunchApplication(FitnessTestApplication.descriptor, reset: true)
        selectFitnessTab(in: app)
        RoutineListScreen(application: app).emptyState.requireExistence()
        return app
    }

    private func selectFitnessTab(in application: XCUIApplication) {
        application.descendants(matching: .any)["super-app.tab.fitness"].tapWhenHittable()
    }
}
