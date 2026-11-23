import SwiftUI

struct LoadingView: View {
    let text: String
    @ViewState private var breathe = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                AlexaGlyph(size: 26, glow: true)
                    .opacity(breathe ? 1 : 0.45)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever()) { breathe = true }
                    }
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            VStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { _ in skeletonCard(tall: true) }
                HStack(spacing: 10) {
                    skeletonCard(tall: false)
                    skeletonCard(tall: false)
                }
            }
            .shimmer()
        }
        .padding(.top, 4)
    }

    private func skeletonCard(tall: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle().fill(Color.primary.opacity(0.10)).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 5) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.10)).frame(width: 90, height: 9)
                    RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.07)).frame(width: 50, height: 7)
                }
                Spacer(minLength: 0)
            }
            if tall {
                Capsule().fill(Color.primary.opacity(0.07)).frame(height: 24)
            }
        }
        .padding(12)
        .card()
    }
}
