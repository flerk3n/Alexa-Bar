import SwiftUI

extension AppModel {
    func statusText(_ d: SmartDevice) -> String {
        if !isReachable(d) { return "Not responding" }
        let st = state(d)
        guard let on = st.on else { return "Unknown" }
        guard on else { return "Off" }
        var parts = ["On"]
        if d.canDim, let b = st.brightness { parts.append("\(b)%") }
        if d.isLight, let label = st.colorLabel ?? st.colorName.map(Self.prettyName) {
            parts.append(label)
        }
        return parts.joined(separator: " · ")
    }

    static func prettyName(_ s: String) -> String {
        s.replacingOccurrences(of: "_", with: " ").capitalized
    }

    func tint(for d: SmartDevice) -> Color {
        d.isLight ? state(d).lightTint : Theme.plugTint
    }
}
