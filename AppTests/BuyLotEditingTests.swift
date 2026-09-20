import XCTest
@testable import ios_xq_finance_app

final class BuyLotEditingTests: XCTestCase {
    func testUpdatingOneBuyLotPreservesIdentityOrderAndMarketPrice() throws {
        let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        var asset = FinanceAsset(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            symbol: "AAPL",
            name: "Apple",
            nativeCurrency: .usd,
            accent: .black,
            currentPrice: 200,
            transactions: [
                BuyTransaction(id: firstID, date: "Jan 1, 2026", units: 2, unitPrice: 100),
                BuyTransaction(id: secondID, date: "Feb 2, 2026", units: 3, unitPrice: 120)
            ]
        )

        let updated = asset.updateBuyLot(transactionID: secondID, units: 4, unitPrice: 150)

        XCTAssertTrue(updated)
        XCTAssertEqual(asset.transactions.map(\.id), [firstID, secondID])
        XCTAssertEqual(asset.transactions[1].date, "Feb 2, 2026")
        XCTAssertEqual(asset.transactions[1].units, 4)
        XCTAssertEqual(asset.transactions[1].unitPrice, 150)
        XCTAssertEqual(asset.transactions[0].units, 2)
        XCTAssertEqual(asset.transactions.count, 2)
        XCTAssertEqual(asset.currentPrice, 200)
        XCTAssertEqual(asset.unitsOwned, 6)
        XCTAssertEqual(asset.totalCost, 800)
        XCTAssertEqual(asset.currentValue, 1_200)
    }

    func testUpdatingOnlyPurchasePriceLeavesCurrentValueUnchanged() {
        var asset = makeAsset()

        let updated = asset.updateBuyLot(
            transactionID: asset.transactions[0].id,
            units: 2,
            unitPrice: 125
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(asset.totalCost, 250)
        XCTAssertEqual(asset.currentPrice, 200)
        XCTAssertEqual(asset.currentValue, 400)
    }

    func testUpdatingMissingBuyLotLeavesAssetUnchanged() {
        var asset = makeAsset()
        let originalSignature = PortfolioStore.signature(for: [asset])

        let updated = asset.updateBuyLot(
            transactionID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            units: 4,
            unitPrice: 150
        )

        XCTAssertFalse(updated)
        XCTAssertEqual(PortfolioStore.signature(for: [asset]), originalSignature)
    }

    func testUpdatingBuyLotRejectsInvalidNumbersWithoutMutation() {
        let transactionID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let invalidValues: [(units: Double, unitPrice: Double)] = [
            (0, 100),
            (-1, 100),
            (1, 0),
            (1, -100),
            (.nan, 100),
            (.infinity, 100),
            (1, .infinity),
            (Double.greatestFiniteMagnitude, 2)
        ]

        for values in invalidValues {
            var asset = makeAsset()
            let originalSignature = PortfolioStore.signature(for: [asset])

            let updated = asset.updateBuyLot(
                transactionID: transactionID,
                units: values.units,
                unitPrice: values.unitPrice
            )

            XCTAssertFalse(updated, "Expected rejection for \(values)")
            XCTAssertEqual(PortfolioStore.signature(for: [asset]), originalSignature)
        }
    }

    func testEditedBuyLotRoundTripsThroughPortfolioSnapshot() throws {
        var asset = makeAsset()
        let transactionID = try XCTUnwrap(asset.transactions.first?.id)
        XCTAssertTrue(
            asset.updateBuyLot(
                transactionID: transactionID,
                units: 0.75,
                unitPrice: 30
            )
        )

        let data = try XCTUnwrap(PortfolioStore.encode(PortfolioSnapshot(assets: [asset])))
        let restored = try XCTUnwrap(PortfolioStore.decode(data)?.financeAssets.first)
        let transaction = try XCTUnwrap(restored.transactions.first)

        XCTAssertEqual(transaction.id, transactionID)
        XCTAssertEqual(transaction.date, "Jan 1, 2026")
        XCTAssertEqual(transaction.units, 0.75)
        XCTAssertEqual(transaction.unitPrice, 30)
        XCTAssertEqual(restored.currentPrice, 200)
    }

    @MainActor
    func testViewModelUpdatesExactAssetAndLotByStableIDs() {
        let target = makeAsset()
        let untouched = FinanceAsset(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            symbol: "MSFT",
            name: "Microsoft",
            nativeCurrency: .usd,
            accent: .blue,
            currentPrice: 300,
            transactions: [
                BuyTransaction(
                    id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                    date: "Mar 3, 2026",
                    units: 5,
                    unitPrice: 250
                )
            ]
        )
        let viewModel = PortfolioViewModel(
            portfolio: PortfolioSnapshot(assets: [untouched, target])
        )
        let originalUntouched = PortfolioStore.signature(for: [untouched])

        let updated = viewModel.updateBuyLot(
            assetID: target.id,
            transactionID: target.transactions[0].id,
            units: 7,
            unitPrice: 125
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(viewModel.assets[1].transactions[0].units, 7)
        XCTAssertEqual(viewModel.assets[1].transactions[0].unitPrice, 125)
        XCTAssertEqual(PortfolioStore.signature(for: [viewModel.assets[0]]), originalUntouched)
    }

    @MainActor
    func testViewModelRejectsStaleIDsWithoutChangingPersistenceSignature() {
        let asset = makeAsset()
        let staleAssetModel = PortfolioViewModel(portfolio: PortfolioSnapshot(assets: [asset]))
        let staleAssetSignature = staleAssetModel.persistenceSignature

        let staleAssetUpdated = staleAssetModel.updateBuyLot(
            assetID: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            transactionID: asset.transactions[0].id,
            units: 3,
            unitPrice: 150
        )

        XCTAssertFalse(staleAssetUpdated)
        XCTAssertEqual(staleAssetModel.persistenceSignature, staleAssetSignature)

        let staleLotModel = PortfolioViewModel(portfolio: PortfolioSnapshot(assets: [asset]))
        let staleLotSignature = staleLotModel.persistenceSignature
        let staleLotUpdated = staleLotModel.updateBuyLot(
            assetID: asset.id,
            transactionID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            units: 3,
            unitPrice: 150
        )

        XCTAssertFalse(staleLotUpdated)
        XCTAssertEqual(staleLotModel.persistenceSignature, staleLotSignature)
    }

    @MainActor
    func testPresentingBuyLotEditorRoutesAssetAndTransactionIDs() throws {
        let asset = makeAsset()
        let transaction = try XCTUnwrap(asset.transactions.first)
        let viewModel = PortfolioViewModel(portfolio: PortfolioSnapshot(assets: [asset]))

        viewModel.presentEditBuyLot(for: asset, transaction: transaction)

        guard case .editBuyLot(let assetID, let transactionID) = viewModel.activeSheet else {
            return XCTFail("Expected edit buy lot route")
        }
        XCTAssertEqual(assetID, asset.id)
        XCTAssertEqual(transactionID, transaction.id)
    }

    private func makeAsset() -> FinanceAsset {
        FinanceAsset(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            symbol: "AAPL",
            name: "Apple",
            nativeCurrency: .usd,
            accent: .black,
            currentPrice: 200,
            transactions: [
                BuyTransaction(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    date: "Jan 1, 2026",
                    units: 2,
                    unitPrice: 100
                )
            ]
        )
    }
}
