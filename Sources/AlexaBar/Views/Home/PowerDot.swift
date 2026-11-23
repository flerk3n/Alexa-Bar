import SwiftUI

/// Tiny on/off switch glyph in the corner of a tile.
struct PowerDot: View {
    let on: Bool
    let tint: Color

    var body: some View {
        Capsule()
            .fill(on ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.primary.opacity(0.12)))
            .frame(width: 26, height: 15)
            .overlay(alignment: on ? .trailing : .leading) {
                Circle().fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                    .padding(2)
            }
            .animation(.snappy(duration: 0.25), value: on)
    }
}
