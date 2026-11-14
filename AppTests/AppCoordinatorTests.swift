import XCTest
@testable import ios_xq_finance_app

@MainActor
final class AppCoordinatorTests: XCTestCase {
    func testSelectedTabDefaultsToFinance() {
        let coordinator = AppDependencyContainer(
            financeLoader: { .failed("unused") },
            fitnessLoader: { .failed("unused") }
        ).makeAppCoordinator(
            model: SuperAppModel(
                financeLoader: { .failed("unused") },
                fitnessLoader: { .failed("unused") },
                loadImmediately: false
            )
        )

        XCTAssertEqual(coordinator.selectedTab, .finance)
    }

    func testHandleFinanceSelectsTabAndForwardsWithoutResettingFitnessPath() {
        let finance = FinanceTabCoordinator()
        let fitness = FitnessTabCoordinator()
        let routineID = UUID()
        fitness.path = [.routine(routineID)]

        let coordinator = AppCoordinator(
            model: SuperAppModel(
                financeLoader: { .failed("unused") },
                fitnessLoader: { .failed("unused") },
                loadImmediately: false
            ),
            financeCoordinator: finance,
            fitnessCoordinator: fitness
        )

        coordinator.handle(.finance(.portfolio))

        XCTAssertEqual(coordinator.selectedTab, .finance)
        XCTAssertEqual(finance.path, [.portfolio])
        XCTAssertEqual(fitness.path, [.routine(routineID)])
    }

    func testHandleFitnessSelectsTabAndForwardsWithoutResettingFinancePath() {
        let finance = FinanceTabCoordinator()
        let fitness = FitnessTabCoordinator()
        finance.path = [.portfolio]
        let routineID = UUID()

        let coordinator = AppCoordinator(
            model: SuperAppModel(
                financeLoader: { .failed("unused") },
                fitnessLoader: { .failed("unused") },
                loadImmediately: false
            ),
            financeCoordinator: finance,
            fitnessCoordinator: fitness
        )

        coordinator.handle(.fitness(.routine(routineID)))

        XCTAssertEqual(coordinator.selectedTab, .fitness)
        XCTAssertEqual(fitness.path, [.routine(routineID)])
        XCTAssertEqual(finance.path, [.portfolio])
    }

    func testCompositionRootHasNoURLSchemeWiring() throws {
        let appSource = try String(
            contentsOf: appSwiftURL(),
            encoding: .utf8
        )
        let coordinatorSource = try String(
            contentsOf: coordinationDirectory()
                .appendingPathComponent("AppCoordinator.swift"),
            encoding: .utf8
        )

        XCTAssertFalse(appSource.contains("onOpenURL"))
        XCTAssertFalse(appSource.contains("onContinueUserActivity"))
        XCTAssertFalse(coordinatorSource.contains("onOpenURL"))
        XCTAssertTrue(appSource.contains("AppDependencyContainer().makeAppCoordinator()"))
        XCTAssertTrue(appSource.contains("SuperAppRootView(appCoordinator:"))
        XCTAssertTrue(appSource.contains("$appCoordinator.selectedTab"))
        XCTAssertTrue(coordinatorSource.contains("func handle(_ route: AppRoute)"))
    }

    private func appSwiftURL() throws -> URL {
        let candidates = [
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("App/App.swift"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("App/App.swift")
        ]
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        XCTFail("Could not locate App/App.swift from \(#filePath)")
        throw CocoaError(.fileNoSuchFile)
    }

    private func coordinationDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("App/Coordination")
    }
}
