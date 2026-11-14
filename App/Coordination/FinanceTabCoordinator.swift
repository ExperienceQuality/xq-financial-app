import Foundation
import Observation

/// Owns Finance navigation chrome. Sheets/alerts land in T2; path stays empty for now.
@MainActor
@Observable
final class FinanceTabCoordinator {
    var path: [FinanceRoute] = []

    func handle(_ route: FinanceRoute) {
        path.append(route)
    }
}
