import Foundation

struct TransactionSelection: Identifiable {
    let assetID: UUID
    let transaction: BuyTransaction

    var id: UUID {
        transaction.id
    }
}
