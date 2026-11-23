import SwiftUI

struct HomeView: View {
    @EnvironmentObject var model: AppModel

    private let grid = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            PanelHeader()
            if !model.speakers.isEmpty {
                AskBar()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }
            if model.isOffline {
                OfflineBanner()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Divider().opacity(0.5)
            FittingScrollView(maxHeight: PanelMetrics.maxScrollHeight) {
                VStack(alignment: .leading, spacing: 16) {
                    if model.showLaunchAtLoginOffer {
                        LaunchAtLoginBanner()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if model.visibleDevices.isEmpty && (model.speakers.isEmpty || !model.prefs.showSpeakers) {
                        EmptyDevicesView()
                    }
                    if !model.lights.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Lights", count: model.lights.count) {
                                if model.lights.contains(where: model.isOn) {
                                    LinkButton(title: "Turn all off") { model.allOff(model.lights) }
                                }
                            }
                            ForEach(model.lights) { LightCard(device: $0) }
                        }
                    }
                    if !model.others.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Plugs & Switches", count: model.others.count) {
                                if model.others.contains(where: model.isOn) {
                                    LinkButton(title: "Turn all off") { model.allOff(model.others) }
                                }
                            }
                            LazyVGrid(columns: grid, spacing: 10) {
                                ForEach(model.others) { DeviceTile(device: $0) }
                            }
                        }
                    }
                    if model.prefs.showSpeakers && !model.speakers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Echo", count: model.speakers.count)
                            ForEach(model.speakers) { SpeakerCard(speaker: $0) }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
            Divider().opacity(0.5)
            PanelFooter()
        }
    }
}
