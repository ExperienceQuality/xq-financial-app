import FinanceCore
import Foundation
import Observation

@MainActor
@Observable
final class FinancePortfolioViewModel {
    let store: FinanceStore
    private let coordinator: any FinanceCoordinating

    var selectedAssetID: UUID?

    var selectedAsset: FinancialAsset? {
        guard let selectedAssetID else { return nil }
        return store.asset(id: selectedAssetID)
    }

    init(store: FinanceStore, coordinator: any FinanceCoordinating) {
        self.store = store
        self.coordinator = coordinator
    }

    func toggleSelection(assetID: UUID) {
        selectedAssetID = selectedAssetID == assetID ? nil : assetID
    }

    func showAddAsset() {
        coordinator.showAddAsset()
    }

    func showExchangeRate() {
        coordinator.showExchangeRate()
    }

    func showEditPrice(assetID: UUID) {
        coordinator.showEditPrice(assetID: assetID)
    }

    func showAddUnits(assetID: UUID) {
        coordinator.showUnits(assetID: assetID, operation: .add)
    }

    func showSubtractUnits(assetID: UUID) {
        coordinator.showUnits(assetID: assetID, operation: .subtract)
    }

    func requestDelete(_ asset: FinancialAsset) {
        coordinator.confirmDelete(asset: asset)
    }

    func performConfirmedDelete(assetID: UUID) {
        do {
            try store.send(.deleteAsset(assetID: assetID))
            if selectedAssetID == assetID {
                selectedAssetID = nil
            }
            coordinator.dismissAlert()
        } catch {
            coordinator.presentError(error.financeMessage)
        }
    }
}

extension Error {
    var financeMessage: String {
        (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }
}
