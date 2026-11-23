import Foundation

/// Finds the helper inside the app bundle:
///
///     Contents/Resources/helper/
///         python/bin/python3        standalone CPython
///         site-packages/            AlexaPy and dependencies
///         alexabar_helper/          helper package
///         run_helper.py             entry point
enum HelperLocator {
    static var root: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("helper", isDirectory: true)
    }

    static var python: URL? {
        guard let u = root?.appendingPathComponent("python/bin/python3"),
              FileManager.default.isExecutableFile(atPath: u.path) else { return nil }
        return u
    }

    static var entryScript: URL? {
        guard let u = root?.appendingPathComponent("run_helper.py"),
              FileManager.default.fileExists(atPath: u.path) else { return nil }
        return u
    }

    static var caBundle: URL? {
        guard let u = root?.appendingPathComponent("site-packages/certifi/cacert.pem"),
              FileManager.default.fileExists(atPath: u.path) else { return nil }
        return u
    }
}
