import AppKit
import SwiftUI

@main
struct AlexaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environmentObject(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Icon (plus optional count of devices that are on) in the menu bar.
private struct MenuBarLabel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let on = model.onCount
        HStack(spacing: 3) {
            Image(nsImage: MenuBarIcon.image(active: on > 0, dimmed: model.phase != .ready))
            if model.prefs.showOnCountInMenuBar && on > 0 {
                Text("\(on)")
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(on > 0 ? "Alexa, \(on) on" : "Alexa")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        if !SingleInstance.claim() {
            Log.app.notice("another instance is running; exiting")
            exit(0)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Log.app.info("Alexa Bar \(Bundle.main.shortVersion, privacy: .public) (\(Bundle.main.buildNumber, privacy: .public)) started")
    }
}
