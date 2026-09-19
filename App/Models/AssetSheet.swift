import Foundation

enum AssetSheet: Identifiable {
    case addAsset
    case editPrice(UUID)
    case addBuyLot(UUID)
    case editBuyLot(assetID: UUID, transactionID: UUID)

    var id: String {
        switch self {
        case .addAsset:
            return "add-asset"
        case .editPrice(let assetID):
            return "edit-price-\(assetID.uuidString)"
        case .addBuyLot(let assetID):
            return "add-buy-lot-\(assetID.uuidString)"
        case .editBuyLot(let assetID, let transactionID):
            return "edit-buy-lot-\(assetID.uuidString)-\(transactionID.uuidString)"
        }
    }
}
