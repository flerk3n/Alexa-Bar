import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @ViewState private var loginStatus = LaunchAtLogin.status
    @ViewState private var confirmSignOut = false

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Settings")
            Divider().opacity(0.5)
            FittingScrollView(maxHeight: PanelMetrics.maxScrollHeight) {
                VStack(alignment: .leading, spacing: 16) {
                    account
                    general
                    if !model.speakers.isEmpty { echo }
                    if !model.prefs.hiddenDevices.isEmpty && !hiddenList.isEmpty { hidden }
                    help
                    footer
                }
                .padding(14)
            }
        }
        .onAppear { loginStatus = LaunchAtLogin.status }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginStatus = LaunchAtLogin.status
        }
    }

    // MARK: - Account

    private var account: some View {
        SettingsGroup(title: "Account") {
            SettingsRow(symbol: "person.crop.circle.fill", tint: Theme.alexaBlue,
                        title: model.email.isEmpty ? "Not signed in" : model.email,
                        subtitle: model.domain.isEmpty ? nil : "\(model.region.flag) \(model.region.name) · \(model.domain)") {
                accountButton
            }
        }
    }

    @ViewBuilder
    private var accountButton: some View {
        if model.phase == .ready {
            if confirmSignOut {
                HStack(spacing: 4) {
                    Button("Cancel") { withAnimation { confirmSignOut = false } }
                        .controlSize(.small)
                    Button("Sign Out") { model.signOut() }
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            } else {
                Button("Sign Out…") { withAnimation { confirmSignOut = true } }
                    .controlSize(.small)
            }
        } else if model.phase == .signedOut || model.phase.isFailed {
            Button("Sign In") {
                model.phase = .signedOut
                withAnimation(.snappy(duration: 0.3)) { model.page = .home }
            }
            .controlSize(.small)
        }
    }

    // MARK: - General

    private var general: some View {
        SettingsGroup(title: "General") {
            SettingsRow(symbol: "power", tint: .green, title: "Open at login",
                        subtitle: loginStatus == .needsApproval ? "Waiting for approval in System Settings" : nil) {
                if loginStatus == .needsApproval {
                    Button("Open Settings") { LaunchAtLogin.openSystemSettings() }
                        .controlSize(.small)
                } else {
                    Toggle("", isOn: Binding(get: { loginStatus == .enabled }, set: setLaunchAtLogin))
                        .toggleStyle(.switch).labelsHidden().controlSize(.small)
                }
            }
            RowDivider()
            SettingsRow(symbol: "number", tint: .indigo, title: "Show count in menu bar",
                        subtitle: "Number of devices that are on") {
                Toggle("", isOn: Binding(get: { model.prefs.showOnCountInMenuBar },
                                         set: { model.prefs.showOnCountInMenuBar = $0 }))
                    .toggleStyle(.switch).labelsHidden().controlSize(.small)
            }
            RowDivider()
            SettingsRow(symbol: "arrow.triangle.2.circlepath", tint: .orange, title: "Refresh status") {
                Picker("", selection: Binding(get: { model.prefs.refreshInterval },
                                              set: { model.setRefreshInterval($0) })) {
                    ForEach(Preferences.refreshChoices, id: \.seconds) { Text("Every \($0.label)").tag($0.seconds) }
                }
                .labelsHidden()
                .fixedSize()
                .controlSize(.small)
            }
        }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        model.prefs.hasOfferedLaunchAtLogin = true
        model.showLaunchAtLoginOffer = false
        do {
            try LaunchAtLogin.set(on)
        } catch {
            model.showToast("Couldn't change the login item. \(error.localizedDescription)", .error)
        }
        loginStatus = LaunchAtLogin.status
        if loginStatus == .needsApproval { LaunchAtLogin.openSystemSettings() }
    }

    // MARK: - Echo

    private var echo: some View {
        SettingsGroup(title: "Echo") {
            SettingsRow(symbol: "waveform", tint: Theme.speakerTint,
                        title: "Voice speaker", subtitle: "Ask Alexa & voice fallback") {
                Picker("", selection: Binding(get: { model.defaultSpeaker?.serial ?? "" },
                                              set: { model.prefs.defaultEchoSerial = $0 })) {
                    ForEach(model.speakers) { Text($0.name).tag($0.serial) }
                }
                .labelsHidden()
                .fixedSize()
                .controlSize(.small)
            }
            RowDivider()
            SettingsRow(symbol: "hifispeaker.2.fill", tint: .purple, title: "Show Echo speakers") {
                Toggle("", isOn: Binding(get: { model.prefs.showSpeakers }, set: { model.prefs.showSpeakers = $0 }))
                    .toggleStyle(.switch).labelsHidden().controlSize(.small)
            }
        }
    }

    // MARK: - Hidden devices

    private var hiddenList: [SmartDevice] {
        model.devices.filter { model.prefs.hiddenDevices.contains($0.id) }
    }

    private var hidden: some View {
        SettingsGroup(title: "Hidden devices") {
            ForEach(Array(hiddenList.enumerated()), id: \.element.id) { i, d in
                if i > 0 { RowDivider() }
                SettingsRow(symbol: d.symbol(on: true), tint: .gray, title: d.name) {
                    Button("Show") { model.setHidden(d, false) }
                        .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Help

    private var help: some View {
        SettingsGroup(title: "Help") {
            SettingsRow(symbol: "doc.text.magnifyingglass", tint: .gray, title: "Logs",
                        subtitle: "For troubleshooting. Contains no passwords.") {
                Button("Show in Finder") {
                    AppPaths.ensure()
                    let log = AppPaths.helperLog
                    if FileManager.default.fileExists(atPath: log.path) {
                        NSWorkspace.shared.activateFileViewerSelecting([log])
                    } else {
                        NSWorkspace.shared.open(AppPaths.logsDirectory)
                    }
                }
                .controlSize(.small)
            }
            RowDivider()
            SettingsRow(symbol: "arrow.counterclockwise", tint: .gray, title: "Reconnect",
                        subtitle: "Restarts the connection to Amazon") {
                Button("Reconnect") { model.restartHelper() }
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                AlexaGlyph(size: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Alexa Bar \(Bundle.main.shortVersion)")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Not affiliated with Amazon. Uses Alexa's web service, which Amazon may change at any time.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 8) {
                FooterButton(title: "About", symbol: "info.circle") { AboutPanel.show() }
                FooterButton(title: "Quit", symbol: "power") { NSApp.terminate(nil) }
                    .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }
}

private struct FooterButton: View {
    let title: String
    let symbol: String
    let action: () -> Void
    @ViewState private var hovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.11 : 0.07)))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }
}
