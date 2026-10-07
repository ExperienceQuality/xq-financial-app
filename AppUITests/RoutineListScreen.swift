import XCTest
import XQXCUITestSupport

@MainActor
struct RoutineListScreen: ScreenObject {
    let application: XCUIApplication

    var emptyState: XCUIElement {
        application.descendants(matching: .any)[FitnessAccessibility.emptyRoutineList]
    }

    func routine(named name: String) -> XCUIElement {
        application.staticTexts[name]
    }

    func notes(_ notes: String) -> XCUIElement {
        application.staticTexts[notes]
    }

    func openCreateRoutine() -> RoutineEditorScreen {
        application.buttons[FitnessAccessibility.createRoutineButton]
            .firstMatch
            .tapWhenHittable()
        return RoutineEditorScreen(application: application)
    }

    func openRoutine(named name: String) {
        routine(named: name).tapWhenHittable()
    }
}

