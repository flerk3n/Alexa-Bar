import SwiftUI

struct AskBar: View {
    @EnvironmentObject var model: AppModel
    @ViewState private var text = ""
    @FocusState private var focused: Bool

    private var busy: Bool { model.pending.contains(model.defaultSpeaker?.serial ?? "ask") }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.brand)
                .symbolEffect(.variableColor.iterative, isActive: busy)
            TextField("Ask Alexa…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($focused)
                .onSubmit(send)
            if !text.isEmpty {
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.brand)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .help("Send to \(model.defaultSpeaker?.name ?? "Alexa")")
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 34)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(focused ? Theme.alexaBlue.opacity(0.7) : Color.primary.opacity(0.07),
                              lineWidth: focused ? 1.5 : 1)
        )
        .animation(.snappy(duration: 0.2), value: text.isEmpty)
        .animation(.snappy(duration: 0.2), value: focused)
        .help("Type anything you'd say to Alexa, e.g. “turn off the lights in 10 minutes”")
    }

    private func send() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        model.ask(text)
        text = ""
    }
}
