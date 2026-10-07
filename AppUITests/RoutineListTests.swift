import XCTest
import XQXCUITestSupport

@MainActor
final class RoutineListTests: FitnessUITestCase {
    func testCreatesRoutineWithoutNotesAndAddsAnotherFromToolbar() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)

        routines.openCreateRoutine().save(name: "Morning Mobility")
        routines.routine(named: "Morning Mobility").requireExistence()

        routines.openCreateRoutine().save(
            name: "Evening Strength",
            notes: "Short and focused"
        )
        routines.routine(named: "Morning Mobility").requireExistence()
        routines.routine(named: "Evening Strength").requireExistence()
        routines.notes("Short and focused").requireExistence()
    }

    func testResetClearsPreviouslyPersistedUITestRoutines() {
        var app = fitnessApp
        var routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Temporary Routine")
        routines.routine(named: "Temporary Routine").requireExistence()

        app = resetToCleanState()
        routines = RoutineListScreen(application: app)
        routines.emptyState.requireExistence()
        XCTAssertFalse(routines.routine(named: "Temporary Routine").exists)
    }
}

