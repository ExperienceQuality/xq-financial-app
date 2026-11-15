import FinanceCore
import Foundation

enum FinanceSheetDestination: Identifiable, Equatable {
    case addAsset
    case editPrice(UUID)
    case units(UUID, UnitOperation)
    case exchangeRate

    var id: String {
        switch self {
        case .addAsset: "add-asset"
        case .editPrice(let id): "edit-price-\(id)"
        case let .units(id, operation): "units-\(id)-\(operation.rawValue)"
        case .exchangeRate: "exchange-rate"
        }
    }
}

enum FinanceAlert: Identifiable, Equatable {
    case delete(FinancialAsset)
    case error(String)

    var id: String {
        switch self {
        case .delete(let asset): "delete-\(asset.id.uuidString)"
        case .error(let message): "error-\(message)"
        }
    }
}

@MainActor
protocol FinanceCoordinating: AnyObject {
    func showAddAsset()
    func showEditPrice(assetID: UUID)
    func showUnits(assetID: UUID, operation: UnitOperation)
    func showExchangeRate()
    func dismissSheet()
    func confirmDelete(asset: FinancialAsset)
    func presentError(_ message: String)
    func dismissAlert()
}
