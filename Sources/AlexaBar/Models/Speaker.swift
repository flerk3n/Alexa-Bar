import Foundation

/// An Echo (or other Alexa speaker) that can speak and take commands.
struct Speaker: Identifiable, Codable, Hashable {
    let serial: String
    let deviceType: String
    let name: String
    let family: String
    let online: Bool
    let customerId: String
    let capabilities: [String]

    var id: String { serial }

    var canVolume: Bool { capabilities.contains("VOLUME_SETTING") || family == "ECHO" || family == "KNIGHT" }

    var symbol: String {
        switch family {
        case "KNIGHT": return DeviceSymbols.first(["display", "tv"])
        case "FIRE_TV": return DeviceSymbols.first(["tv.fill", "tv"])
        case "TABLET": return DeviceSymbols.first(["ipad", "rectangle.portrait"])
        default: return DeviceSymbols.first(["homepodmini.fill", "hifispeaker.fill", "speaker.wave.2.fill"])
        }
    }
}
