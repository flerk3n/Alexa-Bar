import SwiftUI

struct ToastView: View {
    let toast: Toast

    private var symbol: String {
        switch toast.style {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch toast.style {
        case .info: return Theme.alexaBlue
        case .success: return .green
        case .error: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(toast.message)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .padding(.horizontal, 16)
    }
}
