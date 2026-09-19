import SwiftUI

struct TransactionHeaderRow: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Units")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Price / unit")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Subtotal")
                .frame(maxWidth: .infinity, alignment: .trailing)

            Color.clear.frame(width: 60, height: 1)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(XQPalette.muted)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(XQPalette.softFill.opacity(0.72))
    }
}
