import XCTest
@testable import ios_xq_finance_app

@MainActor
final class CharacterizationContractTests: XCTestCase {
    func testFinanceFitnessAndSuperAppAccessibilityIdentifiersAreUniqueAndStable() {
        let financeIDs = [
            FinanceAccessibility.emptyState,
            FinanceAccessibility.legacyEmptyState,
            FinanceAccessibility.addAsset,
            FinanceAccessibility.summaryTotalVND,
            FinanceAccessibility.summaryExchangeRate,
            FinanceAccessibility.editExchangeRate,
            FinanceAccessibility.assetCode,
            FinanceAccessibility.assetName,
            FinanceAccessibility.assetCurrency,
            FinanceAccessibility.assetUnits,
            FinanceAccessibility.assetPrice,
            FinanceAccessibility.assetNativeTotal,
            FinanceAccessibility.assetCard,
            FinanceAccessibility.editPrice,
            FinanceAccessibility.priceEditorField,
            FinanceAccessibility.priceEditorSave,
            FinanceAccessibility.addUnits,
            FinanceAccessibility.subtractUnits,
            FinanceAccessibility.transactionRow,
            FinanceAccessibility.deleteAsset,
            FinanceAccessibility.codeField,
            FinanceAccessibility.nameField,
            FinanceAccessibility.currencyPicker,
            FinanceAccessibility.priceField,
            FinanceAccessibility.assetSave,
            FinanceAccessibility.unitAmountField,
            FinanceAccessibility.unitSave,
            FinanceAccessibility.exchangeRateField,
            FinanceAccessibility.exchangeRateSave,
            FinanceAccessibility.validationError,
            FinanceAccessibility.persistenceError,
            FinanceAccessibility.dataUnavailable,
            FinanceAccessibility.deleteConfirm,
            FinanceAccessibility.deleteCancel
        ]

        let fitnessIDs = [
            FitnessAccessibility.emptyRoutineList,
            FitnessAccessibility.createRoutineButton,
            FitnessAccessibility.routineRow,
            FitnessAccessibility.routineNameField,
            FitnessAccessibility.routineNotesField,
            FitnessAccessibility.routineSaveButton,
            FitnessAccessibility.editorError,
            FitnessAccessibility.routineWorkspace,
            FitnessAccessibility.trainingDayRow,
            FitnessAccessibility.trainingDayScreen,
            FitnessAccessibility.addTrainingSessionButton,
            FitnessAccessibility.trainingSessionNameField,
            FitnessAccessibility.trainingSessionSaveButton,
            FitnessAccessibility.addExerciseButton,
            FitnessAccessibility.exerciseRow,
            FitnessAccessibility.exerciseNameLabel,
            FitnessAccessibility.exerciseSetsLabel,
            FitnessAccessibility.exerciseRepsLabel,
            FitnessAccessibility.exerciseWeightLabel,
            FitnessAccessibility.exerciseNameField,
            FitnessAccessibility.exerciseSetsField,
            FitnessAccessibility.exerciseRepsField,
            FitnessAccessibility.exerciseWeightField,
            FitnessAccessibility.exerciseSaveButton,
            FitnessAccessibility.snapshotButton,
            FitnessAccessibility.snapshotReport,
            FitnessAccessibility.snapshotExercise,
            FitnessAccessibility.snapshotProgress
        ]

        let superAppIDs = [
            SuperAppAccessibility.financeTab,
            SuperAppAccessibility.fitnessTab,
            SuperAppAccessibility.financeFailure,
            SuperAppAccessibility.fitnessFailure,
            SuperAppAccessibility.financeRetry,
            SuperAppAccessibility.fitnessRetry,
            SuperAppAccessibility.fitnessImportButton,
            SuperAppAccessibility.fitnessImportStatus
        ]

        let all = financeIDs + fitnessIDs + superAppIDs
        XCTAssertEqual(Set(all).count, all.count)

        XCTAssertEqual(FinanceAccessibility.assetCard, "xq.asset.card")
        XCTAssertEqual(FitnessAccessibility.trainingDayRow, "fitness.training-day.row")
        XCTAssertEqual(SuperAppAccessibility.financeTab, "super-app.tab.finance")
        XCTAssertEqual(SuperAppAccessibility.financeFailure, "super-app.finance.failure")
        XCTAssertEqual(SuperAppAccessibility.financeRetry, "super-app.finance.retry")
        XCTAssertEqual(SuperAppAccessibility.fitnessImportButton, "fitness.import.button")
        XCTAssertEqual(SuperAppAccessibility.fitnessImportStatus, "fitness.import.status")

        // Page-object mirror must not drift from production FinanceAccessibility.
        XCTAssertEqual(AssetModelAccessibilityMirror.emptyState, FinanceAccessibility.emptyState)
        XCTAssertEqual(AssetModelAccessibilityMirror.addAsset, FinanceAccessibility.addAsset)
        XCTAssertEqual(AssetModelAccessibilityMirror.assetCard, FinanceAccessibility.assetCard)
        XCTAssertEqual(AssetModelAccessibilityMirror.validationError, FinanceAccessibility.validationError)
        XCTAssertEqual(AssetModelAccessibilityMirror.deleteConfirm, FinanceAccessibility.deleteConfirm)
    }

    func testUITestHooksRequireExplicitArguments() {
        XCTAssertNil(
            FitnessImportTestHook.fixtureURL(arguments: ["--xq-fitness-import-fixture", "/tmp/x.json"])
        )
        XCTAssertEqual(
            FitnessImportTestHook.fixtureURL(
                arguments: ["--xq-ui-testing", "--xq-fitness-import-fixture", "/tmp/x.json"]
            )?.path,
            "/tmp/x.json"
        )
        XCTAssertEqual(
            FitnessImportTestHook.fixtureURL(
                arguments: ["--xq-ui-testing", "--xq-fitness-import-fixture=/tmp/y.json"]
            )?.path,
            "/tmp/y.json"
        )

        XCTAssertEqual(FinanceBootstrap.bootstrapFailArgument, "--xq-finance-bootstrap-fail")
        XCTAssertEqual(FitnessBootstrap.bootstrapFailArgument, "--xq-fitness-bootstrap-fail")
        guard case .failed = FinanceBootstrap.make(arguments: [FinanceBootstrap.bootstrapFailArgument]) else {
            return XCTFail("Expected forced finance bootstrap failure")
        }
        guard case .failed = FitnessBootstrap.make(arguments: [FitnessBootstrap.bootstrapFailArgument]) else {
            return XCTFail("Expected forced fitness bootstrap failure")
        }
    }

    func testFitnessRouterPathAndSheetAreObservable() {
        let coordinator = FitnessTabCoordinator()
        let routineID = UUID()
        let dayID = UUID()

        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertNil(coordinator.sheet)

        coordinator.path = [.routine(routineID)]
        XCTAssertEqual(coordinator.path, [.routine(routineID)])

        coordinator.path.append(.trainingDay(routineID: routineID, dayID: dayID))
        XCTAssertEqual(coordinator.path.count, 2)

        coordinator.sheet = .createRoutine
        XCTAssertEqual(coordinator.sheet, .createRoutine)

        coordinator.sheet = .exercise(routineID: routineID, dayID: dayID, exerciseID: nil)
        XCTAssertEqual(
            coordinator.sheet,
            .exercise(routineID: routineID, dayID: dayID, exerciseID: nil)
        )

        coordinator.path = []
        coordinator.sheet = nil
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertNil(coordinator.sheet)
    }
}

/// Mirrors `AppUITests/AssetModelScreens.swift` literals so CHAR-06 fails if they drift.
private enum AssetModelAccessibilityMirror {
    static let emptyState = "xq.portfolio.empty-state"
    static let addAsset = "xq.portfolio.add-asset"
    static let assetCard = "xq.asset.card"
    static let validationError = "xq.validation.error"
    static let deleteConfirm = "xq.asset.delete-confirm"
}
