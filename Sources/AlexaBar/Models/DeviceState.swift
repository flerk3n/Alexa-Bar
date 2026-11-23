import SwiftUI

struct HSBColor: Codable, Equatable, Hashable {
    var hue: Double
    var saturation: Double
    var brightness: Double
}

/// Live state of a smart home device. Every field is optional because
/// devices report only what they support.
struct DeviceState: Codable, Equatable {
    var on: Bool?
    var brightness: Int?
    var kelvin: Int?
    var color: HSBColor?
    var colorName: String?
    var colorLabel: String?
    var reachable: Bool?
    var percentage: Int?
}

extension DeviceState {
    /// The colour a light is emitting, for tinting its card.
    var lightTint: Color {
        if let name = colorName {
            if let p = ColorPreset.all.first(where: { $0.id == name }) { return p.color }
            if let w = WhitePreset.all.first(where: { $0.id == name }) { return w.color }
        }
        if let c = color, c.saturation > 0.15 {
            return Color(hue: c.hue / 360, saturation: max(c.saturation, 0.55), brightness: 1)
        }
        if let k = kelvin { return KelvinColor.color(k) }
        return Color(red: 1.0, green: 0.80, blue: 0.35)
    }

    /// White light rather than a saturated colour.
    var isWhite: Bool { color == nil || (color?.saturation ?? 0) < 0.15 }
}
