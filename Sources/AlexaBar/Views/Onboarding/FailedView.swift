import SwiftUI

struct FailedView: View {
    @EnvironmentObject var model: AppModel
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.orange)
                .padding(.top, 6)
            Text("Can't reach Alexa")
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(6)
                .textSelection(.enabled)
            HStack(spacing: 8) {
                Button("Sign In Again") { model.phase = .signedOut }
                    .controlSize(.large)
                Button("Try Again") { model.retry() }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.alexaBlue)
            }
        }
    }
}
