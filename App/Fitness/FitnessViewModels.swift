import FitnessCore
import Foundation
import Observation

@MainActor
@Observable
final class RoutineListViewModel {
    let store: FitnessStore
    private let coordinator: any FitnessCoordinating

    init(store: FitnessStore, coordinator: any FitnessCoordinating) {
        self.store = store
        self.coordinator = coordinator
    }

    func showCreateRoutine() {
        coordinator.showCreateRoutine()
    }

    func showImportPicker() {
        coordinator.presentImportPicker()
    }
}

@MainActor
@Observable
final class RoutineWorkspaceViewModel {
    let store: FitnessStore
    private let coordinator: any FitnessCoordinating
    let routineID: UUID
    var errorMessage: String?

    var routine: Routine? {
        store.snapshot.routines.first { $0.id == routineID }
    }

    init(store: FitnessStore, coordinator: any FitnessCoordinating, routineID: UUID) {
        self.store = store
        self.coordinator = coordinator
        self.routineID = routineID
    }

    func createSnapshot() {
        do {
            try store.send(
                .createSnapshot(
                    routineID: routineID,
                    id: UUID(),
                    createdAt: Date()
                )
            )
            coordinator.showSnapshotReport(routineID: routineID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func showAddTrainingSession() {
        coordinator.showTrainingSession(routineID: routineID, sessionID: nil)
    }

    func showRenameTrainingSession(_ dayID: UUID) {
        coordinator.showTrainingSession(routineID: routineID, sessionID: dayID)
    }

    func deleteTrainingSession(_ day: TrainingDay) {
        do {
            try store.send(
                .deleteTrainingSession(
                    routineID: routineID,
                    sessionID: day.id
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class TrainingDayViewModel {
    let store: FitnessStore
    private let coordinator: any FitnessCoordinating
    let routineID: UUID
    let dayID: UUID
    var errorMessage: String?

    var day: TrainingDay? {
        store.snapshot.routines
            .first(where: { $0.id == routineID })?
            .days
            .first(where: { $0.id == dayID })
    }

    init(
        store: FitnessStore,
        coordinator: any FitnessCoordinating,
        routineID: UUID,
        dayID: UUID
    ) {
        self.store = store
        self.coordinator = coordinator
        self.routineID = routineID
        self.dayID = dayID
    }

    func showAddExercise() {
        coordinator.showExercise(routineID: routineID, dayID: dayID, exerciseID: nil)
    }

    func showEditExercise(_ exerciseID: UUID) {
        coordinator.showExercise(routineID: routineID, dayID: dayID, exerciseID: exerciseID)
    }

    func deleteExercise(_ exercise: Exercise) {
        do {
            try store.send(
                .deleteExercise(
                    routineID: routineID,
                    dayID: dayID,
                    exerciseID: exercise.id
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class SnapshotReportViewModel {
    let store: FitnessStore
    let routineID: UUID

    var report: SnapshotReport? {
        try? store.snapshotReport(routineID: routineID)
    }

    init(store: FitnessStore, routineID: UUID) {
        self.store = store
        self.routineID = routineID
    }
}

@MainActor
@Observable
final class FitnessImportViewModel {
    private let store: FitnessStore
    private let coordinator: any FitnessCoordinating

    init(store: FitnessStore, coordinator: any FitnessCoordinating) {
        self.store = store
        self.coordinator = coordinator
    }

    func handleImport(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                try store.importSnapshot(from: Data(contentsOf: url))
                coordinator.presentImportStatus(
                    FitnessImportStatus(message: "Fitness data imported.", isError: false)
                )
            } catch {
                coordinator.presentImportStatus(
                    FitnessImportStatus(
                        message: (error as? LocalizedError)?.errorDescription
                            ?? error.localizedDescription,
                        isError: true
                    )
                )
            }
        case .failure(let error):
            if let cocoaError = error as? CocoaError,
               cocoaError.code == .userCancelled {
                return
            }
            coordinator.presentImportStatus(
                FitnessImportStatus(message: error.localizedDescription, isError: true)
            )
        }
    }
}
