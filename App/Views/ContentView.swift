import SwiftUI

struct ContentView: View {
    @State private var viewModel: PortfolioViewModel

    init(summary: FinanceAppSummary, portfolio: PortfolioSnapshot? = nil) {
        _viewModel = State(
            initialValue: PortfolioViewModel(summary: summary, portfolio: portfolio)
        )
    }

    init(viewModel: PortfolioViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                XQPalette.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    HeaderView(
                        title: viewModel.summary.title,
                        position: viewModel.deckPositionLabel,
                        count: viewModel.assets.count,
                        onAddAsset: { viewModel.presentAddAsset() }
                    )

                    CurrencyToggleView(displayCurrency: $viewModel.displayCurrency)

                    PortfolioSummaryView(
                        totalValue: viewModel.portfolioTotalValue,
                        displayCurrency: viewModel.displayCurrency,
                        exchangeRateUSDToVND: viewModel.exchangeRateUSDToVND
                    )

                    ExchangeRateEditorView(
                        exchangeRateUSDToVND: $viewModel.exchangeRateUSDToVND
                    )

                    AssetDeckView(
                        assets: viewModel.assets,
                        activeIndex: viewModel.activeIndex,
                        dragOffset: viewModel.dragOffset,
                        displayCurrency: viewModel.displayCurrency,
                        exchangeRateUSDToVND: viewModel.exchangeRateUSDToVND,
                        onAddAsset: { viewModel.presentAddAsset() },
                        onEditPrice: { viewModel.presentEditPrice(for: $0) },
                        onAddBuyLot: { viewModel.presentAddBuyLot(for: $0) },
                        onSelectTransaction: { asset, transaction in
                            viewModel.requestDeduction(asset: asset, transaction: transaction)
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { viewModel.handleDragChanged($0.translation) }
                            .onEnded { value in
                                viewModel.handleDragEnd(value.translation)
                            }
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 54)
                .padding(.bottom, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: viewModel.persistenceSignature) { _, _ in
            viewModel.persist()
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .addAsset:
                AddAssetSheet { symbol, name, nativeCurrency, startingPrice in
                    viewModel.addAsset(
                        symbol: symbol,
                        name: name,
                        nativeCurrency: nativeCurrency,
                        startingPrice: startingPrice
                    )
                }
                .presentationDetents([.medium])

            case .editPrice(let assetID):
                if let index = viewModel.assetIndex(for: assetID) {
                    PriceEditorSheet(asset: $viewModel.assets[index])
                        .presentationDetents([.medium])
                } else {
                    Text("Asset unavailable")
                        .presentationDetents([.medium])
                }

            case .addBuyLot(let assetID):
                if let index = viewModel.assetIndex(for: assetID) {
                    BuyLotEditorSheet(asset: $viewModel.assets[index])
                        .presentationDetents([.medium])
                } else {
                    Text("Asset unavailable")
                        .presentationDetents([.medium])
                }
            }
        }
        .alert(
            "Deduct this transaction?",
            isPresented: $viewModel.isShowingDeductConfirmation,
            presenting: viewModel.selectedTransaction
        ) { selection in
            Button("Confirm Deduction", role: .destructive) {
                viewModel.deduct(selection)
            }
            .accessibilityIdentifier(XQAccessibilityIdentifier.confirmDeductionButton.rawValue)
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier(XQAccessibilityIdentifier.cancelDeductionButton.rawValue)
        } message: { selection in
            Text("This removes \(selection.transaction.units.formattedUnits) units from the asset's buy lots.")
        }
    }
}

#Preview {
    let portfolio = PortfolioSnapshot(
        assets: [
            FinanceAsset(
                id: UUID(uuidString: "46C64E8D-039F-4E41-8E0C-7D6D970E3F91")!,
                symbol: "AAPL",
                name: "Apple Inc.",
                nativeCurrency: .usd,
                accent: FinanceAsset.accent(for: "AAPL"),
                currentPrice: 174.65,
                transactions: [
                    BuyTransaction(
                        id: UUID(uuidString: "52AD1788-4E1C-4797-9BD9-F5B77C9388E2")!,
                        date: "May 6, 2024",
                        units: 10.000,
                        unitPrice: 169.21
                    ),
                    BuyTransaction(
                        id: UUID(uuidString: "4A8E62BF-6FDE-482A-9F56-768440E28A5D")!,
                        date: "Apr 15, 2024",
                        units: 15.000,
                        unitPrice: 165.32
                    )
                ]
            ),
            FinanceAsset(
                id: UUID(uuidString: "87A05B55-3282-49EA-98E4-3A2C05B34B20")!,
                symbol: "VNGOLD",
                name: "VND Gold",
                nativeCurrency: .vnd,
                accent: XQPalette.positive,
                currentPrice: 7_850_000,
                transactions: [
                    BuyTransaction(
                        id: UUID(uuidString: "3AE792AC-4B1E-4712-A302-33E6D9F1D1BD")!,
                        date: "May 5, 2024",
                        units: 0.080,
                        unitPrice: 7_420_000
                    )
                ]
            )
        ],
        exchangeRateUSDToVND: 25_500
    )

    ContentView(summary: .default, portfolio: portfolio)
}
