import XCTest
import XQXCUITestSupport

@MainActor
final class MultiDayExerciseTests: FitnessUITestCase {
    func testExercisesCanBeAddedAcrossMultipleTrainingSessions() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Session Spread")
        routines.openRoutine(named: "Session Spread")

        var workspace = RoutineWorkspaceScreen(application: app)
        workspace.addSession(named: "Push Strength")
        workspace.addSession(named: "Pull Strength")

        var push = workspace.openDay(1)
        push.openAddExercise().save(name: "Push Squats")
        push.exercise(named: "Push Squats").requireExistence()
        workspace = push.backToWorkspace()

        let pull = workspace.openDay(2)
        pull.openAddExercise().save(name: "Pull Rows")
        pull.exercise(named: "Pull Rows").requireExistence()
        XCTAssertFalse(pull.exercise(named: "Push Squats").exists)
        workspace = pull.backToWorkspace()

        push = workspace.openDay(1)
        push.exercise(named: "Push Squats").requireExistence()
        XCTAssertFalse(push.exercise(named: "Pull Rows").exists)
    }

    func testUpdatingSetsPersistsOnTrainingSession() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Sets Plan")
        routines.openRoutine(named: "Sets Plan")

        let workspace = RoutineWorkspaceScreen(application: app)
        workspace.addSession(named: "Pull Strength")
        let day = workspace.openDay(1)
        day.openAddExercise().save(name: "Deadlift")
        day.openExercise(named: "Deadlift").update(sets: "5")
        day.exercise(named: "Deadlift").requireExistence()
    }
}

