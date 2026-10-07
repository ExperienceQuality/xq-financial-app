import XCTest
import XQXCUITestSupport

@MainActor
final class SevenDaySnapshotTests: FitnessUITestCase {
    func testSessionExerciseDrillDownAndThreeSnapshotComparisonPersists() {
        var app = fitnessApp
        var routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Progress Plan")
        routines.openRoutine(named: "Progress Plan")

        var workspace = RoutineWorkspaceScreen(application: app)
        workspace.root.requireExistence()
        XCTAssertFalse(workspace.session(1).exists)
        workspace.addSession(named: "Push Strength")

        var day = workspace.openDay(1)
        day.openAddExercise().save(name: "Bench Press")
        day.exercise(named: "Bench Press").requireExistence()
        workspace = day.backToWorkspace()

        var report = workspace.createSnapshot()
        report.root.requireExistence()
        report.exercise(named: "Bench Press").requireExistence()
        report.progress("first").requireExistence()

        workspace = report.backToWorkspace()
        day = workspace.openDay(1)
        let editor = day.openExercise(named: "Bench Press")
        editor.update(reps: "20", weight: "10")
        workspace = day.backToWorkspace()

        report = workspace.createSnapshot()
        report.root.requireExistence()
        report.progress("increased").requireExistence()

        workspace = report.backToWorkspace()
        day = workspace.openDay(1)
        day.openExercise(named: "Bench Press").update(reps: "15", weight: "5")
        workspace = day.backToWorkspace()

        report = workspace.createSnapshot()
        report.root.requireExistence()
        report.progress("decreased").requireExistence()

        app = relaunchPreservingTestData()
        routines = RoutineListScreen(application: app)
        routines.openRoutine(named: "Progress Plan")
        workspace = RoutineWorkspaceScreen(application: app)
        workspace.root.requireExistence()
        report = workspace.openLatestComparison()
        report.progress("decreased").requireExistence()
    }

    func testExerciseCanBeDeletedFromTrainingDay() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Deletion Plan")
        routines.openRoutine(named: "Deletion Plan")

        let workspace = RoutineWorkspaceScreen(application: app)
        workspace.addSession(named: "Push Strength")
        let day = workspace.openDay(1)
        day.openAddExercise().save(name: "Temporary Press")
        day.exercise(named: "Temporary Press").requireExistence()

        day.deleteExercise(named: "Temporary Press")

        day.emptyState.requireExistence()
        XCTAssertFalse(day.exercise(named: "Temporary Press").exists)
    }

    func testExerciseEditorShowsEveryInputLabel() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)
        routines.openCreateRoutine().save(name: "Clear Inputs")
        routines.openRoutine(named: "Clear Inputs")

        let workspace = RoutineWorkspaceScreen(application: app)
        workspace.addSession(named: "Push Strength")
        let editor = workspace.openDay(1).openAddExercise()

        editor.nameLabel.requireExistence()
        editor.setsLabel.requireExistence()
        editor.repsLabel.requireExistence()
        editor.weightLabel.requireExistence()
        XCTAssertEqual(editor.nameLabel.label, "Exercise name")
        XCTAssertEqual(editor.setsLabel.label, "Sets")
        XCTAssertEqual(editor.repsLabel.label, "Repetitions")
        XCTAssertEqual(editor.weightLabel.label, "Weight (kg)")
        XCTAssertEqual(editor.nameField.label, "Exercise name")
        XCTAssertEqual(editor.setsField.label, "Sets")
        XCTAssertEqual(editor.repsField.label, "Repetitions")
        XCTAssertEqual(editor.weightField.label, "Weight (kg)")
    }
}

