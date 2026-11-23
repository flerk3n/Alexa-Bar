import AppKit

/// Quits if another copy of the app is already running (e.g. opened twice
/// from Finder, or a login item plus a manual launch).
enum SingleInstance {
    /// Returns true when this process should keep running.
    static func claim() -> Bool {
        guard let id = Bundle.main.bundleIdentifier else { return true }
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .filter { $0.processIdentifier != me && !$0.isTerminated }
        return others.isEmpty
    }
}
