import SwiftUI

struct EmptyDevicesView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "house")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.secondary)
            Text("No smart home devices yet")
                .font(.system(size: 13, weight: .semibold))
            Text("Devices you add in the Alexa app will show up here.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
