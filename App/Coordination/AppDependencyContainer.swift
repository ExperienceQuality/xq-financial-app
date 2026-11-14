import FinanceCore
import FitnessCore
import Foundation

/// Composition root. Constructor injection only — no DI framework (ADR-10).
@MainActor
final class AppDependencyContainer {
    private let financeLoader: SuperAppModel.FinanceLoader
    private let fitnessLoader: SuperAppModel.FitnessLoader

    init(
        financeLoader: @escaping SuperAppModel.FinanceLoader = { FinanceBootstrap.make() },
        fitnessLoader: @escaping SuperAppModel.FitnessLoader = { FitnessBootstrap.make() }
    ) {
        self.financeLoader = financeLoader
        self.fitnessLoader = fitnessLoader
    }

    func makeFinanceState() -> FeatureBootstrapState<FinanceStore> {
        financeLoader()
    }

    func makeFitnessState() -> FeatureBootstrapState<FitnessStore> {
        fitnessLoader()
    }

    func makeSuperAppModel(loadImmediately: Bool = true) -> SuperAppModel {
        SuperAppModel(
            financeLoader: financeLoader,
            fitnessLoader: fitnessLoader,
            loadImmediately: loadImmediately
        )
    }

    func makeFinanceTabCoordinator() -> FinanceTabCoordinator {
        FinanceTabCoordinator()
    }

    func makeFitnessTabCoordinator() -> FitnessTabCoordinator {
        FitnessTabCoordinator()
    }

    func makeAppCoordinator(
        model: SuperAppModel? = nil,
        financeCoordinator: FinanceTabCoordinator? = nil,
        fitnessCoordinator: FitnessTabCoordinator? = nil
    ) -> AppCoordinator {
        AppCoordinator(
            model: model ?? makeSuperAppModel(),
            financeCoordinator: financeCoordinator ?? makeFinanceTabCoordinator(),
            fitnessCoordinator: fitnessCoordinator ?? makeFitnessTabCoordinator()
        )
    }
}
