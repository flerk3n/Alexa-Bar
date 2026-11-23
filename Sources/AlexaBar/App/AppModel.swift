import AppKit
import Combine
import SwiftUI

/// All app state. Views read it; actions live in the extensions
/// (Account, SmartHome, Echo).
@MainActor
final class AppModel: ObservableObject {
    // Connection
    @Published var phase: Phase = .starting
    @Published var email = ""
    @Published var domain = ""
    @Published var isOffline = false

    // Data
    @Published var devices: [SmartDevice] = []
    @Published var speakers: [Speaker] = []
    @Published var states: [String: DeviceState] = [:]
    @Published var volumes: [String: Int] = [:]
    @Published var pending: Set<String> = []
    @Published var lastUpdated: Date?
    @Published var isRefreshing = false

    // UI
    @Published var page: Page = .home
    @Published var toast: Toast?
    @Published var showLaunchAtLoginOffer = false

    let prefs: Preferences
    let backend = BackendClient()
    let debouncer = Debouncer()
    private let network = NetworkMonitor()
    private var pollTimer: Timer?
    private var toastTask: Task<Void, Never>?
    private var followUp: Task<Void, Never>?
    private var crashTimes: [Date] = []
    private var observers: [NSObjectProtocol] = []
    private var prefsSink: AnyCancellable?

    init(prefs: Preferences = Preferences()) {
        self.prefs = prefs
        prefsSink = prefs.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        backend.onEvent = { [weak self] event in self?.handle(event: event) }
        backend.onUnexpectedExit = { [weak self] message in self?.helperCrashed(message) }
        network.onChange = { [weak self] online in self?.networkChanged(online) }
        network.start()
        observe()
        Task { await boot() }
    }

    // MARK: - Derived

    var visibleDevices: [SmartDevice] { devices.filter { !prefs.hiddenDevices.contains($0.id) } }
    var lights: [SmartDevice] { visibleDevices.filter(\.isLight) }
    var others: [SmartDevice] { visibleDevices.filter { !$0.isLight } }
    var onCount: Int { visibleDevices.filter(isOn).count }
    var region: AmazonRegion { AmazonRegion.named(domain) }

    var defaultSpeaker: Speaker? {
        speakers.first { $0.serial == prefs.defaultEchoSerial }
            ?? speakers.first(where: \.online) ?? speakers.first
    }

    func state(_ d: SmartDevice) -> DeviceState { states[d.id] ?? DeviceState() }
    func isOn(_ d: SmartDevice) -> Bool { states[d.id]?.on == true }
    func isReachable(_ d: SmartDevice) -> Bool { d.available && states[d.id]?.reachable != false }
    func device(_ id: String) -> SmartDevice? { devices.first { $0.id == id } }

    // MARK: - Lifecycle

    func boot() async {
        phase = .starting
        do {
            try backend.start()
            let hello: HelloReply = try await backend.call("hello")
            email = hello.email
            domain = hello.domain.isEmpty ? AmazonRegion.guess.id : hello.domain
            if hello.email.isEmpty || !hello.hasSession {
                phase = .signedOut
            } else {
                await connect()
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func connect() async {
        phase = .connecting
        do {
            let acct: AccountReply = try await backend.call("connect")
            email = acct.email
            domain = acct.domain
            try await loadEverything()
            becameReady()
        } catch let e as BackendError where e.needsLogin {
            phase = .signedOut
        } catch {
            phase = isOffline ? .failed("You're offline. Alexa Bar will reconnect when your Mac is back online.")
                              : .failed(error.localizedDescription)
        }
    }

    func becameReady() {
        phase = .ready
        schedulePolling()
        if !prefs.hasOfferedLaunchAtLogin && !LaunchAtLogin.isEnabled {
            showLaunchAtLoginOffer = true
        }
    }

    func retry() {
        Task {
            if backend.isRunning, !email.isEmpty { await connect() } else { await boot() }
        }
    }

    func restartHelper() {
        backend.stop()
        Task { await boot() }
    }

    private func helperCrashed(_ message: String) {
        pollTimer?.invalidate()
        let now = Date()
        crashTimes = crashTimes.filter { now.timeIntervalSince($0) < 120 } + [now]
        if crashTimes.count <= 3 {
            Log.app.notice("helper crashed, restarting (\(self.crashTimes.count))")
            Task { await boot() }
        } else {
            phase = .failed(message)
        }
    }

    // MARK: - System events

    private func observe() {
        let ws = NSWorkspace.shared.notificationCenter
        observers.append(ws.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.didWake() }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.backend.stop() }
        })
    }

    private func didWake() {
        Task {
            try? await Task.sleep(for: .seconds(3))  // give Wi-Fi a moment
            if phase == .ready { await refreshStates() } else if phase.isFailed { retry() }
        }
    }

    private func networkChanged(_ online: Bool) {
        withAnimation(.snappy) { isOffline = !online }
        guard online else { return }
        if phase == .ready { Task { await refreshStates() } } else if phase.isFailed { retry() }
    }

    // MARK: - Loading

    func loadEverything() async throws {
        let list: DeviceList = try await backend.call("devices")
        withAnimation(.snappy) {
            devices = list.devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            speakers = list.speakers.sorted {
                $0.online != $1.online ? $0.online : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        await refreshStates()
    }

    func refresh() {
        guard phase == .ready, !isRefreshing else { return }
        Task {
            isRefreshing = true
            defer { isRefreshing = false }
            do {
                try await loadEverything()
            } catch {
                handleActionError(error, fallback: "Couldn't refresh")
            }
        }
    }

    func refreshStates() async {
        let ids = devices.map(\.id)
        let wantVolumes = !speakers.isEmpty && prefs.showSpeakers
        let backend = self.backend
        async let s: StatesReply? = ids.isEmpty ? nil : try? backend.call("states", ["ids": ids])
        async let v: VolumesReply? = wantVolumes ? try? backend.call("volumes") : nil
        let (states, vols) = await (s, v)
        withAnimation(.snappy) {
            for (id, st) in states?.states ?? [:] where !pending.contains(id) {
                self.states[id] = st
            }
            for (serial, info) in vols?.volumes ?? [:] where !pending.contains(serial) {
                if let vol = info.volume { volumes[serial] = vol }
            }
        }
        if states != nil || ids.isEmpty { lastUpdated = Date() }
    }

    /// Called when the menu bar panel opens.
    func panelOpened() {
        guard phase == .ready else { return }
        if let last = lastUpdated, Date().timeIntervalSince(last) < 8 { return }
        Task { await refreshStates() }
    }

    func schedulePolling() {
        pollTimer?.invalidate()
        guard phase == .ready else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: max(15, prefs.refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .ready, !self.isOffline else { return }
                await self.refreshStates()
            }
        }
        pollTimer?.tolerance = 5
    }

    /// Read states back shortly after a command, once Amazon has caught up.
    func scheduleFollowUp() {
        followUp?.cancel()
        followUp = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            await refreshStates()
        }
    }

    // MARK: - Errors & toasts

    func handleActionError(_ error: Error, fallback: String) {
        if let e = error as? BackendError {
            if e.needsLogin {
                phase = .signedOut
                showToast("Your Amazon session expired. Please sign in again.", .error)
                return
            }
            if e.isRateLimited {
                showToast(e.message, .error)
                return
            }
        }
        if isOffline {
            showToast("You're offline.", .error)
            return
        }
        let detail = error.localizedDescription
        showToast(detail.isEmpty ? fallback : "\(fallback). \(detail)", .error)
    }

    func showToast(_ message: String, _ style: Toast.Style = .info) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.35)) { toast = Toast(message: message, style: style) }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(style == .error ? 4.5 : 2.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }

    // MARK: - Visibility & preferences

    func setHidden(_ d: SmartDevice, _ hidden: Bool) {
        withAnimation(.snappy) {
            if hidden { prefs.hiddenDevices.insert(d.id) } else { prefs.hiddenDevices.remove(d.id) }
        }
    }

    func setRefreshInterval(_ seconds: Double) {
        prefs.refreshInterval = seconds
        schedulePolling()
    }

    func answerLaunchAtLoginOffer(_ enable: Bool) {
        prefs.hasOfferedLaunchAtLogin = true
        withAnimation(.snappy) { showLaunchAtLoginOffer = false }
        guard enable else { return }
        do {
            try LaunchAtLogin.set(true)
            if LaunchAtLogin.status == .needsApproval {
                showToast("Allow Alexa Bar in System Settings › Login Items.", .info)
                LaunchAtLogin.openSystemSettings()
            } else {
                showToast("Alexa Bar will open when you log in.", .success)
            }
        } catch {
            showToast("Couldn't add the login item. \(error.localizedDescription)", .error)
        }
    }
}
