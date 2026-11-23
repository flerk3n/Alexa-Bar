import SwiftUI

extension AppModel {
    func ask(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        echoCommand("ask", ["text": text], speaker: defaultSpeaker) { "Asked \($0): “\(text)”" }
    }

    func speak(_ text: String, on speaker: Speaker) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        echoCommand("speak", ["text": text], speaker: speaker) { "\($0) is speaking" }
    }

    func stop(_ speaker: Speaker) {
        echoCommand("stop", [:], speaker: speaker) { "Stopped \($0)" }
    }

    /// Volume changes are debounced here and coalesced in the helper, so
    /// fast slider moves don't trip Amazon's rate limit (HTTP 429).
    func setVolume(_ speaker: Speaker, _ value: Int) {
        let previous = volumes[speaker.serial]
        withAnimation(.snappy) {
            volumes[speaker.serial] = value
            pending.insert(speaker.serial)
        }
        debouncer.submit("volume:\(speaker.serial)") { [weak self] in
            guard let self else { return }
            Task {
                defer { self.pending.remove(speaker.serial) }
                do {
                    _ = try await self.backend.call("volume", ["serial": speaker.serial, "value": value],
                                                    as: EchoReply.self)
                } catch {
                    withAnimation(.snappy) { self.volumes[speaker.serial] = previous }
                    self.handleActionError(error, fallback: "Couldn't change the volume")
                }
            }
        }
    }

    private func echoCommand(_ cmd: String, _ args: [String: Any], speaker: Speaker?,
                             success: @escaping (String) -> String) {
        var args = args
        if let s = speaker?.serial { args["serial"] = s }
        let key = speaker?.serial ?? "ask"
        pending.insert(key)
        Task {
            defer { pending.remove(key) }
            do {
                let reply: EchoReply = try await backend.call(cmd, args)
                showToast(success(reply.echo ?? speaker?.name ?? "Alexa"), .success)
                if cmd == "ask" { scheduleFollowUp() }
            } catch {
                handleActionError(error, fallback: "Alexa didn't respond")
            }
        }
    }
}
