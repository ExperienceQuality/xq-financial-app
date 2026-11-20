import FinanceCore
import XCTest
@testable import ios_xq_finance_app

@MainActor
final class FinanceViewModelTests: XCTestCase {
    func testPortfolioSnapshotTotalsMatchStoreAndExpandIsNotRoute() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let viewModel = FinancePortfolioViewModel(store: store, coordinator: coordinator)
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "ABC",
            name: "Asset",
            currency: .usd,
            price: 100
        ))
        try store.send(.addUnits(
            assetID: assetID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 2
        ))

        XCTAssertEqual(viewModel.store.snapshot.assets.count, store.snapshot.assets.count)
        XCTAssertEqual(viewModel.store.asset(id: assetID)?.totalUnits, 2)
        XCTAssertEqual(
            viewModel.store.snapshot.totalValueInVND,
            store.snapshot.totalValueInVND
        )
        XCTAssertEqual(store.snapshot.exchangeRateUSDToVND, 25_500)
        XCTAssertEqual(store.snapshot.totalValueInVND, 5_100_000)

        viewModel.toggleSelection(assetID: assetID)
        XCTAssertEqual(viewModel.selectedAssetID, assetID)
        viewModel.toggleSelection(assetID: assetID)
        XCTAssertNil(viewModel.selectedAssetID)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testDeleteNotSentUntilCoordinatorConfirmed() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let viewModel = FinancePortfolioViewModel(store: store, coordinator: coordinator)
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "DEL",
            name: "Delete Me",
            currency: .vnd,
            price: 1
        ))
        let asset = try XCTUnwrap(store.asset(id: assetID))

        viewModel.requestDelete(asset)
        XCTAssertEqual(coordinator.confirmDeleteCalls.count, 1)
        XCTAssertEqual(store.snapshot.assets.count, 1)

        viewModel.performConfirmedDelete(assetID: assetID)
        XCTAssertTrue(store.snapshot.assets.isEmpty)
        XCTAssertEqual(coordinator.dismissAlertCalls, 1)
    }

    func testAssetEditorValidatesAndCreates() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let viewModel = AssetEditorViewModel(store: store, coordinator: coordinator)

        viewModel.code = "  "
        viewModel.name = "Name"
        viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(store.snapshot.assets.isEmpty)
        XCTAssertEqual(coordinator.dismissSheetCalls, 0)

        viewModel.code = "OK"
        viewModel.name = "   "
        viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(store.snapshot.assets.isEmpty)
        XCTAssertEqual(coordinator.dismissSheetCalls, 0)

        viewModel.code = "NEG"
        viewModel.name = "Negative"
        viewModel.price = "-1"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.assetPriceInvalid.errorDescription)
        XCTAssertTrue(store.snapshot.assets.isEmpty)

        viewModel.price = "nan"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.assetPriceInvalid.errorDescription)
        XCTAssertTrue(store.snapshot.assets.isEmpty)

        viewModel.price = "inf"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.assetPriceInvalid.errorDescription)
        XCTAssertTrue(store.snapshot.assets.isEmpty)

        viewModel.code = "usd"
        viewModel.name = " Dollar "
        viewModel.price = "12,5"
        viewModel.save()
        XCTAssertEqual(store.snapshot.assets.first?.code, "USD")
        XCTAssertEqual(store.snapshot.assets.first?.name, "Dollar")
        XCTAssertEqual(store.snapshot.assets.first?.price, 12.5)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)

        let zeroVM = AssetEditorViewModel(store: store, coordinator: coordinator)
        zeroVM.code = "ZERO"
        zeroVM.name = "Zero"
        zeroVM.price = "0"
        zeroVM.save()
        let zeroAsset = try XCTUnwrap(store.snapshot.assets.first { $0.code == "ZERO" })
        XCTAssertEqual(zeroAsset.price, 0)
        XCTAssertEqual(coordinator.dismissSheetCalls, 2)
    }

    func testPriceEditorKeepsTransactionsAndRejectsInvalid() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "P",
            name: "Priced",
            currency: .usd,
            price: 10
        ))
        try store.send(.addUnits(
            assetID: assetID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 2
        ))
        let viewModel = PriceEditorViewModel(
            store: store,
            assetID: assetID,
            coordinator: coordinator
        )
        viewModel.price = "12,5"
        viewModel.save()
        XCTAssertEqual(store.asset(id: assetID)?.price, 12.5)
        XCTAssertEqual(store.asset(id: assetID)?.transactions.count, 1)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)

        viewModel.price = "-3"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.assetPriceInvalid.errorDescription)
        XCTAssertEqual(store.asset(id: assetID)?.price, 12.5)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)

        viewModel.price = "not-a-number"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.assetPriceInvalid.errorDescription)
        XCTAssertEqual(store.asset(id: assetID)?.price, 12.5)

        let missing = PriceEditorViewModel(
            store: store,
            assetID: UUID(),
            coordinator: coordinator
        )
        missing.price = "1"
        missing.save()
        XCTAssertEqual(missing.errorMessage, FinanceStoreError.assetPriceInvalid.errorDescription)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)
    }

    func testUnitEditorAddSubtractExactDrainAndRejectsInvalid() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "U",
            name: "Units",
            currency: .vnd,
            price: 100
        ))

        let addVM = UnitEditorViewModel(
            store: store,
            assetID: assetID,
            operation: .add,
            coordinator: coordinator
        )
        addVM.amount = "5"
        addVM.save()
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 5)
        XCTAssertEqual(store.asset(id: assetID)?.transactions.count, 1)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)

        let subtractVM = UnitEditorViewModel(
            store: store,
            assetID: assetID,
            operation: .subtract,
            coordinator: coordinator
        )
        subtractVM.amount = "2"
        subtractVM.save()
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 3)
        XCTAssertEqual(coordinator.dismissSheetCalls, 2)

        subtractVM.amount = "0"
        subtractVM.save()
        XCTAssertEqual(subtractVM.errorMessage, FinanceStoreError.unitsInvalid.errorDescription)
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 3)
        XCTAssertEqual(coordinator.dismissSheetCalls, 2)

        subtractVM.amount = "nan"
        subtractVM.save()
        XCTAssertEqual(subtractVM.errorMessage, FinanceStoreError.unitsInvalid.errorDescription)

        subtractVM.amount = "inf"
        subtractVM.save()
        XCTAssertEqual(subtractVM.errorMessage, FinanceStoreError.unitsInvalid.errorDescription)
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 3)

        // Drain exactly remaining units (3 → 0).
        subtractVM.amount = "3"
        subtractVM.save()
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 0)
        XCTAssertEqual(coordinator.dismissSheetCalls, 3)

        let overdraftVM = UnitEditorViewModel(
            store: store,
            assetID: assetID,
            operation: .subtract,
            coordinator: coordinator
        )
        let savesBeforeOverdraft = persistence.savedSnapshots.count
        overdraftVM.amount = "0.1"
        overdraftVM.save()
        XCTAssertNotNil(overdraftVM.errorMessage)
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 0)
        XCTAssertEqual(persistence.savedSnapshots.count, savesBeforeOverdraft)
        XCTAssertEqual(coordinator.dismissSheetCalls, 3)
    }

    func testUnitEditorRejectsOverdraftWithoutPersist() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "U",
            name: "Units",
            currency: .vnd,
            price: 100
        ))
        try store.send(.addUnits(
            assetID: assetID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 1
        ))
        let saves = persistence.savedSnapshots.count
        let viewModel = UnitEditorViewModel(
            store: store,
            assetID: assetID,
            operation: .subtract,
            coordinator: coordinator
        )
        viewModel.amount = "2"
        viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 1)
        XCTAssertEqual(persistence.savedSnapshots.count, saves)
        XCTAssertEqual(coordinator.dismissSheetCalls, 0)
    }

    func testExchangeRateEditorRejectsInvalid() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let viewModel = ExchangeRateEditorViewModel(store: store, coordinator: coordinator)
        let prior = store.snapshot.exchangeRateUSDToVND
        XCTAssertEqual(prior, 25_500)

        viewModel.rate = "0"
        viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(store.snapshot.exchangeRateUSDToVND, prior)
        XCTAssertEqual(coordinator.dismissSheetCalls, 0)

        viewModel.rate = "nan"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.exchangeRateInvalid.errorDescription)
        XCTAssertEqual(store.snapshot.exchangeRateUSDToVND, prior)

        viewModel.rate = "inf"
        viewModel.save()
        XCTAssertEqual(viewModel.errorMessage, FinanceStoreError.exchangeRateInvalid.errorDescription)
        XCTAssertEqual(store.snapshot.exchangeRateUSDToVND, prior)
    }

    func testExchangeRateDefaultAndFractionalUSDContribution() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let fracID = UUID()
        try store.send(.createAsset(
            id: fracID,
            code: "FRAC",
            name: "Fractional",
            currency: .usd,
            price: 12.5
        ))
        try store.send(.addUnits(
            assetID: fracID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 2.5
        ))

        XCTAssertEqual(store.snapshot.exchangeRateUSDToVND, 25_500)
        // 12.5 * 2.5 * 25_500 = 796_875
        XCTAssertEqual(store.snapshot.totalValueInVND, 796_875)
        XCTAssertEqual(
            store.asset(id: fracID)?.valueInVND(exchangeRateUSDToVND: 25_500),
            796_875
        )

        let viewModel = ExchangeRateEditorViewModel(store: store, coordinator: coordinator)
        XCTAssertEqual(viewModel.rate, 25_500.plainNumber)
        viewModel.rate = "26000"
        viewModel.save()
        XCTAssertEqual(store.snapshot.totalValueInVND, 12.5 * 2.5 * 26_000)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)
    }

    func testExchangeRateEditorRecalculatesUSDContributionButNotVNDAsset() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let usdID = UUID()
        let vndID = UUID()
        try store.send(.createAsset(
            id: usdID,
            code: "USD",
            name: "Dollar Asset",
            currency: .usd,
            price: 100
        ))
        try store.send(.addUnits(
            assetID: usdID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 2
        ))
        try store.send(.createAsset(
            id: vndID,
            code: "VND",
            name: "Dong Asset",
            currency: .vnd,
            price: 100_000
        ))
        try store.send(.addUnits(
            assetID: vndID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 3
        ))

        let viewModel = ExchangeRateEditorViewModel(store: store, coordinator: coordinator)
        viewModel.rate = "25000"
        viewModel.save()
        XCTAssertEqual(store.snapshot.totalValueInVND, 5_300_000)
        XCTAssertEqual(
            store.asset(id: usdID)?.valueInVND(exchangeRateUSDToVND: store.snapshot.exchangeRateUSDToVND),
            5_000_000
        )
        XCTAssertEqual(
            store.asset(id: vndID)?.valueInVND(exchangeRateUSDToVND: store.snapshot.exchangeRateUSDToVND),
            300_000
        )
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)

        viewModel.rate = "26000"
        viewModel.save()
        XCTAssertEqual(store.snapshot.totalValueInVND, 5_500_000)
        XCTAssertEqual(
            store.asset(id: usdID)?.valueInVND(exchangeRateUSDToVND: store.snapshot.exchangeRateUSDToVND),
            5_200_000
        )
        XCTAssertEqual(
            store.asset(id: vndID)?.valueInVND(exchangeRateUSDToVND: store.snapshot.exchangeRateUSDToVND),
            300_000
        )
        XCTAssertEqual(coordinator.dismissSheetCalls, 2)
    }
}

@MainActor
private final class RecordingFinanceCoordinator: FinanceCoordinating {
    var path: [FinanceRoute] = []
    var confirmDeleteCalls: [FinancialAsset] = []
    var presentErrorCalls: [String] = []
    var dismissSheetCalls = 0
    var dismissAlertCalls = 0

    func showAddAsset() {}
    func showEditPrice(assetID: UUID) {}
    func showUnits(assetID: UUID, operation: UnitOperation) {}
    func showExchangeRate() {}
    func dismissSheet() { dismissSheetCalls += 1 }
    func confirmDelete(asset: FinancialAsset) { confirmDeleteCalls.append(asset) }
    func presentError(_ message: String) { presentErrorCalls.append(message) }
    func dismissAlert() { dismissAlertCalls += 1 }
}
