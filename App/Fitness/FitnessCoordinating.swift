import Foundation

struct FitnessImportStatus: Equatable {
    let message: String
    let isError: Bool
}

@MainActor
protocol FitnessCoordinating: AnyObject {
    func showCreateRoutine()
    func showRoutine(_ routineID: UUID)
    func showTrainingDay(routineID: UUID, dayID: UUID)
    func showSnapshotReport(routineID: UUID)
    func showTrainingSession(routineID: UUID, sessionID: UUID?)
    func showExercise(routineID: UUID, dayID: UUID, exerciseID: UUID?)
    func dismissSheet()
    func presentImportPicker()
    func presentImportStatus(_ status: FitnessImportStatus)
}
