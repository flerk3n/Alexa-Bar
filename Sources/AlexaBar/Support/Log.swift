import Foundation
import os

enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "AlexaBar"
    static let app = Logger(subsystem: subsystem, category: "app")
    static let helper = Logger(subsystem: subsystem, category: "helper")
}

/// Appends the helper's stderr to ~/Library/Logs/Alexa Bar/helper.log.
/// The file is cut back when it grows past `maxBytes`.
final class HelperLogFile {
    private let url: URL
    private let maxBytes: UInt64
    private let queue = DispatchQueue(label: "AlexaBar.helper-log")
    private var handle: FileHandle?

    init(url: URL = AppPaths.helperLog, maxBytes: UInt64 = 1_000_000) {
        self.url = url
        self.maxBytes = maxBytes
    }

    func append(_ data: Data) {
        queue.async { [self] in
            if handle == nil { open() }
            handle?.seekToEndOfFile()
            handle?.write(data)
            if let size = try? handle?.offset(), size > maxBytes { rotate() }
        }
    }

    func writeMarker(_ text: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        append(Data("\n--- \(stamp) \(text) ---\n".utf8))
    }

    private func open() {
        AppPaths.ensure()
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600])
        }
        handle = try? FileHandle(forWritingTo: url)
    }

    private func rotate() {
        try? handle?.close()
        handle = nil
        let old = url.deletingPathExtension().appendingPathExtension("old.log")
        try? FileManager.default.removeItem(at: old)
        try? FileManager.default.moveItem(at: url, to: old)
        open()
    }
}
