import SwiftUI

/// A colour Alexa understands by name (`setColor` with `colorName`).
struct ColorPreset: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color

    static let all: [ColorPreset] = [
        .init(id: "red", label: "Red", color: Color(red: 1.00, green: 0.23, blue: 0.19)),
        .init(id: "orange", label: "Orange", color: Color(red: 1.00, green: 0.55, blue: 0.10)),
        .init(id: "gold", label: "Gold", color: Color(red: 1.00, green: 0.76, blue: 0.10)),
        .init(id: "yellow", label: "Yellow", color: Color(red: 1.00, green: 0.90, blue: 0.20)),
        .init(id: "green", label: "Green", color: Color(red: 0.20, green: 0.84, blue: 0.35)),
        .init(id: "turquoise", label: "Turquoise", color: Color(red: 0.25, green: 0.88, blue: 0.82)),
        .init(id: "cyan", label: "Cyan", color: Color(red: 0.20, green: 0.80, blue: 1.00)),
        .init(id: "sky_blue", label: "Sky blue", color: Color(red: 0.45, green: 0.72, blue: 1.00)),
        .init(id: "blue", label: "Blue", color: Color(red: 0.16, green: 0.40, blue: 1.00)),
        .init(id: "purple", label: "Purple", color: Color(red: 0.60, green: 0.32, blue: 0.95)),
        .init(id: "magenta", label: "Magenta", color: Color(red: 0.95, green: 0.25, blue: 0.80)),
        .init(id: "pink", label: "Pink", color: Color(red: 1.00, green: 0.45, blue: 0.65)),
    ]
}

/// A white Alexa understands by name (`setColorTemperature`).
struct WhitePreset: Identifiable, Hashable {
    let id: String
    let label: String
    let kelvin: Int

    var color: Color { KelvinColor.color(kelvin) }

    static let all: [WhitePreset] = [
        .init(id: "warm_white", label: "Warm", kelvin: 2200),
        .init(id: "soft_white", label: "Soft", kelvin: 2700),
        .init(id: "white", label: "White", kelvin: 4000),
        .init(id: "daylight_white", label: "Daylight", kelvin: 5500),
        .init(id: "cool_white", label: "Cool", kelvin: 7000),
    ]
}

enum KelvinColor {
    /// Approximate colour of white light at a temperature, for UI tinting.
    static func color(_ k: Int) -> Color {
        let warm = (r: 1.00, g: 0.72, b: 0.40)
        let cool = (r: 0.80, g: 0.90, b: 1.00)
        let t = min(max((Double(k) - 2200) / (7000 - 2200), 0), 1)
        return Color(
            red: warm.r + (cool.r - warm.r) * t,
            green: warm.g + (cool.g - warm.g) * t,
            blue: warm.b + (cool.b - warm.b) * t
        )
    }
}
