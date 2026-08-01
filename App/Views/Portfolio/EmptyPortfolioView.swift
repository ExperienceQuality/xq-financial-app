import SwiftUI

struct EmptyPortfolioView: View {
    let onAddAsset: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(XQPalette.muted)

            VStack(spacing: 4) {
                Text("Add your first asset")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(XQPalette.ink)

                Text("Start with USD or VND, then add buy lots as you go.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(XQPalette.muted)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddAsset) {
                Label("Add Asset", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(XQPalette.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityIdentifier(XQAccessibilityIdentifier.addAssetButton.rawValue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(XQPalette.divider, lineWidth: 1)
        )
        .accessibilityIdentifier(XQAccessibilityIdentifier.emptyPortfolio.rawValue)
    }
}
