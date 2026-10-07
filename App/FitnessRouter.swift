import Foundation
import Observation

@Observable
final class FitnessRouter {
    var path: [FitnessRoute] = []
    var sheet: FitnessSheetDestination?
}

enum FitnessRoute: Hashable {
    case routine(UUID)
    case trainingDay(routineID: UUID, dayID: UUID)
    case snapshotReport(routineID: UUID)
}

enum FitnessSheetDestination: Identifiable, Equatable {
    case createRoutine
    case trainingSession(routineID: UUID, sessionID: UUID?)
    case exercise(routineID: UUID, dayID: UUID, exerciseID: UUID?)

    var id: String {
        switch self {
        case .createRoutine:
            return "create-routine"
        case let .trainingSession(routineID, sessionID):
            return "training-session-\(routineID)-\(sessionID?.uuidString ?? "new")"
        case let .exercise(routineID, dayID, exerciseID):
            return "exercise-\(routineID)-\(dayID)-\(exerciseID?.uuidString ?? "new")"
        }
    }
}


