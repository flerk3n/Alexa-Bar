import Foundation

/// Runs only the last action submitted for a key within `delay`.
/// Used for sliders so a burst of changes becomes one request.
@MainActor
final class Debouncer {
    private var tasks: [String: Task<Void, Never>] = [:]
    private let delay: Duration

    init(delay: Duration = .milliseconds(350)) {
        self.delay = delay
    }

    func submit(_ key: String, _ action: @escaping @MainActor () -> Void) {
        tasks[key]?.cancel()
        tasks[key] = Task { [delay] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
