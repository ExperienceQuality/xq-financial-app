import XCTest
import XQXCUITestSupport

@MainActor
final class RoutineEditorValidationTests: FitnessUITestCase {
    func testRequiredNameValidationAndCancelLeaveRoutineListEmpty() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)
        let editor = routines.openCreateRoutine()

        editor.saveButton.requireExistence()
        XCTAssertFalse(editor.saveButton.isEnabled)

        editor.nameField.replaceText(with: "   ")
        XCTAssertFalse(editor.saveButton.isEnabled)

        editor.cancel()
        routines.emptyState.requireExistence()
    }
}

