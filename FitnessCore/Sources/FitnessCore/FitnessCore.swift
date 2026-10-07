import Foundation
import Observation

public struct Routine: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var notes: String?
    public var days: [TrainingDay]
    public var snapshots: [RoutineSnapshot]

    public init(
        id: UUID,
        name: String,
        notes: String?,
        days: [TrainingDay]? = nil,
        snapshots: [RoutineSnapshot] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.days = days.map(Self.normalizedTrainingDays) ?? []
        self.snapshots = snapshots
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case notes
        case days
        case snapshots
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        self.init(
            id: id,
            name: try container.decode(String.self, forKey: .name),
            notes: try container.decodeIfPresent(String.self, forKey: .notes),
            days: try container.decodeIfPresent([TrainingDay].self, forKey: .days),
            snapshots: try container.decodeIfPresent([RoutineSnapshot].self, forKey: .snapshots) ?? []
        )
    }

    private static func normalizedTrainingDays(_ days: [TrainingDay]) -> [TrainingDay] {
        var daysByNumber: [Int: TrainingDay] = [:]
        for day in days where day.number > 0 && daysByNumber[day.number] == nil {
            daysByNumber[day.number] = day
        }

        return daysByNumber.keys.sorted().compactMap { number in
            guard var day = daysByNumber[number] else { return nil }
            if day.name == "Day \(number)" {
                day.name = TrainingDay.defaultName(for: number)
            }
            return day
        }
    }
}

public struct TrainingDay: Codable, Equatable, Identifiable, Sendable {
    public static func defaultName(for number: Int) -> String {
        "Session \(number)"
    }

    public let id: UUID
    public let number: Int
    public var name: String
    public var exercises: [Exercise]

    public init(id: UUID, number: Int, name: String, exercises: [Exercise] = []) {
        self.id = id
        self.number = number
        self.name = name
        self.exercises = exercises
    }

    static func stableID(routineID: UUID, number: Int) -> UUID {
        var bytes = routineID.uuid
        bytes.15 = bytes.15 &+ UInt8(number)
        return UUID(uuid: bytes)
    }
}

public struct Exercise: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var sets: Int
    public var reps: Int
    public var weightKg: Double

    public init(id: UUID, name: String, sets: Int, reps: Int, weightKg: Double) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
    }
}

public struct RoutineSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let exercises: [ExerciseSnapshot]

    public init(id: UUID, createdAt: Date, exercises: [ExerciseSnapshot]) {
        self.id = id
        self.createdAt = createdAt
        self.exercises = exercises
    }
}

public struct ExerciseSnapshot: Codable, Equatable, Sendable {
    public let name: String
    public let sets: Int
    public let reps: Int
    public let weightKg: Double

    public init(name: String, sets: Int, reps: Int, weightKg: Double) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
    }
}

public enum ProgressIndicator: String, Codable, Equatable, Sendable {
    case first
    case increased
    case decreased
    case maintained
}

public struct ExerciseProgress: Equatable, Identifiable, Sendable {
    public var id: String { current.name.lowercased() }

    public let current: ExerciseSnapshot
    public let reps: ProgressIndicator
    public let weight: ProgressIndicator
}

public struct SnapshotReport: Equatable, Sendable {
    public let current: RoutineSnapshot
    public let previous: RoutineSnapshot?
    public let exercises: [ExerciseProgress]
}

public struct FitnessSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var routines: [Routine]

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        routines: [Routine] = []
    ) {
        self.schemaVersion = schemaVersion
        self.routines = routines
    }

    fileprivate func migratedToCurrentSchema() throws -> FitnessSnapshot {
        guard schemaVersion <= Self.currentSchemaVersion else {
            throw JSONFitnessPersistenceError.unsupportedSchemaVersion(schemaVersion)
        }
        guard schemaVersion < Self.currentSchemaVersion else { return self }

        return FitnessSnapshot(
            schemaVersion: Self.currentSchemaVersion,
            routines: routines.map {
                Routine(
                    id: $0.id,
                    name: $0.name,
                    notes: $0.notes,
                    days: $0.days,
                    snapshots: $0.snapshots
                )
            }
        )
    }

    fileprivate mutating func mutateDay(
        routineID: UUID,
        dayID: UUID,
        mutation: (inout TrainingDay) throws -> Void
    ) throws {
        guard let routineIndex = routines.firstIndex(where: { $0.id == routineID }) else {
            throw FitnessStoreError.routineNotFound
        }
        guard let dayIndex = routines[routineIndex].days.firstIndex(where: { $0.id == dayID }) else {
            throw FitnessStoreError.trainingDayNotFound
        }
        try mutation(&routines[routineIndex].days[dayIndex])
    }

    fileprivate mutating func deleteTrainingSession(
        routineID: UUID,
        sessionID: UUID
    ) throws {
        guard let routineIndex = routines.firstIndex(where: { $0.id == routineID }) else {
            throw FitnessStoreError.routineNotFound
        }
        guard let sessionIndex = routines[routineIndex].days.firstIndex(where: { $0.id == sessionID }) else {
            throw FitnessStoreError.trainingDayNotFound
        }
        routines[routineIndex].days.remove(at: sessionIndex)
    }
}

public enum FitnessCommand: Equatable, Sendable {
    case createRoutine(id: UUID, name: String, notes: String)
    case addTrainingSession(routineID: UUID, id: UUID, name: String)
    case renameTrainingSession(routineID: UUID, sessionID: UUID, name: String)
    case addExercise(
        routineID: UUID,
        dayID: UUID,
        id: UUID,
        name: String,
        sets: Int,
        reps: Int,
        weightKg: Double
    )
    case updateExercise(
        routineID: UUID,
        dayID: UUID,
        exerciseID: UUID,
        name: String,
        sets: Int,
        reps: Int,
        weightKg: Double
    )
    case deleteExercise(routineID: UUID, dayID: UUID, exerciseID: UUID)
    case deleteTrainingSession(routineID: UUID, sessionID: UUID)
    case deleteTrainingDay(routineID: UUID, dayID: UUID)
    case createSnapshot(routineID: UUID, id: UUID, createdAt: Date)
}

public enum FitnessStoreError: Error, Equatable, LocalizedError {
    case routineNameRequired
    case routineNotFound
    case trainingDayNotFound
    case exerciseNotFound
    case trainingSessionNameRequired
    case exerciseNameRequired
    case exerciseMetricsInvalid
    case snapshotNotFound

    public var errorDescription: String? {
        switch self {
        case .routineNameRequired:
            return "Enter a routine name."
        case .routineNotFound:
            return "The routine could not be found."
        case .trainingDayNotFound:
            return "The training session could not be found."
        case .exerciseNotFound:
            return "The exercise could not be found."
        case .trainingSessionNameRequired:
            return "Enter a training session name."
        case .exerciseNameRequired:
            return "Enter an exercise name."
        case .exerciseMetricsInvalid:
            return "Sets and reps must be greater than zero, and weight cannot be negative."
        case .snapshotNotFound:
            return "Create a snapshot before viewing its comparison."
        }
    }
}

public protocol FitnessPersisting {
    func load() throws -> FitnessSnapshot?
    func save(_ snapshot: FitnessSnapshot) throws
}

@Observable
public final class FitnessStore {
    public private(set) var snapshot: FitnessSnapshot

    private let persistence: any FitnessPersisting

    public init(persistence: any FitnessPersisting) throws {
        self.persistence = persistence
        snapshot = try (persistence.load() ?? FitnessSnapshot()).migratedToCurrentSchema()
    }

    public func send(_ command: FitnessCommand) throws {
        var candidate = snapshot

        switch command {
        case let .createRoutine(id, name, notes):
            let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedName.isEmpty else {
                throw FitnessStoreError.routineNameRequired
            }

            candidate.routines.append(
                Routine(
                    id: id,
                    name: normalizedName,
                    notes: notes.nilIfBlank
                )
            )
        case let .addTrainingSession(routineID, id, name):
            guard let routineIndex = candidate.routines.firstIndex(where: { $0.id == routineID }) else {
                throw FitnessStoreError.routineNotFound
            }
            let normalizedName = try Self.trainingSessionName(name)
            let nextNumber = (candidate.routines[routineIndex].days.map(\.number).max() ?? 0) + 1
            candidate.routines[routineIndex].days.append(
                TrainingDay(id: id, number: nextNumber, name: normalizedName)
            )
        case let .renameTrainingSession(routineID, sessionID, name):
            let normalizedName = try Self.trainingSessionName(name)
            try candidate.mutateDay(routineID: routineID, dayID: sessionID) { session in
                session.name = normalizedName
            }
        case let .addExercise(routineID, dayID, id, name, sets, reps, weightKg):
            try candidate.mutateDay(routineID: routineID, dayID: dayID) { day in
                day.exercises.append(try Self.exercise(
                    id: id,
                    name: name,
                    sets: sets,
                    reps: reps,
                    weightKg: weightKg
                ))
            }
        case let .updateExercise(routineID, dayID, exerciseID, name, sets, reps, weightKg):
            try candidate.mutateDay(routineID: routineID, dayID: dayID) { day in
                guard let index = day.exercises.firstIndex(where: { $0.id == exerciseID }) else {
                    throw FitnessStoreError.exerciseNotFound
                }
                day.exercises[index] = try Self.exercise(
                    id: exerciseID,
                    name: name,
                    sets: sets,
                    reps: reps,
                    weightKg: weightKg
                )
            }
        case let .deleteExercise(routineID, dayID, exerciseID):
            try candidate.mutateDay(routineID: routineID, dayID: dayID) { day in
                guard let index = day.exercises.firstIndex(where: { $0.id == exerciseID }) else {
                    throw FitnessStoreError.exerciseNotFound
                }
                day.exercises.remove(at: index)
            }
        case let .deleteTrainingSession(routineID, sessionID):
            try candidate.deleteTrainingSession(routineID: routineID, sessionID: sessionID)
        case let .deleteTrainingDay(routineID, dayID):
            try candidate.deleteTrainingSession(routineID: routineID, sessionID: dayID)
        case let .createSnapshot(routineID, id, createdAt):
            guard let routineIndex = candidate.routines.firstIndex(where: { $0.id == routineID }) else {
                throw FitnessStoreError.routineNotFound
            }
            let capture = RoutineSnapshot(
                id: id,
                createdAt: createdAt,
                exercises: Self.aggregateExercises(in: candidate.routines[routineIndex])
            )
            candidate.routines[routineIndex].snapshots.append(capture)
            let excessCount = candidate.routines[routineIndex].snapshots.count - 2
            if excessCount > 0 {
                candidate.routines[routineIndex].snapshots.removeFirst(excessCount)
            }
        }

        try persistence.save(candidate)
        snapshot = candidate
    }

    public func importSnapshot(from data: Data) throws {
        let candidate = try FitnessSnapshotImport.decode(data)
        try persistence.save(candidate)
        snapshot = candidate
    }

    public func snapshotReport(routineID: UUID) throws -> SnapshotReport {
        guard let routine = snapshot.routines.first(where: { $0.id == routineID }) else {
            throw FitnessStoreError.routineNotFound
        }
        guard let current = routine.snapshots.last else {
            throw FitnessStoreError.snapshotNotFound
        }
        let previous = routine.snapshots.dropLast().last
        let previousByName = Dictionary(
            uniqueKeysWithValues: (previous?.exercises ?? []).map { ($0.name.normalizedKey, $0) }
        )
        let exercises = current.exercises.map { exercise in
            let prior = previousByName[exercise.name.normalizedKey]
            return ExerciseProgress(
                current: exercise,
                reps: Self.indicator(current: exercise.reps, previous: prior?.reps),
                weight: Self.indicator(current: exercise.weightKg, previous: prior?.weightKg)
            )
        }
        return SnapshotReport(current: current, previous: previous, exercises: exercises)
    }

    private static func exercise(
        id: UUID,
        name: String,
        sets: Int,
        reps: Int,
        weightKg: Double
    ) throws -> Exercise {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw FitnessStoreError.exerciseNameRequired }
        guard sets > 0, reps > 0, weightKg >= 0 else {
            throw FitnessStoreError.exerciseMetricsInvalid
        }
        return Exercise(id: id, name: normalizedName, sets: sets, reps: reps, weightKg: weightKg)
    }

    private static func trainingSessionName(_ name: String) throws -> String {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw FitnessStoreError.trainingSessionNameRequired }
        return normalizedName
    }

    private static func aggregateExercises(in routine: Routine) -> [ExerciseSnapshot] {
        var byName: [String: ExerciseSnapshot] = [:]
        for exercise in routine.days.flatMap(\.exercises) {
            let key = exercise.name.normalizedKey
            if let existing = byName[key] {
                byName[key] = ExerciseSnapshot(
                    name: existing.name,
                    sets: max(existing.sets, exercise.sets),
                    reps: max(existing.reps, exercise.reps),
                    weightKg: max(existing.weightKg, exercise.weightKg)
                )
            } else {
                byName[key] = ExerciseSnapshot(
                    name: exercise.name,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    weightKg: exercise.weightKg
                )
            }
        }
        return byName.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func indicator<T: Comparable>(current: T, previous: T?) -> ProgressIndicator {
        guard let previous else { return .first }
        if current > previous { return .increased }
        if current < previous { return .decreased }
        return .maintained
    }
}

@Observable
public final class RoutineEditorModel {
    public var name: String
    public var notes: String
    public private(set) var validationMessage: String?

    private let store: FitnessStore

    public init(store: FitnessStore, name: String = "", notes: String = "") {
        self.store = store
        self.name = name
        self.notes = notes
    }

    public var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    public func save(id: UUID = UUID()) -> Bool {
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

@Observable
public final class TrainingSessionEditorModel {
    public var name: String
    public private(set) var validationMessage: String?

    public let isEditing: Bool

    private let store: FitnessStore
    private let routineID: UUID
    private let sessionID: UUID?
    private let isUnavailable: Bool

    public init(
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

    public var canSave: Bool {
        !isUnavailable && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    public func save(id: UUID = UUID()) -> Bool {
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

@Observable
public final class ExerciseEditorModel {
    public var name: String
    public var sets: Int
    public var reps: Int
    public var weightKg: Double
    public private(set) var validationMessage: String?

    public let isEditing: Bool

    private let store: FitnessStore
    private let routineID: UUID
    private let dayID: UUID
    private let exerciseID: UUID?
    private let isUnavailable: Bool

    public init(
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

    public var canSave: Bool {
        !isUnavailable && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    public func save(id: UUID = UUID()) -> Bool {
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

public final class InMemoryFitnessPersistence: FitnessPersisting {
    public var snapshot: FitnessSnapshot?
    public private(set) var savedSnapshots: [FitnessSnapshot] = []
    public var loadError: Error?
    public var saveError: Error?

    public init(
        snapshot: FitnessSnapshot? = nil,
        loadError: Error? = nil,
        saveError: Error? = nil
    ) {
        self.snapshot = snapshot
        self.loadError = loadError
        self.saveError = saveError
    }

    public func load() throws -> FitnessSnapshot? {
        if let loadError {
            throw loadError
        }
        return snapshot
    }

    public func save(_ snapshot: FitnessSnapshot) throws {
        if let saveError {
            throw saveError
        }
        self.snapshot = snapshot
        savedSnapshots.append(snapshot)
    }
}

public enum JSONFitnessPersistenceError: Error, Equatable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case unreadableSnapshot
    case rollbackFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "This fitness data uses unsupported schema version \(version)."
        case .unreadableSnapshot:
            return "The local fitness data and its recovery copy could not be read."
        case .rollbackFailed(let message):
            return "Fitness data could not be restored after a failed save: \(message)"
        }
    }
}

public enum FitnessSnapshotImport {
    public static func decode(_ data: Data) throws -> FitnessSnapshot {
        let snapshot = try JSONDecoder().decode(FitnessSnapshot.self, from: data)
        try validateSchema(snapshot)
        return try snapshot.migratedToCurrentSchema()
    }

    fileprivate static func validateSchema(_ snapshot: FitnessSnapshot) throws {
        guard (1...FitnessSnapshot.currentSchemaVersion).contains(snapshot.schemaVersion) else {
            throw JSONFitnessPersistenceError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }
    }
}

public enum FitnessStorage {
    public static func directory(baseURL: URL, arguments: [String]) -> URL {
        let directoryName = arguments.contains("--xq-ui-testing")
            ? "XQFitnessUITests"
            : "XQFitness"
        return baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    public static func shouldReset(arguments: [String]) -> Bool {
        arguments.contains("--xq-ui-testing") &&
            arguments.contains("--xq-fitness-ui-testing-reset")
    }

    public static func resetUITestDataIfRequested(
        directory: URL,
        arguments: [String],
        fileManager: FileManager = .default
    ) throws {
        guard shouldReset(arguments: arguments) else { return }
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.removeItem(at: directory)
    }
}

public protocol FitnessFileSystem {
    func fileExists(at url: URL) -> Bool
    func createDirectory(at url: URL) throws
    func readData(at url: URL) throws -> Data
    func writeData(_ data: Data, to url: URL) throws
    func removeItem(at url: URL) throws
}

public struct LocalFitnessFileSystem: FitnessFileSystem {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    public func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
    }

    public func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    public func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}

public struct JSONFitnessPersistence: FitnessPersisting {
    public let directory: URL
    private let fileSystem: any FitnessFileSystem

    public var primaryURL: URL {
        directory.appendingPathComponent("fitness.json")
    }

    public var recoveryURL: URL {
        directory.appendingPathComponent("fitness-recovery.json")
    }

    public init(
        directory: URL,
        fileSystem: any FitnessFileSystem = LocalFitnessFileSystem()
    ) {
        self.directory = directory
        self.fileSystem = fileSystem
    }

    public func load() throws -> FitnessSnapshot? {
        let primaryExists = fileSystem.fileExists(at: primaryURL)
        let recoveryExists = fileSystem.fileExists(at: recoveryURL)

        if primaryExists {
            do {
                return try decodeSnapshot(at: primaryURL)
            } catch let error as JSONFitnessPersistenceError {
                if case .unsupportedSchemaVersion = error {
                    throw error
                }
            } catch {
                // Corrupt or unreadable primary data can fall back to recovery.
            }
        }

        if recoveryExists {
            do {
                let snapshot = try decodeSnapshot(at: recoveryURL)
                try? persistPrimary(snapshot)
                return snapshot
            } catch let error as JSONFitnessPersistenceError {
                if case .unsupportedSchemaVersion = error {
                    throw error
                }
            } catch {
                // Both local copies are unreadable; report one stable error below.
            }
        }

        if primaryExists || recoveryExists {
            throw JSONFitnessPersistenceError.unreadableSnapshot
        }

        return nil
    }

    public func save(_ snapshot: FitnessSnapshot) throws {
        try FitnessSnapshotImport.validateSchema(snapshot)
        try fileSystem.createDirectory(at: directory)

        let data = try Self.encoder.encode(snapshot)
        let previousPrimary = try backup(at: primaryURL)
        let previousRecovery = try backup(at: recoveryURL)

        do {
            try fileSystem.writeData(data, to: primaryURL)
            try fileSystem.writeData(data, to: recoveryURL)
        } catch {
            let rollbackErrors = [
                rollbackError(restoring: previousPrimary, at: primaryURL),
                rollbackError(restoring: previousRecovery, at: recoveryURL)
            ].compactMap { $0 }
            if !rollbackErrors.isEmpty {
                throw JSONFitnessPersistenceError.rollbackFailed(
                    rollbackErrors.joined(separator: "; ")
                )
            }
            throw error
        }
    }

    private func persistPrimary(_ snapshot: FitnessSnapshot) throws {
        try fileSystem.createDirectory(at: directory)
        let data = try Self.encoder.encode(snapshot)
        try fileSystem.writeData(data, to: primaryURL)
    }

    private func decodeSnapshot(at url: URL) throws -> FitnessSnapshot {
        try FitnessSnapshotImport.decode(fileSystem.readData(at: url))
    }

    private enum FileBackup {
        case absent
        case data(Data)
    }

    private func backup(at url: URL) throws -> FileBackup {
        guard fileSystem.fileExists(at: url) else { return .absent }
        return .data(try fileSystem.readData(at: url))
    }

    private func restore(_ backup: FileBackup, at url: URL) throws {
        switch backup {
        case .absent:
            if fileSystem.fileExists(at: url) {
                try fileSystem.removeItem(at: url)
            }
        case .data(let data):
            try fileSystem.writeData(data, to: url)
        }
    }

    private func rollbackError(
        restoring backup: FileBackup,
        at url: URL
    ) -> String? {
        do {
            try restore(backup, at: url)
            return nil
        } catch {
            return "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()
}

private extension String {
    var normalizedKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
