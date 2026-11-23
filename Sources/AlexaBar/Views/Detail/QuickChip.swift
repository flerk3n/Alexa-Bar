import SwiftUI

struct QuickChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void
    @ViewState private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(Color.primary.opacity(selected ? 0.16 : (hovering ? 0.10 : 0.06)))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }
}
