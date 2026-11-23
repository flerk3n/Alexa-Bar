import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(width: Theme.panelWidth)
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                ToastView(toast: toast)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture { withAnimation { model.toast = nil } }
                    .id(toast.id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            model.panelOpened()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.page {
        case .settings:
            SettingsView()
                .transition(.push(from: .trailing))
        case .device(let id):
            if model.phase == .ready, let d = model.device(id) {
                DeviceDetailView(device: d)
                    .transition(.push(from: .trailing))
            } else {
                main
            }
        case .home:
            main
        }
    }

    @ViewBuilder
    private var main: some View {
        if model.phase == .ready {
            HomeView()
                .transition(.push(from: .leading))
        } else {
            StatusScreens()
                .transition(.opacity)
        }
    }
}
