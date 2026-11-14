import Foundation
import Observation

/// App-level coordinator: tab selection + internal route hook. No URL scheme (D4).
@MainActor
@Observable
final class AppCoordinator {
    var selectedTab: SuperAppTab = .finance
    let model: SuperAppModel
    let financeCoordinator: FinanceTabCoordinator
    let fitnessCoordinator: FitnessTabCoordinator

    init(
        model: SuperAppModel,
        financeCoordinator: FinanceTabCoordinator,
        fitnessCoordinator: FitnessTabCoordinator
    ) {
        self.model = model
        self.financeCoordinator = financeCoordinator
        self.fitnessCoordinator = fitnessCoordinator
    }

    func handle(_ route: AppRoute) {
        switch route {
        case .finance(let financeRoute):
            selectedTab = .finance
            financeCoordinator.handle(financeRoute)
        case .fitness(let fitnessRoute):
            selectedTab = .fitness
            fitnessCoordinator.handle(fitnessRoute)
        }
    }
}
