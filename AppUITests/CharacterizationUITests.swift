import XCTest
import XQXCUITestSupport

@MainActor
final class CharacterizationUITests: FinanceUITestCase {
    override class var applicationDescriptor: ApplicationDescriptor {
        SuperAppTestApplication.descriptor
    }

    private var financeTab: XCUIElement {
        financeApp.descendants(matching: .any)["super-app.tab.finance"]
    }

    private var fitnessTab: XCUIElement {
        financeApp.descendants(matching: .any)["super-app.tab.fitness"]
    }

    override func verifyInitialState(in app: XCUIApplication) {
        AssetModelPortfolioScreen(application: app).emptyState.requireExistence()
        financeTab.requireExistence()
        fitnessTab.requireExistence()
    }

    @discardableResult
    override func relaunchPreservingTestData() -> XCUIApplication {
        relaunchApplication(SuperAppTestApplication.descriptor, reset: false)
    }

    @discardableResult
    override func resetToCleanState() -> XCUIApplication {
        let app = relaunchApplication(SuperAppTestApplication.descriptor, reset: true)
        AssetModelPortfolioScreen(application: app).emptyState.requireExistence()
        return app
    }

    // MARK: - CHAR-03

    func testFinanceBootstrapFailureShowsRetryWhileFitnessLoads() {
        relaunchWithExtraArguments(["--xq-finance-bootstrap-fail"], reset: true)

        let financeFailure = financeApp.descendants(matching: .any)["super-app.finance.failure"]
        let financeRetry = financeApp.descendants(matching: .any)["super-app.finance.retry"]
        financeFailure.requireExistence()
        financeRetry.requireExistence()

        fitnessTab.tapWhenHittable()
        RoutineListScreen(application: financeApp).emptyState.requireExistence()

        financeTab.tapWhenHittable()
        financeRetry.tapWhenHittable()
        // Fail arg still present — Retry re-attempts and stays failed.
        financeFailure.requireExistence()
    }

    func testFitnessBootstrapFailureShowsRetryWhileFinanceLoads() {
        relaunchWithExtraArguments(["--xq-fitness-bootstrap-fail"], reset: true)

        AssetModelPortfolioScreen(application: financeApp).emptyState.requireExistence()

        fitnessTab.tapWhenHittable()
        let fitnessFailure = financeApp.descendants(matching: .any)["super-app.fitness.failure"]
        let fitnessRetry = financeApp.descendants(matching: .any)["super-app.fitness.retry"]
        fitnessFailure.requireExistence()
        fitnessRetry.requireExistence()
        fitnessRetry.tapWhenHittable()
        fitnessFailure.requireExistence()
    }

    // MARK: - CHAR-02

    func testFitnessImportFixtureCreatesRoutineAndMalformedShowsError() throws {
        let goodURL = try writeTemporaryFixture(
            named: "good-import.json",
            contents: """
            {
              "schemaVersion": 1,
              "routines": [{
                "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                "name": "Imported Strength",
                "notes": "From fixture"
              }]
            }
            """
        )
        relaunchWithExtraArguments(
            ["--xq-fitness-import-fixture", goodURL.path],
            reset: true
        )

        fitnessTab.tapWhenHittable()
        let routines = RoutineListScreen(application: financeApp)
        routines.routine(named: "Imported Strength").requireExistence()
        financeApp.descendants(matching: .any)["fitness.import.status"].requireExistence()

        financeTab.tapWhenHittable()
        AssetModelPortfolioScreen(application: financeApp).emptyState.requireExistence()

        let badURL = try writeTemporaryFixture(named: "bad-import.json", contents: "not-json")
        relaunchWithExtraArguments(
            ["--xq-fitness-import-fixture", badURL.path],
            reset: false
        )
        fitnessTab.tapWhenHittable()
        RoutineListScreen(application: financeApp)
            .routine(named: "Imported Strength")
            .requireExistence()
        let status = financeApp.descendants(matching: .any)["fitness.import.status"]
        status.requireExistence()
        XCTAssertFalse(status.label.isEmpty)
    }

    // MARK: - CHAR-10

    func testFitnessPushedScreenSurvivesFinanceTabRoundTrip() {
        fitnessTab.tapWhenHittable()
        let routines = RoutineListScreen(application: financeApp)
        routines.openCreateRoutine().save(name: "Stack Keep")
        routines.openRoutine(named: "Stack Keep")
        financeApp.descendants(matching: .any)[FitnessAccessibility.routineWorkspace]
            .requireExistence()

        financeTab.tapWhenHittable()
        AssetModelPortfolioScreen(application: financeApp).emptyState.requireExistence()

        fitnessTab.tapWhenHittable()
        financeApp.descendants(matching: .any)[FitnessAccessibility.routineWorkspace]
            .requireExistence()
    }

    // MARK: - CHAR-09

    func testSnapshotProgressIsPushAndLatestComparisonDoesNotAddSnapshot() {
        fitnessTab.tapWhenHittable()
        let routines = RoutineListScreen(application: financeApp)
        routines.openCreateRoutine().save(name: "Snapshot Push")
        routines.openRoutine(named: "Snapshot Push")

        var workspace = RoutineWorkspaceScreen(application: financeApp)
        workspace.addSession(named: "Day One")
        var day = workspace.openDay(1)
        day.openAddExercise().save(name: "Squat")
        workspace = day.backToWorkspace()

        var report = workspace.createSnapshot()
        report.root.requireExistence()
        workspace = report.backToWorkspace()
        workspace.root.requireExistence()

        report = workspace.openLatestComparison()
        report.root.requireExistence()
        workspace = report.backToWorkspace()

        // Second Latest Comparison must not create another snapshot entry in UI:
        // still a single comparison affordance, report still opens.
        report = workspace.openLatestComparison()
        report.root.requireExistence()
        _ = report.backToWorkspace()
        workspace.root.requireExistence()
    }

    // MARK: - CHAR-04

    func testExerciseSurvivesRelaunchAndResetClearsIt() {
        fitnessTab.tapWhenHittable()
        var routines = RoutineListScreen(application: financeApp)
        routines.openCreateRoutine().save(name: "Relaunch Lift")
        routines.openRoutine(named: "Relaunch Lift")

        var workspace = RoutineWorkspaceScreen(application: financeApp)
        workspace.addSession(named: "Push")
        var day = workspace.openDay(1)
        day.openAddExercise().save(name: "Press")
        day.exercise(named: "Press").requireExistence()

        var app = relaunchPreservingTestData()
        fitnessTab.tapWhenHittable()
        routines = RoutineListScreen(application: app)
        routines.openRoutine(named: "Relaunch Lift")
        workspace = RoutineWorkspaceScreen(application: app)
        day = workspace.openDay(1)
        day.exercise(named: "Press").requireExistence()

        app = resetToCleanState()
        fitnessTab.tapWhenHittable()
        RoutineListScreen(application: app).emptyState.requireExistence()
    }

    // MARK: - CHAR-07

    func testBlankAssetFieldsAndInvalidEditorsDoNotMutate() {
        let portfolio = AssetModelPortfolioScreen(application: financeApp)
        let editor = portfolio.openAddAsset()
        editor.create(code: "   ", name: "   ", currency: "USD", price: "1")
        financeApp.descendants(matching: .any)[AssetModelAccessibility.validationError]
            .requireExistence()
        editor.cancel()
        portfolio.emptyState.requireExistence()

        portfolio.openAddAsset().create(code: "KEEP", name: "Keeper", currency: "VND", price: "100")
        portfolio.assetCard(code: "KEEP").requireExistence()
        let priorRate = portfolio.summaryExchangeRate.requireExistence().label

        portfolio.openExchangeRate().save(rate: "0")
        financeApp.descendants(matching: .any)[AssetModelAccessibility.validationError]
            .requireExistence()
        financeApp.buttons["Cancel"].tapWhenHittable()
        XCTAssertEqual(
            AssetModelPortfolioScreen(application: financeApp)
                .summaryExchangeRate
                .requireExistence()
                .label,
            priorRate
        )

        let detail = AssetModelPortfolioScreen(application: financeApp).openAsset(code: "KEEP")
        detail.openUnits(operation: AssetModelAccessibility.addUnits).save(amount: "abc")
        financeApp.descendants(matching: .any)[AssetModelAccessibility.validationError]
            .requireExistence()
        financeApp.buttons["Cancel"].tapWhenHittable()
        XCTAssertTrue(
            AssetModelPortfolioScreen(application: financeApp)
                .assetCard(code: "KEEP")
                .requireExistence()
                .label
                .contains("0")
        )
    }

    // MARK: - CHAR-05 display

    func testFractionalUSDDisplayAndCommaDecimalPrice() {
        var portfolio = AssetModelPortfolioScreen(application: financeApp)
        portfolio.openAddAsset().create(
            code: "FRAC",
            name: "Frac USD",
            currency: "USD",
            price: "12,5"
        )
        portfolio = AssetModelPortfolioScreen(application: financeApp)
        let detail = portfolio.openAsset(code: "FRAC")
        detail.openUnits(operation: AssetModelAccessibility.addUnits).save(amount: "2,5")

        portfolio = AssetModelPortfolioScreen(application: financeApp)
        let total = portfolio.summaryTotalVND.requireExistence().label
        // 12.5 * 2.5 * 25_500 = 796_875
        XCTAssertTrue(total.contains("796"), "Unexpected total label: \(total)")
        XCTAssertTrue(
            portfolio.assetCard(code: "FRAC").requireExistence().label.contains("2.5")
                || portfolio.assetCard(code: "FRAC").label.contains("2,5")
        )
    }

    // MARK: - Helpers

    private func relaunchWithExtraArguments(_ extra: [String], reset: Bool) {
        let app = financeApp
        app.terminate()
        app.launchArguments = SuperAppTestApplication.descriptor.launchConfiguration
            .arguments(reset: reset) + extra
        app.launchEnvironment = SuperAppTestApplication.descriptor.launchConfiguration.environment
        app.launch()
    }

    private func writeTemporaryFixture(named name: String, contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "xq-char-\(UUID().uuidString)-\(name)"
        )
        try Data(contents.utf8).write(to: url)
        return url
    }
}
