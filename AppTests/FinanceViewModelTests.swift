import FinanceCore
import XCTest
@testable import ios_xq_finance_app

@MainActor
final class FinanceViewModelTests: XCTestCase {
    func testPortfolioExpandCollapseIsViewModelStateNotRoute() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let coordinator = RecordingFinanceCoordinator()
        let viewModel = FinancePortfolioViewModel(store: store, coordinator: coordinator)
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "ABC",
            name: "Asset",
            currency: .vnd,
            price: 100
        ))

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

        viewModel.code = "usd"
        viewModel.name = " Dollar "
        viewModel.price = "0"
        viewModel.save()
        XCTAssertEqual(store.snapshot.assets.first?.code, "USD")
        XCTAssertEqual(store.snapshot.assets.first?.price, 0)
        XCTAssertEqual(coordinator.dismissSheetCalls, 1)
    }

    func testPriceEditorKeepsTransactions() throws {
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
        viewModel.rate = "0"
        viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(store.snapshot.exchangeRateUSDToVND, prior)
        XCTAssertEqual(coordinator.dismissSheetCalls, 0)
    }

    func testConfirmDeleteUsesAsyncDelayOnCoordinator() {
        let coordinator = FinanceTabCoordinator()
        let asset = FinancialAsset(
            id: UUID(),
            code: "X",
            name: "X",
            currency: .vnd,
            price: 1
        )
        XCTAssertNil(coordinator.activeAlert)
        coordinator.confirmDelete(asset: asset)
        XCTAssertNil(coordinator.activeAlert)
        let expectation = expectation(description: "alert presented")
        DispatchQueue.main.async {
            XCTAssertEqual(coordinator.activeAlert, .delete(asset))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
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
