import Foundation

/// A smart home device (light, plug, switch...) as reported by the helper.
struct SmartDevice: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let kind: String
    let applianceType: String
    let operations: [String]
    let available: Bool

    var canPower: Bool { operations.contains("turnOn") || operations.contains("turnOff") }
    var canDim: Bool { operations.contains("setBrightness") }
    var canColor: Bool { operations.contains("setColor") }
    var canWhite: Bool { operations.contains("setColorTemperature") }
    var hasExtraControls: Bool { canDim || canColor || canWhite }

    var isLight: Bool { kind == "LIGHT" || applianceType == "LIGHT" || canColor || canWhite }

    /// Brand / model text without the "(TYPE)" suffix Amazon appends.
    var subtitle: String {
        if let r = description.lastIndex(of: "("), description.hasSuffix(")") {
            return description[..<r].trimmingCharacters(in: .whitespaces)
        }
        return description
    }

    func symbol(on: Bool) -> String {
        DeviceSymbols.symbol(for: kind, appliance: applianceType, on: on)
    }
}
