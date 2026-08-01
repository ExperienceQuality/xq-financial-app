import SwiftUI

struct AssetDeckView: View {
    let assets: [FinanceAsset]
    let activeIndex: Int
    let dragOffset: CGSize
    let displayCurrency: DisplayCurrency
    let exchangeRateUSDToVND: Double
    let onAddAsset: () -> Void
    let onEditPrice: (FinanceAsset) -> Void
    let onAddBuyLot: (FinanceAsset) -> Void
    let onSelectTransaction: (FinanceAsset, BuyTransaction) -> Void

    var body: some View {
        ZStack {
            if assets.isEmpty {
                EmptyPortfolioView(onAddAsset: onAddAsset)
            } else {
                // Key by asset index so cards keep identity while the deck rotates.
                let indices = (0..<min(3, assets.count)).map { offset in
                    (activeIndex + offset) % assets.count
                }
                ForEach(Array(indices.enumerated()), id: \.element) { deckPosition, assetIndex in
                    let asset = assets[assetIndex]

                    AssetCardView(
                        asset: asset,
                        isActive: deckPosition == 0,
                        displayCurrency: displayCurrency,
                        exchangeRateUSDToVND: exchangeRateUSDToVND,
                        onEditPrice: { onEditPrice(asset) },
                        onAddBuyLot: { onAddBuyLot(asset) },
                        onSelectTransaction: { onSelectTransaction(asset, $0) }
                    )
                    .offset(x: xOffset(for: deckPosition), y: yOffset(for: deckPosition))
                    .rotationEffect(.degrees(rotation(for: deckPosition)))
                    .scaleEffect(scale(for: deckPosition))
                    .zIndex(Double(indices.count - deckPosition))
                    .allowsHitTesting(deckPosition == 0)
                    .accessibilityHidden(deckPosition != 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 520)
    }

    private func xOffset(for deckPosition: Int) -> CGFloat {
        guard deckPosition == 0 else { return CGFloat(deckPosition) * 44 }
        return dragOffset.width
    }

    private func yOffset(for deckPosition: Int) -> CGFloat {
        guard deckPosition == 0 else { return CGFloat(deckPosition) * 20 }
        return dragOffset.height * 0.16
    }

    private func rotation(for deckPosition: Int) -> Double {
        guard deckPosition == 0 else { return Double(deckPosition) * 3.5 }
        return Double(dragOffset.width / 28)
    }

    private func scale(for deckPosition: Int) -> CGFloat {
        deckPosition == 0 ? 1 : 1 - CGFloat(deckPosition) * 0.045
    }
}
