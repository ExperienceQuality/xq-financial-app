import SwiftUI

/// Owns portfolio screen state and user intents. Views bind to this and stay presentation-only.
@Observable
@MainActor
final class PortfolioViewModel {
    var assets: [FinanceAsset]
    var exchangeRateUSDToVND: Double
    var activeIndex = 0
    var dragOffset: CGSize = .zero
    var selectedTransaction: TransactionSelection?
    var isShowingDeductConfirmation = false
    var activeSheet: AssetSheet?
    var displayCurrency = DisplayCurrency.usd

    let summary: FinanceAppSummary

    init(summary: FinanceAppSummary = .default, portfolio: PortfolioSnapshot? = nil) {
        self.summary = summary
        let snapshot = portfolio ?? PortfolioStore.loadPortfolio()
        assets = snapshot.financeAssets
        exchangeRateUSDToVND = snapshot.exchangeRateUSDToVND
    }

    var portfolioTotalValue: Double {
        assets.reduce(0) { $0 + $1.currentValueInUSD(exchangeRateUSDToVND: exchangeRateUSDToVND) }
    }

    var persistenceSignature: String {
        PortfolioStore.signature(
            for: PortfolioSnapshot(assets: assets, exchangeRateUSDToVND: exchangeRateUSDToVND)
        )
    }

    var deckPositionLabel: Int {
        assets.isEmpty ? 0 : activeIndex + 1
    }

    func persist() {
        PortfolioStore.save(
            PortfolioSnapshot(assets: assets, exchangeRateUSDToVND: exchangeRateUSDToVND)
        )
    }

    func presentAddAsset() {
        activeSheet = .addAsset
    }

    func presentEditPrice(for asset: FinanceAsset) {
        activeSheet = .editPrice(asset.id)
    }

    func presentAddBuyLot(for asset: FinanceAsset) {
        activeSheet = .addBuyLot(asset.id)
    }

    func requestDeduction(asset: FinanceAsset, transaction: BuyTransaction) {
        selectedTransaction = TransactionSelection(assetID: asset.id, transaction: transaction)
        isShowingDeductConfirmation = true
    }

    func handleDragChanged(_ translation: CGSize) {
        dragOffset = translation
    }

    func handleDragEnd(_ translation: CGSize) {
        guard assets.count > 1 else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                dragOffset = .zero
            }
            return
        }

        if translation.width > 90 {
            moveToNextCard(direction: .right)
        } else if translation.width < -90 {
            moveToNextCard(direction: .left)
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                dragOffset = .zero
            }
        }
    }

    func moveToNextCard(direction: SwipeDirection) {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            dragOffset = CGSize(width: direction == .right ? 520 : -520, height: -20)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            guard !assets.isEmpty else {
                dragOffset = .zero
                return
            }
            activeIndex = AssetDeckNavigation.index(
                after: activeIndex,
                direction: direction,
                count: assets.count
            )
            dragOffset = .zero
        }
    }

    func deduct(_ selection: TransactionSelection) {
        guard let index = assets.firstIndex(where: { $0.id == selection.assetID }) else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            assets[index].deduct(transactionID: selection.transaction.id)
        }
    }

    func addAsset(
        symbol: String,
        name: String,
        nativeCurrency: AssetCurrency,
        startingPrice: Double
    ) {
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let newAsset = FinanceAsset(
            id: UUID(),
            symbol: trimmedSymbol,
            name: trimmedName,
            nativeCurrency: nativeCurrency,
            accent: FinanceAsset.accent(for: trimmedSymbol),
            currentPrice: max(0, startingPrice),
            transactions: []
        )

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            assets.insert(newAsset, at: 0)
            activeIndex = 0
            dragOffset = .zero
        }
    }

    func assetIndex(for id: UUID) -> Int? {
        assets.firstIndex(where: { $0.id == id })
    }
}
