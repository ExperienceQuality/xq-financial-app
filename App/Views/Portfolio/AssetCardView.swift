import SwiftUI

struct AssetCardView: View {
    let asset: FinanceAsset
    let isActive: Bool
    let displayCurrency: DisplayCurrency
    let exchangeRateUSDToVND: Double
    let onEditPrice: () -> Void
    let onAddBuyLot: () -> Void
    let onEditTransaction: (BuyTransaction) -> Void
    let onSelectTransaction: (BuyTransaction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                AssetIconView(asset: asset)

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.symbol)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(XQPalette.ink)
                        .accessibilityIdentifier(
                            isActive
                                ? XQAccessibilityIdentifier.assetSymbol.rawValue
                                : "asset-symbol-inactive"
                        )

                    Text(asset.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(XQPalette.muted)
                }

                Spacer()

                Button {
                    onEditPrice()
                } label: {
                    Label("Edit price", systemImage: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white, in: Capsule())
                        .overlay(
                            Capsule().stroke(XQPalette.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(XQPalette.ink)
                .accessibilityLabel("Update current price for \(asset.symbol)")
                .accessibilityIdentifier(XQAccessibilityIdentifier.editPriceButton.rawValue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(displayCurrency.formatted(fromUSD: asset.currentValueInUSD(exchangeRateUSDToVND: exchangeRateUSDToVND), exchangeRateUSDToVND: exchangeRateUSDToVND))
                    .font(.system(size: displayCurrency == .usd ? 38 : 30, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
                    .foregroundStyle(XQPalette.ink)
                    .accessibilityIdentifier(
                        isActive
                            ? XQAccessibilityIdentifier.assetCurrentValue.rawValue
                            : "asset-current-value-inactive"
                    )

                Text("Current total value")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(XQPalette.muted)
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("Buy Lots")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(XQPalette.ink)

                    Text("\(asset.transactions.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(XQPalette.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(XQPalette.softFill, in: Capsule())

                    Spacer()

                    Button {
                        onAddBuyLot()
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .labelStyle(.titleAndIcon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(XQPalette.ink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .accessibilityLabel("Add buy lot for \(asset.symbol)")
                    .accessibilityIdentifier(XQAccessibilityIdentifier.addBuyLotButton.rawValue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)

                Divider().overlay(XQPalette.divider)

                TransactionHeaderRow()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(asset.transactions) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                displayCurrency: displayCurrency,
                                assetCurrency: asset.nativeCurrency,
                                exchangeRateUSDToVND: exchangeRateUSDToVND,
                                onDeduct: { onSelectTransaction(transaction) },
                                onEdit: { onEditTransaction(transaction) }
                            )

                            if transaction.id != asset.transactions.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                                    .overlay(XQPalette.divider)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(XQPalette.divider, lineWidth: 1)
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(isActive ? XQPalette.divider : XQPalette.divider.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: XQPalette.shadow.opacity(isActive ? 0.18 : 0.08), radius: isActive ? 22 : 12, x: 0, y: isActive ? 16 : 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            isActive
                ? XQAccessibilityIdentifier.assetCard.rawValue
                : "asset-card-inactive"
        )
    }
}
