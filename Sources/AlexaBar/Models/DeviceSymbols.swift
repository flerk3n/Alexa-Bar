import AppKit

/// SF Symbols for device types, with fallbacks for older macOS versions.
enum DeviceSymbols {
    static func exists(_ name: String) -> Bool {
        NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    }

    static func first(_ names: [String]) -> String {
        names.first(where: exists) ?? "circle.fill"
    }

    static func symbol(for kind: String, appliance: String, on: Bool) -> String {
        switch kind {
        case "LIGHT": return on ? "lightbulb.fill" : "lightbulb"
        case "COMPUTER": return first(["desktopcomputer", "display"])
        case "TV": return first(["tv.fill", "tv"])
        case "FAN": return first(["fan.fill", "fanblades.fill", "wind"])
        case "SWITCH": return first([on ? "lightswitch.on.fill" : "lightswitch.off.fill", "switch.2"])
        case "THERMOSTAT", "TEMPERATURE_SENSOR": return first(["thermometer.medium", "thermometer"])
        case "AIR_PURIFIER": return first(["air.purifier.fill", "wind"])
        case "AIR_CONDITIONER": return first(["air.conditioner.horizontal.fill", "snowflake"])
        case "CAMERA": return "video.fill"
        case "GARAGE_DOOR": return first(["door.garage.closed", "car.fill"])
        case "SMARTLOCK": return on ? "lock.open.fill" : "lock.fill"
        case "SPEAKERS": return "hifispeaker.fill"
        case "GAME_CONSOLE": return "gamecontroller.fill"
        default: break
        }
        switch appliance {
        case "LIGHT": return on ? "lightbulb.fill" : "lightbulb"
        case "SWITCH": return first(["lightswitch.on.fill", "switch.2"])
        default: return first(["poweroutlet.type.b.fill", "powerplug.fill", "power"])
        }
    }
}
