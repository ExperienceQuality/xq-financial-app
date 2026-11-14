import Foundation
import Observation

/// Tab-scoped navigation owner. T3 evolves `FitnessRouter` into this type in place;
/// T1 holds a parallel bag so `AppCoordinator.handle` can forward without touching views yet.
@MainActor
@Observable
final class FitnessTabCoordinator {
    var path: [FitnessRoute] = []
    var sheet: FitnessSheetDestination?

    func handle(_ route: FitnessRoute) {
        path.append(route)
    }
}
