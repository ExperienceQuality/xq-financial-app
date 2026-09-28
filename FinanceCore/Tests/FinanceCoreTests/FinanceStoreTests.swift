import Foundation
import XCTest
@testable import FinanceCore

final class FinanceStoreTests: XCTestCase {
    func testCreateAssetsAndCalculatePortfolioInVND() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let usdID = UUID()
        let vndID = UUID()

        try store.send(.updateExchangeRate(25_000))
        try store.send(.createAsset(
            id: usdID,
            code: " usd ",
            name: " Dollar Asset ",
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

        XCTAssertEqual(store.asset(id: usdID)?.code, "USD")
        XCTAssertEqual(store.asset(id: usdID)?.name, "Dollar Asset")
        XCTAssertEqual(store.snapshot.totalValueInVND, 5_300_000)
    }

    func testSignedTransactionsDeriveUnitsAndRejectOverdraft() throws {
        let persistence = InMemoryFinancePersistence()
        let store = try FinanceStore(persistence: persistence)
        let assetID = UUID()
        try store.send(.createAsset(
            id: assetID,
            code: "UNIT",
            name: "Unit Asset",
            currency: .vnd,
            price: 100
        ))
        try store.send(.addUnits(
            assetID: assetID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 5
        ))
        try store.send(.subtractUnits(
            assetID: assetID,
            transactionID: UUID(),
            occurredAt: .now,
            units: 2
        ))

        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 3)
        XCTAssertEqual(store.asset(id: assetID)?.transactions.map(\.units), [-2, 5])
        let savesBeforeRejection = persistence.savedSnapshots.count

        XCTAssertThrowsError(
            try store.send(.subtractUnits(
                assetID: assetID,
                transactionID: UUID(),
                occurredAt: .now,
                units: 4
            ))
        ) { error in
            XCTAssertEqual(error as? FinanceStoreError, .insufficientUnits)
        }
        XCTAssertEqual(store.asset(id: assetID)?.totalUnits, 3)
        XCTAssertEqual(persistence.savedSnapshots.count, savesBeforeRejection)
    }

    func testFailedPersistenceDoesNotPublishCandidate() throws {
        let persistence = InMemoryFinancePersistence(saveError: TestFailure.expected)
        let store = try FinanceStore(persistence: persistence)

        XCTAssertThrowsError(
            try store.send(.createAsset(
                id: UUID(),
                code: "FAIL",
                name: "Failure",
                currency: .usd,
                price: 1
            ))
        )
        XCTAssertTrue(store.snapshot.assets.isEmpty)
    }

    func testValidationRejectsNonFiniteAndNonPositiveInputs() throws {
        let store = try FinanceStore(persistence: InMemoryFinancePersistence())
        let assetID = UUID()

        XCTAssertThrowsError(
            try store.send(.createAsset(
                id: assetID,
                code: "A",
                name: "Asset",
                currency: .usd,
                price: .infinity
            ))
        )
        XCTAssertThrowsError(try store.send(.updateExchangeRate(0)))
        XCTAssertThrowsError(try store.send(.updateExchangeRate(.nan)))
    }
}

private enum TestFailure: Error {
    case expected
}
