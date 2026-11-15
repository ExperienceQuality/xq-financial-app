import Foundation
import Observation

/// Evolved from `FitnessRouter` (ADR-2). Owns path, sheets, import chrome.
@MainActor
@Observable
final class FitnessTabCoordinator: FitnessCoordinating {
    var path: [FitnessRoute] = []
    var sheet: FitnessSheetDestination?
    var isImporting = false
    var importStatus: FitnessImportStatus?

    func handle(_ route: FitnessRoute) {
        path.append(route)
    }

    func showCreateRoutine() {
        sheet = .createRoutine
    }

    func showRoutine(_ routineID: UUID) {
        path.append(.routine(routineID))
    }

    func showTrainingDay(routineID: UUID, dayID: UUID) {
        path.append(.trainingDay(routineID: routineID, dayID: dayID))
    }

    func showSnapshotReport(routineID: UUID) {
        path.append(.snapshotReport(routineID: routineID))
    }

    func showTrainingSession(routineID: UUID, sessionID: UUID?) {
        sheet = .trainingSession(routineID: routineID, sessionID: sessionID)
    }

    func showExercise(routineID: UUID, dayID: UUID, exerciseID: UUID?) {
        sheet = .exercise(routineID: routineID, dayID: dayID, exerciseID: exerciseID)
    }

    func dismissSheet() {
        sheet = nil
    }

    func presentImportPicker() {
        isImporting = true
    }

    func presentImportStatus(_ status: FitnessImportStatus) {
        importStatus = status
    }
}
