import Foundation

struct BuyTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let date: String
    let units: Double
    let unitPrice: Double

    var totalCost: Double {
        units * unitPrice
    }

    var shortDate: String {
        date
            .replacingOccurrences(of: ", 2024", with: "")
            .replacingOccurrences(of: ", 2023", with: "")
    }
}
