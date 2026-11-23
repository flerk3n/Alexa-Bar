import Foundation
import Network

/// Reports when the Mac goes offline or comes back online.
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "AlexaBar.network")
    private(set) var isOnline = true

    /// Called on the main queue when connectivity changes.
    var onChange: ((Bool) -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            DispatchQueue.main.async {
                guard let self, online != self.isOnline else { return }
                self.isOnline = online
                self.onChange?(online)
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
