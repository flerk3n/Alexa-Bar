import Foundation

/// Where the app is in its connect / sign-in lifecycle.
enum Phase: Equatable {
    case starting
    case signedOut
    case signingIn(url: URL?)
    case connecting
    case ready
    case failed(String)

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

/// Which page the panel shows.
enum Page: Equatable {
    case home
    case device(String)
    case settings
}

struct Toast: Identifiable, Equatable {
    enum Style { case info, success, error }
    let id = UUID()
    let message: String
    let style: Style
}
