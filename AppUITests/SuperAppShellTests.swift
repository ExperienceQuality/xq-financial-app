import XCTest
import XQXCUITestSupport

@MainActor
final class SuperAppShellTests: FinanceUITestCase {
    override class var applicationDescriptor: ApplicationDescriptor {
        SuperAppTestApplication.descriptor
    }

    private var financeTab: XCUIElement {
        financeApp.descendants(matching: .any)["super-app.tab.finance"]
    }

    private var fitnessTab: XCUIElement {
        financeApp.descendants(matching: .any)["super-app.tab.fitness"]
    }

    func testFinanceIsDefaultAndBothFeatureTabsHaveStableIdentifiers() {
        AssetModelPortfolioScreen(application: financeApp).emptyState.requireExistence()
        financeTab.requireExistence()
        fitnessTab.requireExistence()
        XCTAssertTrue(financeTab.isSelected)
        XCTAssertFalse(fitnessTab.isSelected)
        XCTAssertNotEqual(financeTab.identifier, fitnessTab.identifier)
    }

    func testFeatureSwitchingRetainsFinanceAssetAndFitnessRoutineState() {
        let portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(
            code: "SHELL",
            name: "Shared Shell Asset",
            currency: "VND",
            price: "100"
        )
        portfolio.assetCard(code: "SHELL").requireExistence()

        fitnessTab.tapWhenHittable()
        let routines = RoutineListScreen(application: financeApp)
        routines.emptyState.requireExistence()
        routines.openCreateRoutine().save(
            name: "Shared Shell Routine",
            notes: "State survives tab changes"
        )
        routines.routine(named: "Shared Shell Routine").requireExistence()

        financeTab.tapWhenHittable()
        AssetModelPortfolioScreen(application: financeApp)
            .assetCard(code: "SHELL")
            .requireExistence()

        fitnessTab.tapWhenHittable()
        RoutineListScreen(application: financeApp)
            .routine(named: "Shared Shell Routine")
            .requireExistence()
    }

    func testShellSmokeSupportsCurrentDeviceFamily() {
        financeTab.requireExistence()
        fitnessTab.tapWhenHittable()
        RoutineListScreen(application: financeApp).emptyState.requireExistence()
        financeTab.tapWhenHittable()
        AssetModelPortfolioScreen(application: financeApp).emptyState.requireExistence()
    }
}
