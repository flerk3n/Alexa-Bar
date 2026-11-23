import SwiftUI

struct Swatch: View {
    let color: Color
    let label: String?
    let selected: Bool
    var size: CGFloat = 32
    let action: () -> Void
    @ViewState private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: size, height: size)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                    .shadow(color: color.opacity(hovering || selected ? 0.6 : 0.25), radius: hovering || selected ? 6 : 2)
                    .padding(3)
                    .overlay(
                        Circle().strokeBorder(selected ? Color.primary.opacity(0.85) : .clear, lineWidth: 2)
                    )
                    .scaleEffect(hovering ? 1.08 : 1)
                if let label {
                    Text(label)
                        .font(.system(size: 10, weight: selected ? .bold : .medium))
                        .foregroundStyle(selected ? .primary : .secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.18), value: hovering)
        .animation(.snappy(duration: 0.2), value: selected)
    }
}
