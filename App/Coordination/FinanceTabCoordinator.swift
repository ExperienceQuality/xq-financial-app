import FinanceCore
import Foundation
import Observation

/// Owns Finance sheets/alerts. Path stays unused — live finance is sheet-only (no push routes).
@MainActor
@Observable
final class FinanceTabCoordinator: FinanceCoordinating {
    var path: [FinanceRoute] = []
    var sheet: FinanceSheetDestination?
    var activeAlert: FinanceAlert?

    func handle(_ route: FinanceRoute) {
        path.append(route)
    }

    func showAddAsset() {
        sheet = .addAsset
    }

    func showEditPrice(assetID: UUID) {
        sheet = .editPrice(assetID)
    }

    func showUnits(assetID: UUID, operation: UnitOperation) {
        sheet = .units(assetID, operation)
    }

    func showExchangeRate() {
        sheet = .exchangeRate
    }

    func dismissSheet() {
        sheet = nil
    }

    func confirmDelete(asset: FinancialAsset) {
        // Present after the initiating touch completes. Avoids physical-device
        // touch-up dismissing the newly presented alert.
        DispatchQueue.main.async { [weak self] in
            self?.activeAlert = .delete(asset)
        }
    }

    func presentError(_ message: String) {
        activeAlert = .error(message)
    }

    func dismissAlert() {
        activeAlert = nil
    }
}
