import Foundation

/// An error from the helper (with its `code`) or from the process plumbing.
struct BackendError: LocalizedError, Equatable {
    let code: String
    let message: String

    var errorDescription: String? { message }

    var needsLogin: Bool { code == "need_login" }
    var isRateLimited: Bool { code == "rate_limited" }
    var isCancelled: Bool { code == "cancelled" }

    static func crashed(_ detail: String) -> BackendError {
        .init(code: "crashed", message: detail)
    }

    static let missingRuntime = BackendError(
        code: "missing_runtime",
        message: "Alexa Bar's helper is missing from the app. Please reinstall Alexa Bar."
    )

    static let stopped = BackendError(code: "stopped", message: "The helper was restarted.")
}
