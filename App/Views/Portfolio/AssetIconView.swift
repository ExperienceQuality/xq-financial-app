import SwiftUI

struct AssetIconView: View {
    let asset: FinanceAsset

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(asset.accent.gradient)

            Text(String(asset.symbol.prefix(1)))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 60, height: 60)
        .shadow(color: asset.accent.opacity(0.24), radius: 10, y: 8)
    }
}
