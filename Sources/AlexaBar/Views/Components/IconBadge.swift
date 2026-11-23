import SwiftUI

struct IconBadge: View {
    let symbol: String
    var tint: Color
    var isOn: Bool
    var pending = false
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle()
                .fill(isOn ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.primary.opacity(0.10)))
                .shadow(color: isOn ? tint.opacity(0.45) : .clear, radius: 6, y: 1)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(isOn ? tint.onColor : Color.secondary)
                .shadow(color: isOn && !tint.isPale ? .black.opacity(0.18) : .clear, radius: 1, y: 0.5)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isOn)
            if pending {
                PendingRing(color: isOn ? tint : .secondary)
                    .padding(-3)
            }
        }
        .frame(width: size, height: size)
        .animation(.snappy(duration: 0.25), value: isOn)
    }
}

struct PendingRing: View {
    var color: Color
    @ViewState private var spin = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.28)
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(spin ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) { spin = true }
            }
    }
}
