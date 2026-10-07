import XCTest
import XQXCUITestSupport

@MainActor
struct RoutineEditorScreen: ScreenObject {
    let application: XCUIApplication

    var nameField: XCUIElement {
        application.descendants(matching: .any)[FitnessAccessibility.routineNameField]
    }

    var notesField: XCUIElement {
        application.descendants(matching: .any)[FitnessAccessibility.routineNotesField]
    }

    var saveButton: XCUIElement {
        application.buttons[FitnessAccessibility.routineSaveButton]
    }

    func save(name: String, notes: String? = nil) {
        nameField.replaceText(with: name)
        if let notes {
            notesField.replaceText(with: notes)
        }
        saveButton.tapWhenHittable()
    }

    func cancel() {
        application.buttons["Cancel"].tapWhenHittable()
    }
}

