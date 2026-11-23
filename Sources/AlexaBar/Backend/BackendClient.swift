import Foundation

/// Runs the bundled Python helper and exchanges JSON lines with it.
@MainActor
final class BackendClient {
    private var process: Process?
    private var stdinHandle: FileHandle?
    private var buffer = Data()
    private var nextID = 1
    private var pending: [Int: CheckedContinuation<Data, Error>] = [:]
    private var stderrTail: [String] = []
    private let logFile = HelperLogFile()

    /// Unsolicited messages such as `{"event": "login_url", ...}`.
    var onEvent: (([String: Any]) -> Void)?
    /// Called when the helper exits without being asked to.
    var onUnexpectedExit: ((String) -> Void)?

    var isRunning: Bool { process?.isRunning == true }

    func start() throws {
        guard !isRunning else { return }
        guard let python = HelperLocator.python, let script = HelperLocator.entryScript else {
            throw BackendError.missingRuntime
        }
        AppPaths.ensure()

        let p = Process()
        p.executableURL = python
        // -I isolated (ignore user Python config), -B no .pyc writes into the signed bundle, -u unbuffered
        p.arguments = ["-I", "-B", "-u", script.path]
        p.currentDirectoryURL = AppPaths.dataDirectory
        var env = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("PYTHON") }
        env["ALEXABAR_DATA_DIR"] = AppPaths.dataDirectory.path
        if let ca = HelperLocator.caBundle { env["SSL_CERT_FILE"] = ca.path }
        p.environment = env

        let inPipe = Pipe(), outPipe = Pipe(), errPipe = Pipe()
        p.standardInput = inPipe
        p.standardOutput = outPipe
        p.standardError = errPipe

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            DispatchQueue.main.async { self?.receive(data) }
        }
        let logFile = self.logFile
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty else { return }
            logFile.append(data)
            let text = String(decoding: data, as: UTF8.self)
            DispatchQueue.main.async { self?.remember(text) }
        }
        p.terminationHandler = { [weak self] proc in
            let status = proc.terminationStatus
            DispatchQueue.main.async { self?.handleExit(proc, status: status) }
        }

        logFile.writeMarker("helper starting (app \(Bundle.main.shortVersion))")
        try p.run()
        process = p
        stdinHandle = inPipe.fileHandleForWriting
        buffer.removeAll()
        Log.helper.info("helper started, pid \(p.processIdentifier)")
    }

    /// Ask the helper to save its session and exit; force it after a moment.
    func stop() {
        guard let p = process else { return }
        process = nil
        try? stdinHandle?.close()
        stdinHandle = nil
        let deadline = Date().addingTimeInterval(1.5)
        while p.isRunning && Date() < deadline { usleep(50_000) }
        if p.isRunning { p.terminate() }
        failAll(BackendError.stopped)
    }

    /// Send a command and decode its `result`.
    func call<T: Decodable>(_ cmd: String, _ args: [String: Any] = [:], as type: T.Type = T.self) async throws -> T {
        if !isRunning { try start() }
        let id = nextID
        nextID += 1
        let line = try JSONSerialization.data(withJSONObject: ["id": id, "cmd": cmd, "args": args]) + Data([0x0A])
        let data: Data = try await withCheckedThrowingContinuation { cont in
            pending[id] = cont
            do {
                guard let stdinHandle else { throw BackendError.stopped }
                try stdinHandle.write(contentsOf: line)
            } catch {
                pending.removeValue(forKey: id)
                cont.resume(throwing: BackendError.crashed("Couldn't reach Alexa Bar's helper."))
            }
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Plumbing

    private func receive(_ data: Data) {
        guard !data.isEmpty else { return }
        buffer.append(data)
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<nl]
            buffer.removeSubrange(buffer.startIndex...nl)
            guard !line.isEmpty,
                  let obj = try? JSONSerialization.jsonObject(with: line) as? [String: Any]
            else { continue }
            dispatch(obj)
        }
    }

    private func dispatch(_ obj: [String: Any]) {
        guard let id = obj["id"] as? Int else {
            onEvent?(obj)
            return
        }
        guard let cont = pending.removeValue(forKey: id) else { return }
        if obj["ok"] as? Bool == true {
            let result = obj["result"] ?? [String: Any]()
            let data = (try? JSONSerialization.data(withJSONObject: result)) ?? Data("{}".utf8)
            cont.resume(returning: data)
        } else {
            cont.resume(throwing: BackendError(
                code: obj["code"] as? String ?? "error",
                message: obj["error"] as? String ?? "Something went wrong."
            ))
        }
    }

    private func remember(_ text: String) {
        stderrTail.append(contentsOf: text.split(separator: "\n").map(String.init))
        if stderrTail.count > 50 { stderrTail.removeFirst(stderrTail.count - 50) }
    }

    private func handleExit(_ proc: Process, status: Int32) {
        guard proc === process else { return }  // stop() already handled it
        process = nil
        stdinHandle = nil
        Log.helper.error("helper exited with status \(status)")
        logFile.writeMarker("helper exited with status \(status)")
        let message = "Alexa Bar's helper stopped unexpectedly (code \(status))."
        failAll(BackendError.crashed(message))
        onUnexpectedExit?(message)
    }

    private func failAll(_ error: Error) {
        let conts = pending
        pending.removeAll()
        conts.values.forEach { $0.resume(throwing: error) }
    }
}

extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
