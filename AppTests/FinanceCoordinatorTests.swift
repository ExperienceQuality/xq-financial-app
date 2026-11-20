import FinanceCore
import XCTest
@testable import ios_xq_finance_app

@MainActor
final class FinanceCoordinatorTests: XCTestCase {
    func testShowMethodsSetSheetAndDismissSheetClears() {
        let coordinator = FinanceTabCoordinator()
        let assetID = UUID()

        XCTAssertNil(coordinator.sheet)
        XCTAssertTrue(coordinator.path.isEmpty)

        coordinator.showAddAsset()
        XCTAssertEqual(coordinator.sheet, .addAsset)
        XCTAssertTrue(coordinator.path.isEmpty)

        coordinator.dismissSheet()
        XCTAssertNil(coordinator.sheet)

        coordinator.showEditPrice(assetID: assetID)
        XCTAssertEqual(coordinator.sheet, .editPrice(assetID))
        XCTAssertTrue(coordinator.path.isEmpty)

        coordinator.dismissSheet()
        XCTAssertNil(coordinator.sheet)

        coordinator.showUnits(assetID: assetID, operation: .add)
        XCTAssertEqual(coordinator.sheet, .units(assetID, .add))
        XCTAssertTrue(coordinator.path.isEmpty)

        coordinator.showUnits(assetID: assetID, operation: .subtract)
        XCTAssertEqual(coordinator.sheet, .units(assetID, .subtract))

        coordinator.dismissSheet()
        XCTAssertNil(coordinator.sheet)

        coordinator.showExchangeRate()
        XCTAssertEqual(coordinator.sheet, .exchangeRate)
        XCTAssertTrue(coordinator.path.isEmpty)

        coordinator.dismissSheet()
        XCTAssertNil(coordinator.sheet)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testConfirmDeleteEventuallySetsAlert() {
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
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testPresentErrorAndDismissAlert() {
        let coordinator = FinanceTabCoordinator()

        coordinator.presentError("boom")
        XCTAssertEqual(coordinator.activeAlert, .error("boom"))
        XCTAssertTrue(coordinator.path.isEmpty)

        coordinator.dismissAlert()
        XCTAssertNil(coordinator.activeAlert)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testShowMethodsDoNotInventFinanceRoute() {
        let coordinator = FinanceTabCoordinator()
        let assetID = UUID()

        coordinator.showAddAsset()
        coordinator.showEditPrice(assetID: assetID)
        coordinator.showUnits(assetID: assetID, operation: .add)
        coordinator.showExchangeRate()
        coordinator.confirmDelete(
            asset: FinancialAsset(
                id: assetID,
                code: "Y",
                name: "Y",
                currency: .usd,
                price: 0
            )
        )
        coordinator.presentError("err")
        coordinator.dismissSheet()
        coordinator.dismissAlert()

        XCTAssertTrue(coordinator.path.isEmpty)
    }
}
