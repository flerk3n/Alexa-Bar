import SwiftUI

struct CardBackground: ViewModifier {
    var tint: Color?
    var isOn: Bool
    var hovering = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.cardFill.opacity(hovering ? 1.6 : 1))
                    .overlay {
                        if isOn, let tint {
                            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                .fill(LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.07)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(isOn && tint != nil ? tint!.opacity(0.30) : Theme.cardStroke)
            }
    }
}

extension View {
    func card(tint: Color? = nil, isOn: Bool = false, hovering: Bool = false) -> some View {
        modifier(CardBackground(tint: tint, isOn: isOn, hovering: hovering))
    }
}

/// Slight shrink on press; used for tappable cards.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
