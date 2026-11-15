import FitnessCore
import XCTest
@testable import ios_xq_finance_app

@MainActor
final class FitnessViewModelTests: XCTestCase {
    func testRoutineListSignalsCoordinatorWithoutMutatingPath() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let coordinator = RecordingFitnessCoordinator()
        let viewModel = RoutineListViewModel(store: store, coordinator: coordinator)

        viewModel.showCreateRoutine()
        viewModel.showImportPicker()

        XCTAssertEqual(coordinator.showCreateRoutineCalls, 1)
        XCTAssertEqual(coordinator.presentImportPickerCalls, 1)
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertNil(coordinator.sheet)
    }

    func testCreateSnapshotThenShowsReportInOrder() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let coordinator = RecordingFitnessCoordinator()
        let routineID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        let viewModel = RoutineWorkspaceViewModel(
            store: store,
            coordinator: coordinator,
            routineID: routineID
        )

        viewModel.createSnapshot()

        XCTAssertEqual(coordinator.showSnapshotReportCalls, [routineID])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(store.snapshot.routines.first?.snapshots.count, 1)
    }

    func testCreateSnapshotFailureDoesNotShowReport() throws {
        let persistence = InMemoryFitnessPersistence(saveError: TestFailure.expected)
        // First create must succeed — use clean store then swap? Simpler: missing routine.
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let coordinator = RecordingFitnessCoordinator()
        let viewModel = RoutineWorkspaceViewModel(
            store: store,
            coordinator: coordinator,
            routineID: UUID()
        )

        viewModel.createSnapshot()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(coordinator.showSnapshotReportCalls.isEmpty)
        _ = persistence
    }

    func testTrainingDayDeleteSendsCommand() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let coordinator = RecordingFitnessCoordinator()
        let routineID = UUID()
        let dayID = UUID()
        let exerciseID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Plan", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: dayID, name: "Push"))
        try store.send(.addExercise(
            routineID: routineID,
            dayID: dayID,
            id: exerciseID,
            name: "Press",
            sets: 3,
            reps: 8,
            weightKg: 40
        ))
        let viewModel = TrainingDayViewModel(
            store: store,
            coordinator: coordinator,
            routineID: routineID,
            dayID: dayID
        )
        let exercise = try XCTUnwrap(viewModel.day?.exercises.first)

        viewModel.deleteExercise(exercise)

        XCTAssertTrue(viewModel.day?.exercises.isEmpty == true)
        viewModel.showAddExercise()
        XCTAssertEqual(coordinator.showExerciseCalls.count, 1)
    }

    func testSnapshotReportViewModelExposesStoreReport() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let routineID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Plan", notes: ""))
        try store.send(.createSnapshot(routineID: routineID, id: UUID(), createdAt: .now))
        let viewModel = SnapshotReportViewModel(store: store, routineID: routineID)
        XCTAssertNotNil(viewModel.report)
    }

    func testImportSuccessAndFailureStatus() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let coordinator = RecordingFitnessCoordinator()
        let viewModel = FitnessImportViewModel(store: store, coordinator: coordinator)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fitness-import-\(UUID().uuidString).json")
        let data = Data(
            """
            {"schemaVersion":1,"routines":[{"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","name":"Imported","notes":null}]}
            """.utf8
        )
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        viewModel.handleImport(.success(url))
        XCTAssertEqual(coordinator.importStatuses.last?.isError, false)
        XCTAssertEqual(store.snapshot.routines.count, 1)

        let bad = FileManager.default.temporaryDirectory
            .appendingPathComponent("bad-\(UUID().uuidString).json")
        try Data("not-json".utf8).write(to: bad)
        defer { try? FileManager.default.removeItem(at: bad) }
        viewModel.handleImport(.success(bad))
        XCTAssertEqual(coordinator.importStatuses.last?.isError, true)
        XCTAssertEqual(store.snapshot.routines.count, 1)
    }
}

@MainActor
private final class RecordingFitnessCoordinator: FitnessCoordinating {
    var path: [FitnessRoute] = []
    var sheet: FitnessSheetDestination?
    var showCreateRoutineCalls = 0
    var presentImportPickerCalls = 0
    var showSnapshotReportCalls: [UUID] = []
    var showExerciseCalls: [(UUID, UUID, UUID?)] = []
    var importStatuses: [FitnessImportStatus] = []

    func showCreateRoutine() { showCreateRoutineCalls += 1 }
    func showRoutine(_ routineID: UUID) { path.append(.routine(routineID)) }
    func showTrainingDay(routineID: UUID, dayID: UUID) {
        path.append(.trainingDay(routineID: routineID, dayID: dayID))
    }
    func showSnapshotReport(routineID: UUID) { showSnapshotReportCalls.append(routineID) }
    func showTrainingSession(routineID: UUID, sessionID: UUID?) {
        sheet = .trainingSession(routineID: routineID, sessionID: sessionID)
    }
    func showExercise(routineID: UUID, dayID: UUID, exerciseID: UUID?) {
        showExerciseCalls.append((routineID, dayID, exerciseID))
    }
    func dismissSheet() { sheet = nil }
    func presentImportPicker() { presentImportPickerCalls += 1 }
    func presentImportStatus(_ status: FitnessImportStatus) { importStatuses.append(status) }
}

private enum TestFailure: Error {
    case expected
}
