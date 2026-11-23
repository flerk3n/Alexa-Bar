import Foundation

// Shapes of the helper's `result` objects, one per command.

struct HelloReply: Decodable {
    let protocolVersion: Int
    let email: String
    let domain: String
    let hasSession: Bool
    let migrated: Bool

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol", email, domain, hasSession, migrated
    }
}

struct AccountReply: Decodable {
    let email: String
    let domain: String
}

struct DeviceList: Decodable {
    let devices: [SmartDevice]
    let speakers: [Speaker]
}

struct StatesReply: Decodable {
    let states: [String: DeviceState]
}

struct VolumeInfo: Decodable, Equatable {
    let volume: Int?
    let muted: Bool
}

struct VolumesReply: Decodable {
    let volumes: [String: VolumeInfo]
}

struct ControlReply: Decodable {
    let via: String?
    let skipped: Bool?
}

struct EchoReply: Decodable {
    let echo: String?
    let skipped: Bool?
}

struct EmptyReply: Decodable {}
