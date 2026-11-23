import SwiftUI

/// Thick capsule slider in the style of Control Center.
/// Shows `value` (0...1), and calls `onCommit` when a drag ends.
struct PillSlider: View {
    let value: Double
    var tint: Color
    var label: String
    var height: CGFloat = 30
    var leading: String = "sun.min.fill"
    var dimmed = false
    var minimum: Double = 0.01
    let onCommit: (Double) -> Void

    @ViewState private var dragValue: Double?
    @ViewState private var hovering = false

    private var shown: Double { dragValue ?? value }
    private var percent: Int { Int((shown * 100).rounded()) }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(
                        colors: [tint.opacity(dimmed ? 0.35 : 0.75), tint.opacity(dimmed ? 0.45 : 1)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, w * shown))
                    .shadow(color: tint.opacity(dimmed ? 0 : 0.35), radius: 5)
                labels
            }
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(hovering ? 0.14 : 0.06)))
            .contentShape(Capsule())
            .gesture(drag(width: w))
            .scaleEffect(y: dragValue != nil ? 1.06 : 1)
            .animation(.snappy(duration: 0.18), value: dragValue != nil)
            .animation(.snappy(duration: 0.3), value: value)
        }
        .frame(height: height)
        .onHover { hovering = $0 }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("\(percent) percent")
        .accessibilityAdjustableAction { direction in
            let step = 0.1
            switch direction {
            case .increment: onCommit(min(value + step, 1))
            case .decrement: onCommit(max(value - step, minimum))
            @unknown default: break
            }
        }
    }

    private var labels: some View {
        let fg = dimmed ? Color.secondary : tint.onColor
        let shadow = Color.black.opacity(!dimmed && !tint.isPale ? 0.2 : 0)
        return HStack {
            Image(systemName: leading)
                .font(.system(size: height * 0.42, weight: .semibold))
                .foregroundStyle(shown > 0.12 ? fg : Color.secondary)
                .shadow(color: shown > 0.12 ? shadow : .clear, radius: 1)
            Spacer()
            Text("\(percent)%")
                .font(.system(size: height * 0.38, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: shown))
                .foregroundStyle(shown > 0.88 ? fg : Color.secondary)
        }
        .padding(.horizontal, height * 0.33)
        .allowsHitTesting(false)
    }

    private func drag(width w: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                dragValue = min(max(v.location.x / w, minimum), 1)
            }
            .onEnded { v in
                let final = min(max(v.location.x / w, minimum), 1)
                dragValue = final
                onCommit(final)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dragValue = nil }
            }
    }
}
