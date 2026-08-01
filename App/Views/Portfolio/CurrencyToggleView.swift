import SwiftUI

struct CurrencyToggleView: View {
    @Binding var displayCurrency: DisplayCurrency

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width / CGFloat(DisplayCurrency.allCases.count)
            let thumbWidth = max(0, segmentWidth - 4)
            let thumbX = displayCurrency == .usd ? 4 : segmentWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white)
                    .overlay(Capsule().stroke(XQPalette.divider, lineWidth: 1))

                Capsule()
                    .fill(XQPalette.ink)
                    .shadow(
                        color: XQPalette.shadow.opacity(0.16),
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                    .frame(width: thumbWidth, height: 56)
                    .offset(x: thumbX, y: 0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: displayCurrency)
                    .allowsHitTesting(false)

                HStack(spacing: 0) {
                    ForEach(DisplayCurrency.allCases) { currency in
                        Text(currency.rawValue)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(displayCurrency == currency ? .white : XQPalette.muted)
                            .frame(width: segmentWidth, height: 64)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        selectCurrency(atX: value.location.x, controlWidth: proxy.size.width)
                    }
            )
        }
        .frame(height: 64)
        .sensoryFeedback(.selection, trigger: displayCurrency)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Display currency")
        .accessibilityValue(displayCurrency.rawValue)
        .accessibilityIdentifier(XQAccessibilityIdentifier.displayCurrencyToggle.rawValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                setCurrency(.vnd)
            case .decrement:
                setCurrency(.usd)
            default:
                break
            }
        }
    }

    private func selectCurrency(atX xPosition: CGFloat, controlWidth: CGFloat) {
        setCurrency(xPosition < controlWidth / 2 ? .usd : .vnd)
    }

    private func setCurrency(_ currency: DisplayCurrency) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            displayCurrency = currency
        }
    }
}
