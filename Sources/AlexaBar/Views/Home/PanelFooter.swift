import SwiftUI

/// Connection dot, last update time and region.
struct PanelFooter: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(model.isOffline ? Color.orange : Color.green)
                .frame(width: 6, height: 6)
            TimelineView(.periodic(from: .now, by: 10)) { _ in
                Text(updatedText)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text("\(model.region.flag) \(model.domain)")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    private var updatedText: String {
        if model.isOffline { return "Offline" }
        guard let d = model.lastUpdated else { return "Connected" }
        let s = Int(Date().timeIntervalSince(d))
        if s < 15 { return "Updated just now" }
        if s < 60 { return "Updated \(s)s ago" }
        return "Updated \(s / 60)m ago"
    }
}
