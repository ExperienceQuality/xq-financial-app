import SwiftUI

struct HeaderView: View {
    let title: String
    let position: Int
    let count: Int
    let onAddAsset: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(XQPalette.ink)

                Text(count == 0 ? "No assets yet" : "\(count) assets")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(XQPalette.muted)
            }

            Spacer()

            HStack(spacing: 10) {
                Text(count == 0 ? "0 / 0" : "\(position) / \(count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(XQPalette.muted)
                    .accessibilityIdentifier(XQAccessibilityIdentifier.portfolioPosition.rawValue)

                Button(action: onAddAsset) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(XQPalette.ink, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .accessibilityLabel("Add asset")
                .accessibilityIdentifier(XQAccessibilityIdentifier.addAssetButton.rawValue)
            }
        }
    }
}
