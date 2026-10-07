import XCTest
import XQXCUITestSupport

@MainActor
final class RoutineLifecycleTests: FitnessUITestCase {
    func testRoutineCreationNavigationAndRelaunchPersistence() {
        var app = fitnessApp
        var routines = RoutineListScreen(application: app)
        routines.emptyState.requireExistence()

        routines.openCreateRoutine().save(
            name: "Strength Reset",
            notes: "Three focused days"
        )
        routines.routine(named: "Strength Reset").requireExistence()
        routines.notes("Three focused days").requireExistence()

        routines.openRoutine(named: "Strength Reset")
        app.descendants(matching: .any)[FitnessAccessibility.routineWorkspace]
            .requireExistence()

        app = relaunchPreservingTestData()
        routines = RoutineListScreen(application: app)
        routines.routine(named: "Strength Reset").requireExistence()
        routines.notes("Three focused days").requireExistence()
    }

    func testTrainingSessionsCanBeAddedRenamedDeletedAndPersisted() {
        var app = fitnessApp
        var routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Flexible Routine")
        routines.openRoutine(named: "Flexible Routine")

        var workspace = RoutineWorkspaceScreen(application: app)
        workspace.root.requireExistence()
        XCTAssertFalse(workspace.session(1).exists)

        workspace.openAddSession().save(name: "Push Strength")
        workspace.session(named: "Push Strength").requireExistence()

        workspace.openAddSession().save(name: "Pull Strength")
        workspace.session(named: "Pull Strength").requireExistence()

        workspace.renameSession(1).save(name: "Upper Push")
        workspace.session(named: "Upper Push").requireExistence()
        XCTAssertFalse(workspace.session(named: "Push Strength").exists)

        workspace.deleteSession(2)
        XCTAssertFalse(workspace.session(named: "Pull Strength").exists)
        workspace.session(named: "Upper Push").requireExistence()

        app = relaunchPreservingTestData()
        routines = RoutineListScreen(application: app)
        routines.openRoutine(named: "Flexible Routine")
        workspace = RoutineWorkspaceScreen(application: app)

        workspace.session(named: "Upper Push").requireExistence()
        XCTAssertFalse(workspace.session(named: "Pull Strength").exists)
    }
}

