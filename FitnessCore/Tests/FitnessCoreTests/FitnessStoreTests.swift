import Foundation
import XCTest
@testable import FitnessCore

final class FitnessStoreTests: XCTestCase {
    func testFirstLaunchStartsWithAnEmptyVersionedSnapshot() throws {
        let persistence = InMemoryFitnessPersistence()

        let store = try FitnessStore(persistence: persistence)

        XCTAssertEqual(store.snapshot, FitnessSnapshot())
        XCTAssertEqual(store.snapshot.schemaVersion, FitnessSnapshot.currentSchemaVersion)
        XCTAssertTrue(store.snapshot.routines.isEmpty)
    }

    func testCreateRoutineTrimsInputAndPersistsTheCandidateSnapshot() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID(uuidString: "0F2B8215-BB22-41AE-82B8-A6C81D1D657E")!

        try store.send(.createRoutine(
            id: routineID,
            name: "  Strength Reset  ",
            notes: "  Three focused sessions.  "
        ))

        XCTAssertEqual(
            store.snapshot.routines,
            [Routine(id: routineID, name: "Strength Reset", notes: "Three focused sessions.")]
        )
        XCTAssertEqual(persistence.savedSnapshots, [store.snapshot])
    }

    func testCreateRoutineRejectsBlankNameWithoutMutatingOrPersisting() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)

        XCTAssertThrowsError(
            try store.send(.createRoutine(id: UUID(), name: " \n ", notes: "ignored"))
        ) { error in
            XCTAssertEqual(error as? FitnessStoreError, .routineNameRequired)
        }
        XCTAssertTrue(store.snapshot.routines.isEmpty)
        XCTAssertTrue(persistence.savedSnapshots.isEmpty)
    }

    func testFailedSaveDoesNotPublishPartiallyAppliedState() throws {
        let persistence = InMemoryFitnessPersistence(saveError: TestFailure.expected)
        let store = try FitnessStore(persistence: persistence)

        XCTAssertThrowsError(
            try store.send(.createRoutine(id: UUID(), name: "Upper Body", notes: ""))
        )
        XCTAssertTrue(store.snapshot.routines.isEmpty)
    }

    func testBlankRoutineNotesAreStoredAsNil() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())

        try store.send(.createRoutine(id: UUID(), name: "Cardio", notes: "  \n  "))

        XCTAssertNil(store.snapshot.routines.first?.notes)
    }

    func testCreateRoutineStartsWithNoTrainingSessions() throws {
        let routineID = UUID(uuidString: "6E91E8BB-54D7-42E4-8B11-6D55DCFC9020")!
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())

        try store.send(.createRoutine(id: routineID, name: "Open Plan", notes: ""))

        XCTAssertEqual(store.snapshot.routines.first?.days, [])
        XCTAssertEqual(Routine(id: routineID, name: "Open Plan", notes: nil).days, [])
    }

    func testRoutinePreservesProvidedTrainingSessions() throws {
        let routineID = UUID(uuidString: "F4F7541F-2928-4F0C-A4EE-4A31640E0F45")!
        let session = TrainingDay(
            id: TrainingDay.stableID(routineID: routineID, number: 2),
            number: 2,
            name: "Pull Strength"
        )

        let routine = Routine(id: routineID, name: "Flexible Plan", notes: nil, days: [session])

        XCTAssertEqual(routine.days, [session])
    }

    func testAddTrainingSessionAppendsNamedSessionWithoutSevenSessionLimit() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID(uuidString: "671C58D0-9878-4848-A47B-5299F85A7265")!
        let sessionIDs = (1...8).map { _ in UUID() }
        try store.send(.createRoutine(id: routineID, name: "Adjustable Plan", notes: ""))

        for (index, sessionID) in sessionIDs.enumerated() {
            try store.send(.addTrainingSession(
                routineID: routineID,
                id: sessionID,
                name: "Session \(index + 1)"
            ))
        }

        let sessions = try XCTUnwrap(store.snapshot.routines.first?.days)
        XCTAssertEqual(sessions.count, 8)
        XCTAssertEqual(sessions.map(\.id), sessionIDs)
        XCTAssertEqual(sessions.map(\.number), Array(1...8))
        XCTAssertEqual(sessions.last?.name, "Session 8")
        XCTAssertEqual(persistence.savedSnapshots.count, 9)
    }

    func testRenameTrainingSessionTrimsNameAndKeepsExercises() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID()
        let sessionID = UUID()
        let exerciseID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: sessionID, name: "Push"))
        try store.send(.addExercise(
            routineID: routineID,
            dayID: sessionID,
            id: exerciseID,
            name: "Bench Press",
            sets: 3,
            reps: 10,
            weightKg: 80
        ))

        try store.send(.renameTrainingSession(
            routineID: routineID,
            sessionID: sessionID,
            name: "  Push Strength  "
        ))

        let session = try XCTUnwrap(store.snapshot.routines.first?.days.first)
        XCTAssertEqual(session.name, "Push Strength")
        XCTAssertEqual(session.exercises, [
            Exercise(id: exerciseID, name: "Bench Press", sets: 3, reps: 10, weightKg: 80)
        ])
        XCTAssertEqual(persistence.savedSnapshots.count, 4)
    }

    func testBlankTrainingSessionNameDoesNotMutateOrPersistCandidate() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID()
        let sessionID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))

        XCTAssertThrowsError(
            try store.send(.addTrainingSession(routineID: routineID, id: sessionID, name: " \n "))
        ) { error in
            XCTAssertEqual(error as? FitnessStoreError, .trainingSessionNameRequired)
        }
        XCTAssertEqual(store.snapshot.routines.first?.days, [])
        XCTAssertEqual(persistence.savedSnapshots.count, 1)

        try store.send(.addTrainingSession(routineID: routineID, id: sessionID, name: "Push"))
        let savesBeforeInvalidRename = persistence.savedSnapshots.count

        XCTAssertThrowsError(
            try store.send(.renameTrainingSession(routineID: routineID, sessionID: sessionID, name: " "))
        ) { error in
            XCTAssertEqual(error as? FitnessStoreError, .trainingSessionNameRequired)
        }
        XCTAssertEqual(store.snapshot.routines.first?.days.first?.name, "Push")
        XCTAssertEqual(persistence.savedSnapshots.count, savesBeforeInvalidRename)
    }

    func testDeleteTrainingSessionRemovesTheSessionAndKeepsRemainingSessions() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID()
        let firstSessionID = UUID()
        let deletedSessionID = UUID()
        let thirdSessionID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Adjustable Plan", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: firstSessionID, name: "Push"))
        try store.send(.addTrainingSession(routineID: routineID, id: deletedSessionID, name: "Pull"))
        try store.send(.addTrainingSession(routineID: routineID, id: thirdSessionID, name: "Legs"))

        try store.send(.deleteTrainingSession(routineID: routineID, sessionID: deletedSessionID))

        let remainingSessions = try XCTUnwrap(store.snapshot.routines.first?.days)
        XCTAssertEqual(remainingSessions.map(\.id), [firstSessionID, thirdSessionID])
        XCTAssertEqual(remainingSessions.map(\.name), ["Push", "Legs"])
        XCTAssertEqual(persistence.savedSnapshots.count, 5)
    }

    func testCurrentSchemaDecodePreservesTrainingSessions() throws {
        let routineID = UUID(uuidString: "C55A057D-AB38-4F92-9FD9-8525150AF38C")!
        let routine = Routine(
            id: routineID,
            name: "Recovered Plan",
            notes: nil,
            days: [
                TrainingDay(
                    id: TrainingDay.stableID(routineID: routineID, number: 1),
                    number: 1,
                    name: "Push Strength"
                )
            ]
        )
        let data = try JSONEncoder().encode(FitnessSnapshot(routines: [routine]))

        let decoded = try JSONDecoder().decode(FitnessSnapshot.self, from: data)

        XCTAssertEqual(decoded.routines.first?.days.map(\.name), ["Push Strength"])
    }

    func testLegacySchemaMigratesToEmptySessionsAndCurrentVersion() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = JSONFitnessPersistence(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacy = LegacySnapshot(
            schemaVersion: 1,
            routines: [LegacyRoutine(id: UUID(), name: "Legacy", notes: nil)]
        )
        let data = try JSONEncoder().encode(legacy)
        try data.write(to: persistence.primaryURL)
        try data.write(to: persistence.recoveryURL)

        let store = try FitnessStore(persistence: persistence)

        XCTAssertEqual(store.snapshot.schemaVersion, FitnessSnapshot.currentSchemaVersion)
        XCTAssertEqual(store.snapshot.routines.first?.days, [])
        XCTAssertTrue(store.snapshot.routines.first?.snapshots.isEmpty == true)
    }

    func testExerciseCommandsAddUpdateAndDeleteWithinOneDay() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID()
        let sessionID = UUID()
        let exerciseID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: sessionID, name: "Push"))

        try store.send(.addExercise(
            routineID: routineID,
            dayID: sessionID,
            id: exerciseID,
            name: "  Bench Press  ",
            sets: 3,
            reps: 10,
            weightKg: 80
        ))
        XCTAssertEqual(
            store.snapshot.routines.first?.days.first?.exercises,
            [Exercise(id: exerciseID, name: "Bench Press", sets: 3, reps: 10, weightKg: 80)]
        )

        try store.send(.updateExercise(
            routineID: routineID,
            dayID: sessionID,
            exerciseID: exerciseID,
            name: "Bench Press",
            sets: 4,
            reps: 8,
            weightKg: 90
        ))
        XCTAssertEqual(store.snapshot.routines.first?.days.first?.exercises.first?.sets, 4)
        XCTAssertEqual(store.snapshot.routines.first?.days.first?.exercises.first?.weightKg, 90)

        try store.send(.deleteExercise(
            routineID: routineID,
            dayID: sessionID,
            exerciseID: exerciseID
        ))
        XCTAssertTrue(store.snapshot.routines.first?.days.first?.exercises.isEmpty == true)
        XCTAssertEqual(persistence.savedSnapshots.count, 5)
    }

    func testInvalidExerciseDoesNotMutateOrPersistCandidate() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID()
        let sessionID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: sessionID, name: "Push"))
        let savesBeforeInvalidCommand = persistence.savedSnapshots.count

        XCTAssertThrowsError(try store.send(.addExercise(
            routineID: routineID,
            dayID: sessionID,
            id: UUID(),
            name: "Bench Press",
            sets: 0,
            reps: 10,
            weightKg: 80
        ))) { error in
            XCTAssertEqual(error as? FitnessStoreError, .exerciseMetricsInvalid)
        }
        XCTAssertTrue(store.snapshot.routines.first?.days.first?.exercises.isEmpty == true)
        XCTAssertEqual(persistence.savedSnapshots.count, savesBeforeInvalidCommand)
    }

    func testSnapshotsAreImmutableAggregateDuplicateExercisesAndCompareToPrevious() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let routineID = UUID()
        let firstBenchID = UUID()
        let secondBenchID = UUID()
        let pushSessionID = UUID()
        let pullSessionID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: pushSessionID, name: "Push"))
        try store.send(.addTrainingSession(routineID: routineID, id: pullSessionID, name: "Pull"))
        let days = try XCTUnwrap(store.snapshot.routines.first?.days)

        try store.send(.addExercise(
            routineID: routineID,
            dayID: days[0].id,
            id: firstBenchID,
            name: "Bench Press",
            sets: 3,
            reps: 30,
            weightKg: 80
        ))
        try store.send(.addExercise(
            routineID: routineID,
            dayID: days[1].id,
            id: secondBenchID,
            name: "bench press",
            sets: 4,
            reps: 25,
            weightKg: 85
        ))
        try store.send(.createSnapshot(
            routineID: routineID,
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 100)
        ))

        var report = try store.snapshotReport(routineID: routineID)
        XCTAssertNil(report.previous)
        XCTAssertEqual(report.exercises.count, 1)
        XCTAssertEqual(report.exercises.first?.current.sets, 4)
        XCTAssertEqual(report.exercises.first?.current.reps, 30)
        XCTAssertEqual(report.exercises.first?.current.weightKg, 85)
        XCTAssertEqual(report.exercises.first?.reps, .first)
        XCTAssertEqual(report.exercises.first?.weight, .first)

        try store.send(.updateExercise(
            routineID: routineID,
            dayID: days[0].id,
            exerciseID: firstBenchID,
            name: "Bench Press",
            sets: 3,
            reps: 35,
            weightKg: 80
        ))
        try store.send(.createSnapshot(
            routineID: routineID,
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 200)
        ))

        report = try store.snapshotReport(routineID: routineID)
        XCTAssertEqual(report.exercises.first?.reps, .increased)
        XCTAssertEqual(report.exercises.first?.weight, .maintained)
        XCTAssertEqual(report.previous?.exercises.first?.reps, 30)
        XCTAssertEqual(store.snapshot.routines.first?.snapshots.first?.exercises.first?.reps, 30)

        try store.send(.updateExercise(
            routineID: routineID,
            dayID: days[0].id,
            exerciseID: firstBenchID,
            name: "Bench Press",
            sets: 3,
            reps: 35,
            weightKg: 70
        ))
        try store.send(.updateExercise(
            routineID: routineID,
            dayID: days[1].id,
            exerciseID: secondBenchID,
            name: "Bench Press",
            sets: 4,
            reps: 25,
            weightKg: 75
        ))
        try store.send(.createSnapshot(
            routineID: routineID,
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 300)
        ))

        report = try store.snapshotReport(routineID: routineID)
        XCTAssertEqual(report.exercises.first?.reps, .maintained)
        XCTAssertEqual(report.exercises.first?.weight, .decreased)
    }

    func testCreatingThirdSnapshotRetainsOnlyNewestTwoCaptures() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let routineID = UUID()
        let snapshotA = UUID()
        let snapshotB = UUID()
        let snapshotC = UUID()
        try store.send(.createRoutine(id: routineID, name: "Bounded History", notes: ""))

        try store.send(.createSnapshot(
            routineID: routineID,
            id: snapshotA,
            createdAt: Date(timeIntervalSince1970: 100)
        ))
        try store.send(.createSnapshot(
            routineID: routineID,
            id: snapshotB,
            createdAt: Date(timeIntervalSince1970: 200)
        ))
        try store.send(.createSnapshot(
            routineID: routineID,
            id: snapshotC,
            createdAt: Date(timeIntervalSince1970: 300)
        ))

        let retained = try XCTUnwrap(store.snapshot.routines.first?.snapshots)
        XCTAssertEqual(retained.map(\.id), [snapshotB, snapshotC])
        let report = try store.snapshotReport(routineID: routineID)
        XCTAssertEqual(report.previous?.id, snapshotB)
        XCTAssertEqual(report.current.id, snapshotC)
    }

    func testJSONPersistenceRoundTripsAndRecoversFromDamagedPrimaryFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = JSONFitnessPersistence(directory: directory)
        let routine = Routine(id: UUID(), name: "Mobility", notes: "Daily reset")
        let snapshot = FitnessSnapshot(routines: [routine])

        try persistence.save(snapshot)
        XCTAssertEqual(try persistence.load(), snapshot)

        try Data("not-json".utf8).write(to: persistence.primaryURL, options: .atomic)
        XCTAssertEqual(try persistence.load(), snapshot)
    }

    func testProductionStorageStartsEmptyAndSeparatesUITestNamespace() throws {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }
        let normalDirectory = FitnessStorage.directory(baseURL: baseURL, arguments: [])
        let uiTestDirectory = FitnessStorage.directory(
            baseURL: baseURL,
            arguments: ["--xq-ui-testing"]
        )

        let store = try FitnessStore(
            persistence: JSONFitnessPersistence(directory: normalDirectory)
        )

        XCTAssertEqual(store.snapshot, FitnessSnapshot())
        XCTAssertEqual(normalDirectory.lastPathComponent, "XQFitness")
        XCTAssertEqual(uiTestDirectory.lastPathComponent, "XQFitnessUITests")
        XCTAssertNotEqual(normalDirectory, uiTestDirectory)
    }

    func testUITestResetRequiresIsolationAndResetFlags() {
        XCTAssertFalse(FitnessStorage.shouldReset(arguments: ["app", "--xq-ui-testing-reset"]))
        XCTAssertFalse(FitnessStorage.shouldReset(arguments: ["app", "--xq-fitness-ui-testing-reset"]))
        XCTAssertFalse(FitnessStorage.shouldReset(arguments: ["app", "--xq-ui-testing"]))
        XCTAssertTrue(FitnessStorage.shouldReset(arguments: [
            "app",
            "--xq-ui-testing",
            "--xq-fitness-ui-testing-reset"
        ]))
    }

    func testUITestResetRemovesOnlyIsolatedDirectory() throws {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }
        let normalDirectory = FitnessStorage.directory(baseURL: baseURL, arguments: [])
        let uiTestDirectory = FitnessStorage.directory(
            baseURL: baseURL,
            arguments: ["--xq-ui-testing"]
        )
        try FileManager.default.createDirectory(at: normalDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: uiTestDirectory, withIntermediateDirectories: true)
        let normalMarker = normalDirectory.appendingPathComponent("normal-marker")
        let uiTestMarker = uiTestDirectory.appendingPathComponent("ui-test-marker")
        try Data().write(to: normalMarker)
        try Data().write(to: uiTestMarker)

        try FitnessStorage.resetUITestDataIfRequested(
            directory: uiTestDirectory,
            arguments: ["app", "--xq-ui-testing", "--xq-fitness-ui-testing-reset"]
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: normalMarker.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: uiTestDirectory.path))
    }

    func testRecoveryWriteFailureFailsSaveAndRollsBackPrimary() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = JSONFitnessPersistence(directory: directory)
        try FileManager.default.createDirectory(
            at: persistence.recoveryURL,
            withIntermediateDirectories: true
        )

        XCTAssertThrowsError(
            try persistence.save(FitnessSnapshot(
                routines: [Routine(id: UUID(), name: "Blocked", notes: nil)]
            ))
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: persistence.primaryURL.path))
    }

    func testSecondWriteFailureRestoresBothPreviousFiles() throws {
        let directory = URL(fileURLWithPath: "/fitness-tests", isDirectory: true)
        let primaryURL = directory.appendingPathComponent("fitness.json")
        let recoveryURL = directory.appendingPathComponent("fitness-recovery.json")
        let oldPrimary = Data("old-primary".utf8)
        let oldRecovery = Data("old-recovery".utf8)
        let fileSystem = SecondWriteFailingFileSystem(files: [
            primaryURL: oldPrimary,
            recoveryURL: oldRecovery
        ])
        let persistence = JSONFitnessPersistence(
            directory: directory,
            fileSystem: fileSystem
        )

        XCTAssertThrowsError(
            try persistence.save(FitnessSnapshot(routines: [
                Routine(id: UUID(), name: "Replacement", notes: nil)
            ]))
        ) { error in
            XCTAssertEqual(error as? TestFailure, .expected)
        }

        XCTAssertEqual(fileSystem.files[primaryURL], oldPrimary)
        XCTAssertEqual(fileSystem.files[recoveryURL], oldRecovery)
    }

    func testFuturePrimarySchemaIsNotReplacedByOlderRecovery() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = JSONFitnessPersistence(directory: directory)
        try persistence.save(FitnessSnapshot())
        let futureData = try JSONEncoder().encode(
            FitnessSnapshot(schemaVersion: FitnessSnapshot.currentSchemaVersion + 1)
        )
        try futureData.write(to: persistence.primaryURL, options: .atomic)

        XCTAssertThrowsError(try persistence.load()) { error in
            XCTAssertEqual(
                error as? JSONFitnessPersistenceError,
                .unsupportedSchemaVersion(FitnessSnapshot.currentSchemaVersion + 1)
            )
        }
        XCTAssertEqual(try Data(contentsOf: persistence.primaryURL), futureData)
    }

    func testImportMigratesSchemaOneBeforePublishingAndPersisting() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
        let data = Data(
            """
            {
              "schemaVersion": 1,
              "routines": [{
                "id": "\(routineID)",
                "name": "Legacy Strength",
                "notes": "Imported"
              }]
            }
            """.utf8
        )

        try store.importSnapshot(from: data)

        XCTAssertEqual(store.snapshot.schemaVersion, FitnessSnapshot.currentSchemaVersion)
        XCTAssertEqual(store.snapshot.routines.first?.id.uuidString, routineID)
        XCTAssertEqual(store.snapshot.routines.first?.days, [])
        XCTAssertEqual(store.snapshot.routines.first?.snapshots, [])
        XCTAssertEqual(persistence.savedSnapshots, [store.snapshot])
    }

    func testImportPreservesSchemaTwoTrainingAndSnapshotData() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        let routineID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let sessionID = UUID(uuidString: "AAAAAAAA-1111-2222-3333-BBBBBBBBBBBB")!
        let exercise = Exercise(
            id: UUID(uuidString: "99999999-8888-7777-6666-555555555555")!,
            name: "Bench Press",
            sets: 4,
            reps: 8,
            weightKg: 82.5
        )
        let snapshot = RoutineSnapshot(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            createdAt: Date(timeIntervalSince1970: 1234),
            exercises: [ExerciseSnapshot(name: "Bench Press", sets: 4, reps: 8, weightKg: 82.5)]
        )
        let imported = FitnessSnapshot(routines: [
            Routine(
                id: routineID,
                name: "Imported Plan",
                notes: "Complete schema",
                days: [TrainingDay(id: sessionID, number: 1, name: "Upper", exercises: [exercise])],
                snapshots: [snapshot]
            )
        ])

        try store.importSnapshot(from: JSONEncoder().encode(imported))

        XCTAssertEqual(store.snapshot, imported)
        XCTAssertEqual(persistence.savedSnapshots, [imported])
    }

    func testMalformedImportDoesNotMutateMemoryOrPersistence() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        try store.send(.createRoutine(id: UUID(), name: "Existing", notes: ""))
        let original = store.snapshot
        let saveCount = persistence.savedSnapshots.count

        XCTAssertThrowsError(try store.importSnapshot(from: Data("not-json".utf8)))

        XCTAssertEqual(store.snapshot, original)
        XCTAssertEqual(persistence.savedSnapshots.count, saveCount)
    }

    func testFutureSchemaImportDoesNotMutateMemoryOrPersistence() throws {
        let persistence = InMemoryFitnessPersistence()
        let store = try FitnessStore(persistence: persistence)
        try store.send(.createRoutine(id: UUID(), name: "Existing", notes: ""))
        let original = store.snapshot
        let saveCount = persistence.savedSnapshots.count
        let future = FitnessSnapshot(
            schemaVersion: FitnessSnapshot.currentSchemaVersion + 1,
            routines: [Routine(id: UUID(), name: "Future", notes: nil)]
        )

        XCTAssertThrowsError(try store.importSnapshot(from: JSONEncoder().encode(future))) { error in
            XCTAssertEqual(
                error as? JSONFitnessPersistenceError,
                .unsupportedSchemaVersion(FitnessSnapshot.currentSchemaVersion + 1)
            )
        }
        XCTAssertEqual(store.snapshot, original)
        XCTAssertEqual(persistence.savedSnapshots.count, saveCount)
    }

    func testImportPersistenceFailureDoesNotPublishCandidate() throws {
        let persistence = InMemoryFitnessPersistence(saveError: TestFailure.expected)
        let existing = FitnessSnapshot(routines: [
            Routine(id: UUID(), name: "Existing", notes: nil)
        ])
        persistence.snapshot = existing
        let store = try FitnessStore(persistence: persistence)
        let candidate = FitnessSnapshot(routines: [
            Routine(id: UUID(), name: "Candidate", notes: nil)
        ])

        XCTAssertThrowsError(
            try store.importSnapshot(from: JSONEncoder().encode(candidate))
        )
        XCTAssertEqual(store.snapshot, existing)
        XCTAssertTrue(persistence.savedSnapshots.isEmpty)
    }
}

private enum TestFailure: Error {
    case expected
}

private final class SecondWriteFailingFileSystem: FitnessFileSystem {
    var files: [URL: Data]
    private var writeCount = 0

    init(files: [URL: Data]) {
        self.files = files
    }

    func fileExists(at url: URL) -> Bool {
        files[url] != nil
    }

    func createDirectory(at url: URL) throws {}

    func readData(at url: URL) throws -> Data {
        guard let data = files[url] else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return data
    }

    func writeData(_ data: Data, to url: URL) throws {
        writeCount += 1
        if writeCount == 2 {
            throw TestFailure.expected
        }
        files[url] = data
    }

    func removeItem(at url: URL) throws {
        files[url] = nil
    }
}

private struct LegacySnapshot: Codable {
    let schemaVersion: Int
    let routines: [LegacyRoutine]
}

private struct LegacyRoutine: Codable {
    let id: UUID
    let name: String
    let notes: String?
}
