import FinanceCore
import SwiftUI

struct FinanceCoordinatorView: View {
    let store: FinanceStore
    @Bindable var coordinator: FinanceTabCoordinator
    @State private var portfolioViewModel: FinancePortfolioViewModel

    init(store: FinanceStore, coordinator: FinanceTabCoordinator) {
        self.store = store
        self.coordinator = coordinator
        _portfolioViewModel = State(
            initialValue: FinancePortfolioViewModel(store: store, coordinator: coordinator)
        )
    }

    var body: some View {
        AssetModelRootView(viewModel: portfolioViewModel)
            .sheet(item: $coordinator.sheet) { destination in
                switch destination {
                case .addAsset:
                    AssetEditorView(
                        viewModel: AssetEditorViewModel(store: store, coordinator: coordinator)
                    )
                case .editPrice(let assetID):
                    PriceEditorView(
                        viewModel: PriceEditorViewModel(
                            store: store,
                            assetID: assetID,
                            coordinator: coordinator
                        )
                    )
                case let .units(assetID, operation):
                    UnitEditorView(
                        viewModel: UnitEditorViewModel(
                            store: store,
                            assetID: assetID,
                            operation: operation,
                            coordinator: coordinator
                        )
                    )
                case .exchangeRate:
                    AssetModelExchangeRateEditorView(
                        viewModel: ExchangeRateEditorViewModel(
                            store: store,
                            coordinator: coordinator
                        )
                    )
                }
            }
            .alert(item: $coordinator.activeAlert) { alert in
                switch alert {
                case .delete(let asset):
                    return Alert(
                        title: Text("Delete asset?"),
                        message: Text("This removes \(asset.code) and its unit history."),
                        primaryButton: .destructive(Text("Delete Asset")) {
                            portfolioViewModel.performConfirmedDelete(assetID: asset.id)
                        },
                        secondaryButton: .cancel(Text("Cancel")) {
                            coordinator.dismissAlert()
                        }
                    )
                case .error(let message):
                    return Alert(
                        title: Text("Could Not Save"),
                        message: Text(message),
                        dismissButton: .cancel(Text("OK")) {
                            coordinator.dismissAlert()
                        }
                    )
                }
            }
    }
}
