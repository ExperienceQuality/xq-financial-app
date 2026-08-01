import SwiftUI

struct TransactionHeaderRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Units")
                .frame(width: 64, alignment: .leading)

            Text("Price / unit")
                .frame(width: 84, alignment: .leading)

            Spacer(minLength: 4)

            Text("Subtotal")
                .frame(width: 86, alignment: .trailing)

            Color.clear.frame(width: 38, height: 1)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(XQPalette.muted)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(XQPalette.softFill.opacity(0.72))
    }
}
