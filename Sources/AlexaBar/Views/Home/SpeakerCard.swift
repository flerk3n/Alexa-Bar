import SwiftUI

struct SpeakerCard: View {
    @EnvironmentObject var model: AppModel
    let speaker: Speaker
    @ViewState private var speaking = false
    @ViewState private var phrase = ""
    @ViewState private var hovering = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        let volume = model.volumes[speaker.serial]
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                IconBadge(symbol: speaker.symbol, tint: Theme.speakerTint, isOn: speaker.online,
                          pending: model.pending.contains(speaker.serial))
                VStack(alignment: .leading, spacing: 2) {
                    Text(speaker.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(speaker.online ? (volume.map { "Online · Volume \($0)%" } ?? "Online") : "Offline")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                if speaker.serial == model.defaultSpeaker?.serial && model.speakers.count > 1 {
                    Text("DEFAULT")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Theme.speakerTint)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Theme.speakerTint.opacity(0.15)))
                }
            }
            if speaker.online && speaker.canVolume {
                PillSlider(
                    value: Double(volume ?? 0) / 100,
                    tint: Theme.speakerTint,
                    label: "\(speaker.name) volume",
                    height: 26,
                    leading: volumeSymbol(volume ?? 0),
                    dimmed: !speaker.online,
                    minimum: 0,
                    onCommit: { model.setVolume(speaker, Int(($0 * 100).rounded())) }
                )
            }
            if speaker.online && speaking {
                HStack(spacing: 6) {
                    TextField("Make \(speaker.name) say…", text: $phrase)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12.5))
                        .focused($fieldFocused)
                        .onSubmit(say)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.07)))
                    ChipButton(title: "Say", symbol: "paperplane.fill", tint: Theme.speakerTint, prominent: true, action: say)
                        .disabled(phrase.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if speaker.online {
            HStack(spacing: 6) {
                ChipButton(title: speaking ? "Close" : "Speak", symbol: speaking ? "xmark" : "text.bubble.fill") {
                    withAnimation(.snappy(duration: 0.25)) { speaking.toggle() }
                    if speaking { DispatchQueue.main.async { fieldFocused = true } }
                }
                ChipButton(title: "Stop", symbol: "stop.fill") { model.stop(speaker) }
                Spacer()
            }
            }
        }
        .padding(12)
        .card(tint: Theme.speakerTint, isOn: false, hovering: hovering)
        .onHover { hovering = $0 }
        .opacity(speaker.online ? 1 : 0.6)
        .contextMenu {
            Button("Use for “Ask Alexa”") { model.prefs.defaultEchoSerial = speaker.serial }
        }
    }

    private func volumeSymbol(_ v: Int) -> String {
        switch v {
        case 0: return "speaker.slash.fill"
        case 1..<34: return "speaker.wave.1.fill"
        case 34..<67: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    private func say() {
        let p = phrase.trimmingCharacters(in: .whitespaces)
        guard !p.isEmpty else { return }
        model.speak(p, on: speaker)
        phrase = ""
    }
}
