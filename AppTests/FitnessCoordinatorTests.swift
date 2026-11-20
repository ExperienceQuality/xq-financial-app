import FitnessCore
import XCTest
@testable import ios_xq_finance_app

@MainActor
final class FitnessCoordinatorTests: XCTestCase {
    func testShowRoutineTrainingDayAndSnapshotReportAppendPath() {
        let coordinator = FitnessTabCoordinator()
        let routineID = UUID()
        let dayID = UUID()

        coordinator.showRoutine(routineID)
        coordinator.showTrainingDay(routineID: routineID, dayID: dayID)
        coordinator.showSnapshotReport(routineID: routineID)

        XCTAssertEqual(
            coordinator.path,
            [
                .routine(routineID),
                .trainingDay(routineID: routineID, dayID: dayID),
                .snapshotReport(routineID: routineID)
            ]
        )
        XCTAssertNil(coordinator.sheet)
        XCTAssertFalse(coordinator.isImporting)
    }

    func testSheetsImporterAndDismissSheet() {
        let coordinator = FitnessTabCoordinator()
        let routineID = UUID()
        let dayID = UUID()
        let exerciseID = UUID()
        let sessionID = UUID()

        coordinator.showCreateRoutine()
        XCTAssertEqual(coordinator.sheet, .createRoutine)

        coordinator.dismissSheet()
        XCTAssertNil(coordinator.sheet)

        coordinator.showTrainingSession(routineID: routineID, sessionID: nil)
        XCTAssertEqual(
            coordinator.sheet,
            .trainingSession(routineID: routineID, sessionID: nil)
        )

        coordinator.showTrainingSession(routineID: routineID, sessionID: sessionID)
        XCTAssertEqual(
            coordinator.sheet,
            .trainingSession(routineID: routineID, sessionID: sessionID)
        )

        coordinator.showExercise(routineID: routineID, dayID: dayID, exerciseID: nil)
        XCTAssertEqual(
            coordinator.sheet,
            .exercise(routineID: routineID, dayID: dayID, exerciseID: nil)
        )

        coordinator.showExercise(routineID: routineID, dayID: dayID, exerciseID: exerciseID)
        XCTAssertEqual(
            coordinator.sheet,
            .exercise(routineID: routineID, dayID: dayID, exerciseID: exerciseID)
        )

        coordinator.dismissSheet()
        XCTAssertNil(coordinator.sheet)

        coordinator.presentImportPicker()
        XCTAssertTrue(coordinator.isImporting)

        let status = FitnessImportStatus(message: "ok", isError: false)
        coordinator.presentImportStatus(status)
        XCTAssertEqual(coordinator.importStatus, status)

        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testSnapThenPushLeavesSnapshotReportOnPath() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let coordinator = FitnessTabCoordinator()
        let routineID = UUID()
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        coordinator.showRoutine(routineID)

        let viewModel = RoutineWorkspaceViewModel(
            store: store,
            coordinator: coordinator,
            routineID: routineID
        )
        viewModel.createSnapshot()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(store.snapshot.routines.first?.snapshots.count, 1)
        XCTAssertEqual(
            coordinator.path,
            [
                .routine(routineID),
                .snapshotReport(routineID: routineID)
            ]
        )
        XCTAssertNil(coordinator.sheet)
    }

    func testHandleAppendsRouteWithoutChangingSheet() {
        let coordinator = FitnessTabCoordinator()
        let routineID = UUID()
        coordinator.sheet = .createRoutine

        coordinator.handle(.routine(routineID))

        XCTAssertEqual(coordinator.path, [.routine(routineID)])
        XCTAssertEqual(coordinator.sheet, .createRoutine)
    }
}
