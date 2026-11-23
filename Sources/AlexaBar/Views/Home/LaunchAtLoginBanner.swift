import SwiftUI

/// Shown once after the first successful sign-in.
struct LaunchAtLoginBanner: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "power.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text("Open Alexa Bar at login?")
                    .font(.system(size: 12.5, weight: .semibold))
                Text("Keeps your devices one click away. You can change this in Settings.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            VStack(spacing: 4) {
                ChipButton(title: "Turn On", symbol: "checkmark", tint: Theme.alexaBlue, prominent: true) {
                    model.answerLaunchAtLoginOffer(true)
                }
                LinkButton(title: "Not now") { model.answerLaunchAtLoginOffer(false) }
            }
        }
        .padding(12)
        .card(tint: Theme.alexaBlue, isOn: true)
    }
}
