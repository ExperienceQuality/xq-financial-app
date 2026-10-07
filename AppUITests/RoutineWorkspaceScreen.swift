import XCTest
import XQXCUITestSupport

@MainActor
struct RoutineWorkspaceScreen: ScreenObject {
    let application: XCUIApplication

    var root: XCUIElement {
        application.descendants(matching: .any)[FitnessAccessibility.routineWorkspace]
    }

    func session(_ number: Int) -> XCUIElement {
        application.descendants(matching: .any)[
            "\(FitnessAccessibility.trainingDayRow).\(number)"
        ]
    }

    func session(named name: String) -> XCUIElement {
        application.staticTexts[name]
    }

    func day(_ number: Int) -> XCUIElement {
        session(number)
    }

    func openDay(_ number: Int) -> TrainingDayScreen {
        session(number).tapWhenHittable()
        return TrainingDayScreen(application: application)
    }

    func openAddSession() -> TrainingSessionEditorScreen {
        tapHittableButton(identifier: FitnessAccessibility.addTrainingSessionButton)
        return TrainingSessionEditorScreen(application: application)
    }

    func addSession(named name: String) {
        openAddSession().save(name: name)
    }

    func renameSession(_ number: Int) -> TrainingSessionEditorScreen {
        session(number).swipeLeft()
        application.buttons["Rename"].tapWhenHittable()
        return TrainingSessionEditorScreen(application: application)
    }

    func deleteSession(_ number: Int) {
        session(number).swipeLeft()
        application.buttons["Delete"].tapWhenHittable()
    }

    func createSnapshot() -> SnapshotReportScreen {
        application.buttons[FitnessAccessibility.snapshotButton].tapWhenHittable()
        return SnapshotReportScreen(application: application)
    }

    func openLatestComparison() -> SnapshotReportScreen {
        application.staticTexts["Latest Comparison"].tapWhenHittable()
        return SnapshotReportScreen(application: application)
    }

    private func tapHittableButton(identifier: String) {
        let buttons = application.buttons.matching(identifier: identifier)
        for index in 0..<buttons.count {
            let button = buttons.element(boundBy: index)
            if button.waitForExistence(timeout: 2), button.isHittable {
                button.tap()
                return
            }
        }
        XCTFail("No hittable button found for \(identifier)")
    }
}

@MainActor
struct TrainingSessionEditorScreen: ScreenObject {
    let application: XCUIApplication

    var nameField: XCUIElement {
        application.textFields[FitnessAccessibility.trainingSessionNameField]
    }

    var saveButton: XCUIElement {
        application.buttons[FitnessAccessibility.trainingSessionSaveButton]
    }

    func save(name: String? = nil) {
        if let name {
            nameField.replaceText(with: name)
        }
        saveButton.tapWhenHittable()
    }
}

@MainActor
struct TrainingDayScreen: ScreenObject {
    let application: XCUIApplication

    var emptyState: XCUIElement {
        application.staticTexts["No Exercises"]
    }

    func exercise(named name: String) -> XCUIElement {
        application.staticTexts[name]
    }

    func openAddExercise() -> ExerciseEditorScreen {
        application.buttons[FitnessAccessibility.addExerciseButton]
            .firstMatch
            .tapWhenHittable()
        return ExerciseEditorScreen(application: application)
    }

    func openExercise(named name: String) -> ExerciseEditorScreen {
        exercise(named: name).tapWhenHittable()
        return ExerciseEditorScreen(application: application)
    }

    func deleteExercise(named name: String) {
        exercise(named: name).swipeLeft()
        application.buttons["Delete"].tapWhenHittable()
    }

    func backToWorkspace() -> RoutineWorkspaceScreen {
        application.navigationBars.buttons.element(boundBy: 0).tapWhenHittable()
        return RoutineWorkspaceScreen(application: application)
    }
}

@MainActor
struct ExerciseEditorScreen: ScreenObject {
    let application: XCUIApplication

    var nameLabel: XCUIElement {
        application.staticTexts[FitnessAccessibility.exerciseNameLabel]
    }

    var setsLabel: XCUIElement {
        application.staticTexts[FitnessAccessibility.exerciseSetsLabel]
    }

    var repsLabel: XCUIElement {
        application.staticTexts[FitnessAccessibility.exerciseRepsLabel]
    }

    var weightLabel: XCUIElement {
        application.staticTexts[FitnessAccessibility.exerciseWeightLabel]
    }

    var nameField: XCUIElement {
        application.textFields[FitnessAccessibility.exerciseNameField]
    }

    var setsField: XCUIElement {
        application.textFields[FitnessAccessibility.exerciseSetsField]
    }

    var repsField: XCUIElement {
        application.textFields[FitnessAccessibility.exerciseRepsField]
    }

    var weightField: XCUIElement {
        application.textFields[FitnessAccessibility.exerciseWeightField]
    }

    var saveButton: XCUIElement {
        application.buttons[FitnessAccessibility.exerciseSaveButton]
    }

    func save(name: String? = nil) {
        if let name {
            nameField.replaceText(with: name)
        }
        saveButton.tapWhenHittable()
    }

    func update(reps: String? = nil, weight: String? = nil, sets: String? = nil) {
        if let sets {
            setsField.replaceText(with: sets)
        }
        if let reps {
            repsField.replaceText(with: reps)
        }
        if let weight {
            weightField.replaceText(with: weight)
        }
        save()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}

@MainActor
struct SnapshotReportScreen: ScreenObject {
    let application: XCUIApplication

    var root: XCUIElement {
        application.descendants(matching: .any)[FitnessAccessibility.snapshotReport]
    }

    func exercise(named name: String) -> XCUIElement {
        application.staticTexts[name]
    }

    func progress(_ indicator: String) -> XCUIElement {
        let title = switch indicator {
        case "first": "First snapshot"
        case "increased": "Increased"
        case "decreased": "Decreased"
        case "maintained": "Same"
        default: indicator
        }
        return application.staticTexts[title].firstMatch
    }

    func backToWorkspace() -> RoutineWorkspaceScreen {
        application.navigationBars.buttons.element(boundBy: 0).tapWhenHittable()
        return RoutineWorkspaceScreen(application: application)
    }
}

