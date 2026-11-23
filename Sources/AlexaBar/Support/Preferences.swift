import Foundation

/// User settings stored in UserDefaults.
@MainActor
final class Preferences: ObservableObject {
    private let defaults: UserDefaults

    @Published var defaultEchoSerial: String { didSet { defaults.set(defaultEchoSerial, forKey: Keys.echo) } }
    @Published var refreshInterval: Double { didSet { defaults.set(refreshInterval, forKey: Keys.interval) } }
    @Published var showSpeakers: Bool { didSet { defaults.set(showSpeakers, forKey: Keys.speakers) } }
    @Published var hiddenDevices: Set<String> { didSet { defaults.set(hiddenDevices.sorted(), forKey: Keys.hidden) } }
    @Published var showOnCountInMenuBar: Bool { didSet { defaults.set(showOnCountInMenuBar, forKey: Keys.onCount) } }
    @Published var hasOfferedLaunchAtLogin: Bool { didSet { defaults.set(hasOfferedLaunchAtLogin, forKey: Keys.offered) } }

    static let refreshChoices: [(label: String, seconds: Double)] = [
        ("30 sec", 30), ("1 min", 60), ("2 min", 120), ("5 min", 300),
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultEchoSerial = defaults.string(forKey: Keys.echo) ?? ""
        refreshInterval = defaults.object(forKey: Keys.interval) as? Double ?? 60
        showSpeakers = defaults.object(forKey: Keys.speakers) as? Bool ?? true
        hiddenDevices = Set(defaults.stringArray(forKey: Keys.hidden) ?? [])
        showOnCountInMenuBar = defaults.object(forKey: Keys.onCount) as? Bool ?? false
        hasOfferedLaunchAtLogin = defaults.bool(forKey: Keys.offered)
    }

    private enum Keys {
        static let echo = "defaultEchoSerial"
        static let interval = "refreshInterval"
        static let speakers = "showSpeakers"
        static let hidden = "hiddenDevices"
        static let onCount = "showOnCountInMenuBar"
        static let offered = "hasOfferedLaunchAtLogin"
    }
}
