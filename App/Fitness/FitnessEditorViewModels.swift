import FitnessCore
import Foundation
import Observation

@MainActor
@Observable
final class RoutineEditorModel {
    var name: String
    var notes: String
    private(set) var validationMessage: String?

    private let store: FitnessStore

    init(store: FitnessStore, name: String = "", notes: String = "") {
        self.store = store
        self.name = name
        self.notes = notes
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func save(id: UUID = UUID()) -> Bool {
        do {
            try store.send(.createRoutine(id: id, name: name, notes: notes))
            validationMessage = nil
            return true
        } catch {
            validationMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}

@MainActor
@Observable
final class TrainingSessionEditorModel {
    var name: String
    private(set) var validationMessage: String?

    let isEditing: Bool

    private let store: FitnessStore
    private let routineID: UUID
    private let sessionID: UUID?
    private let isUnavailable: Bool

    init(
        store: FitnessStore,
        routineID: UUID,
        sessionID: UUID? = nil
    ) {
        self.store = store
        self.routineID = routineID
        self.sessionID = sessionID
        self.isEditing = sessionID != nil

        let routine = store.snapshot.routines.first { $0.id == routineID }
        if let sessionID {
            if let session = routine?.days.first(where: { $0.id == sessionID }) {
                name = session.name
                isUnavailable = false
                validationMessage = nil
            } else {
                name = ""
                isUnavailable = true
                validationMessage = Self.message(for: routine == nil ? .routineNotFound : .trainingDayNotFound)
            }
        } else if routine == nil {
            name = ""
            isUnavailable = true
            validationMessage = Self.message(for: .routineNotFound)
        } else {
            name = ""
            isUnavailable = false
            validationMessage = nil
        }
    }

    var canSave: Bool {
        !isUnavailable && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func save(id: UUID = UUID()) -> Bool {
        guard !isUnavailable else {
            return false
        }

        do {
            if let sessionID {
                try store.send(.renameTrainingSession(
                    routineID: routineID,
                    sessionID: sessionID,
                    name: name
                ))
            } else {
                try store.send(.addTrainingSession(
                    routineID: routineID,
                    id: id,
                    name: name
                ))
            }
            validationMessage = nil
            return true
        } catch {
            validationMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    private static func message(for error: FitnessStoreError) -> String {
        error.errorDescription ?? error.localizedDescription
    }
}

@MainActor
@Observable
final class ExerciseEditorModel {
    var name: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    private(set) var validationMessage: String?

    let isEditing: Bool

    private let store: FitnessStore
    private let routineID: UUID
    private let dayID: UUID
    private let exerciseID: UUID?
    private let isUnavailable: Bool

    init(
        store: FitnessStore,
        routineID: UUID,
        dayID: UUID,
        exerciseID: UUID? = nil
    ) {
        self.store = store
        self.routineID = routineID
        self.dayID = dayID
        self.exerciseID = exerciseID
        self.isEditing = exerciseID != nil

        let routine = store.snapshot.routines.first { $0.id == routineID }
        let day = routine?.days.first { $0.id == dayID }

        if let exerciseID {
            if let exercise = day?.exercises.first(where: { $0.id == exerciseID }) {
                name = exercise.name
                sets = exercise.sets
                reps = exercise.reps
                weightKg = exercise.weightKg
                isUnavailable = false
                validationMessage = nil
            } else {
                name = ""
                sets = 3
                reps = 10
                weightKg = 0
                isUnavailable = true
                validationMessage = Self.message(for: day == nil
                    ? (routine == nil ? .routineNotFound : .trainingDayNotFound)
                    : .exerciseNotFound)
            }
        } else if routine == nil {
            name = ""
            sets = 3
            reps = 10
            weightKg = 0
            isUnavailable = true
            validationMessage = Self.message(for: .routineNotFound)
        } else if day == nil {
            name = ""
            sets = 3
            reps = 10
            weightKg = 0
            isUnavailable = true
            validationMessage = Self.message(for: .trainingDayNotFound)
        } else {
            name = ""
            sets = 3
            reps = 10
            weightKg = 0
            isUnavailable = false
            validationMessage = nil
        }
    }

    var canSave: Bool {
        !isUnavailable && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func save(id: UUID = UUID()) -> Bool {
        guard !isUnavailable else {
            return false
        }

        do {
            if let exerciseID {
                try store.send(.updateExercise(
                    routineID: routineID,
                    dayID: dayID,
                    exerciseID: exerciseID,
                    name: name,
                    sets: sets,
                    reps: reps,
                    weightKg: weightKg
                ))
            } else {
                try store.send(.addExercise(
                    routineID: routineID,
                    dayID: dayID,
                    id: id,
                    name: name,
                    sets: sets,
                    reps: reps,
                    weightKg: weightKg
                ))
            }
            validationMessage = nil
            return true
        } catch {
            validationMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    private static func message(for error: FitnessStoreError) -> String {
        error.errorDescription ?? error.localizedDescription
    }
}
