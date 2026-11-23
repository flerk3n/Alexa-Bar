import SwiftUI

/// Title, live summary, refresh and settings. ⌘R refreshes, ⌘, opens settings.
struct PanelHeader: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 10) {
            AlexaGlyph(size: 26, glow: model.onCount > 0)
            VStack(alignment: .leading, spacing: 1) {
                Text("Alexa")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(summary)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: summary)
            }
            Spacer()
            IconButton(symbol: "arrow.clockwise", help: "Refresh (⌘R)", spinning: model.isRefreshing) {
                model.refresh()
            }
            .keyboardShortcut("r", modifiers: .command)
            IconButton(symbol: "gearshape.fill", help: "Settings (⌘,)") {
                withAnimation(.snappy(duration: 0.3)) { model.page = .settings }
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var summary: String {
        let total = model.visibleDevices.count
        if total == 0 {
            return model.speakers.isEmpty ? "No devices" : (model.speakers.count == 1 ? "1 Echo" : "\(model.speakers.count) Echo devices")
        }
        let devices = total == 1 ? "1 device" : "\(total) devices"
        return model.onCount == 0 ? "\(devices) · all off" : "\(devices) · \(model.onCount) on"
    }
}
