import SwiftUI

/// Round icon button with a hover highlight (toolbar style).
struct IconButton: View {
    let symbol: String
    var help: String = ""
    var size: CGFloat = 26
    var spinning = false
    let action: () -> Void
    @ViewState private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(hovering ? Color.primary : Color.secondary)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(spinning ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default,
                           value: spinning)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.primary.opacity(hovering ? 0.10 : 0)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help)
        .accessibilityLabel(help)
    }
}

/// Capsule button used for secondary actions inside cards.
struct ChipButton: View {
    let title: String
    let symbol: String
    var tint: Color = .primary
    var prominent = false
    let action: () -> Void
    @ViewState private var hovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(prominent ? Color.white : tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5.5)
                .background(
                    Capsule().fill(prominent ? AnyShapeStyle(tint.gradient)
                                             : AnyShapeStyle(Color.primary.opacity(hovering ? 0.12 : 0.07)))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }
}

/// Small text button that looks like a link, for section headers.
struct LinkButton: View {
    let title: String
    let action: () -> Void
    @ViewState private var hovering = false

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(hovering ? Theme.alexaBlue : Color.secondary)
            .onHover { hovering = $0 }
    }
}
