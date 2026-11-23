import SwiftUI

/// Everything shown before the device list is available.
struct StatusScreens: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                IconButton(symbol: "gearshape.fill", help: "Settings") {
                    withAnimation(.snappy(duration: 0.3)) { model.page = .settings }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            Group {
                switch model.phase {
                case .starting, .connecting:
                    LoadingView(text: model.phase == .starting ? "Starting…" : "Connecting to Alexa…")
                case .signedOut:
                    SignInView()
                case .signingIn(let url):
                    SigningInView(url: url)
                case .failed(let message):
                    FailedView(message: message)
                case .ready:
                    EmptyView()
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
    }
}
