import Foundation

/// Standard per-user locations for the app's data and logs.
enum AppPaths {
    static let appName = "Alexa Bar"

    /// ~/Library/Application Support/Alexa Bar (session tokens live here, mode 700).
    static var dataDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(appName, isDirectory: true)
    }

    /// ~/Library/Logs/Alexa Bar
    static var logsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs", isDirectory: true)
            .appendingPathComponent(appName, isDirectory: true)
    }

    static var helperLog: URL { logsDirectory.appendingPathComponent("helper.log") }

    static func ensure() {
        let fm = FileManager.default
        try? fm.createDirectory(at: dataDirectory, withIntermediateDirectories: true,
                                attributes: [.posixPermissions: 0o700])
        try? fm.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
    }
}
