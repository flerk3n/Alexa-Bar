import SwiftUI

struct SigningInView: View {
    @EnvironmentObject var model: AppModel
    let url: URL?
    @ViewState private var pulse = false
    @ViewState private var copied = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Theme.alexaBlue.opacity(0.35), lineWidth: 2)
                    .frame(width: 84, height: 84)
                    .scaleEffect(pulse ? 1.25 : 0.9)
                    .opacity(pulse ? 0 : 1)
                AlexaGlyph(size: 50, glow: true)
            }
            .frame(height: 100)
            .onAppear {
                withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
            }

            VStack(spacing: 6) {
                Text("Finish signing in")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text(url == nil
                     ? "Opening Amazon's sign-in page…"
                     : "Amazon's sign-in page is open in your browser. Enter your password and any verification code there. This panel updates when you're done.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button("Cancel") { model.cancelSignIn() }
                    .controlSize(.large)
                if let url {
                    Button("Open Sign-in Page") { NSWorkspace.shared.open(url) }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.alexaBlue)
                }
            }
            if let url {
                LinkButton(title: copied ? "Link copied" : "Copy link for another browser") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                    copied = true
                }
            }
        }
        .padding(.top, 6)
    }
}
