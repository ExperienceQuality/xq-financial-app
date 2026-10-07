import Foundation
import XCTest
@testable import FitnessCore

final class EditorModelTests: XCTestCase {
    func testRoutineEditorSaveCreatesRoutineAndClearsValidation() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let model = RoutineEditorModel(store: store, name: "  Push  ", notes: " notes ")
        let routineID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

        XCTAssertTrue(model.canSave)
        XCTAssertTrue(model.save(id: routineID))
        XCTAssertNil(model.validationMessage)
        XCTAssertEqual(store.snapshot.routines.map(\.id), [routineID])
        XCTAssertEqual(store.snapshot.routines.first?.name, "Push")
    }

    func testRoutineEditorSaveRejectsBlankName() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let model = RoutineEditorModel(store: store, name: "   ")

        XCTAssertFalse(model.canSave)
        model.name = "   "
        XCTAssertFalse(model.save())
        XCTAssertEqual(model.validationMessage, FitnessStoreError.routineNameRequired.errorDescription)
        XCTAssertTrue(store.snapshot.routines.isEmpty)
    }

    func testExerciseEditorHydratesExistingExercise() throws {
        let (store, routineID, dayID, exerciseID) = try seededExerciseStore()
        let model = ExerciseEditorModel(
            store: store,
            routineID: routineID,
            dayID: dayID,
            exerciseID: exerciseID
        )

        XCTAssertTrue(model.isEditing)
        XCTAssertTrue(model.canSave)
        XCTAssertEqual(model.name, "Bench Press")
        XCTAssertEqual(model.sets, 4)
        XCTAssertEqual(model.reps, 8)
        XCTAssertEqual(model.weightKg, 60)
        XCTAssertNil(model.validationMessage)
    }

    func testExerciseEditorAddSavesNewExercise() throws {
        let (store, routineID, dayID, _) = try seededExerciseStore()
        let model = ExerciseEditorModel(store: store, routineID: routineID, dayID: dayID)
        let newID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

        model.name = "Row"
        model.sets = 3
        model.reps = 10
        model.weightKg = 40

        XCTAssertFalse(model.isEditing)
        XCTAssertTrue(model.save(id: newID))
        XCTAssertNil(model.validationMessage)

        let exercises = try XCTUnwrap(
            store.snapshot.routines.first(where: { $0.id == routineID })?
                .days.first(where: { $0.id == dayID })?
                .exercises
        )
        XCTAssertEqual(exercises.map(\.id), [
            UUID(uuidString: "99999999-8888-7777-6666-555555555555")!,
            newID
        ])
        XCTAssertEqual(exercises.last?.name, "Row")
    }

    func testExerciseEditorUpdatePersistsChanges() throws {
        let (store, routineID, dayID, exerciseID) = try seededExerciseStore()
        let model = ExerciseEditorModel(
            store: store,
            routineID: routineID,
            dayID: dayID,
            exerciseID: exerciseID
        )

        model.weightKg = 70
        XCTAssertTrue(model.save())

        let exercise = try XCTUnwrap(
            store.snapshot.routines.first(where: { $0.id == routineID })?
                .days.first(where: { $0.id == dayID })?
                .exercises.first(where: { $0.id == exerciseID })
        )
        XCTAssertEqual(exercise.weightKg, 70)
    }

    func testExerciseEditorFailsClosedWhenExerciseMissing() throws {
        let (store, routineID, dayID, _) = try seededExerciseStore()
        let model = ExerciseEditorModel(
            store: store,
            routineID: routineID,
            dayID: dayID,
            exerciseID: UUID()
        )

        XCTAssertTrue(model.isEditing)
        XCTAssertFalse(model.canSave)
        XCTAssertEqual(model.validationMessage, FitnessStoreError.exerciseNotFound.errorDescription)
        XCTAssertFalse(model.save())
    }

    func testExerciseEditorFailsClosedWhenRoutineMissingOnAdd() throws {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let model = ExerciseEditorModel(
            store: store,
            routineID: UUID(),
            dayID: UUID()
        )

        XCTAssertFalse(model.isEditing)
        XCTAssertFalse(model.canSave)
        XCTAssertEqual(model.validationMessage, FitnessStoreError.routineNotFound.errorDescription)
        XCTAssertFalse(model.save())
    }

    func testExerciseEditorMapsStoreValidationOnSave() throws {
        let (store, routineID, dayID, _) = try seededExerciseStore()
        let model = ExerciseEditorModel(store: store, routineID: routineID, dayID: dayID)
        model.name = "Squat"
        model.sets = 0
        model.reps = 10
        model.weightKg = 100

        XCTAssertTrue(model.canSave)
        XCTAssertFalse(model.save())
        XCTAssertEqual(model.validationMessage, FitnessStoreError.exerciseMetricsInvalid.errorDescription)
    }

    private func seededExerciseStore() throws -> (FitnessStore, UUID, UUID, UUID) {
        let store = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let routineID = UUID(uuidString: "0F2B8215-BB22-41AE-82B8-A6C81D1D657E")!
        let dayID = UUID(uuidString: "AAAAAAAA-1111-2222-3333-BBBBBBBBBBBB")!
        try store.send(.createRoutine(id: routineID, name: "Strength", notes: ""))
        try store.send(.addTrainingSession(routineID: routineID, id: dayID, name: "Push"))
        let exerciseID = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!
        try store.send(.addExercise(
            routineID: routineID,
            dayID: dayID,
            id: exerciseID,
            name: "Bench Press",
            sets: 4,
            reps: 8,
            weightKg: 60
        ))
        return (store, routineID, dayID, exerciseID)
    }
}

