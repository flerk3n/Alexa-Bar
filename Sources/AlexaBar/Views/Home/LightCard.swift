import SwiftUI

struct LightCard: View {
    @EnvironmentObject var model: AppModel
    let device: SmartDevice
    @ViewState private var hovering = false

    var body: some View {
        let on = model.isOn(device)
        let tint = model.tint(for: device)
        let reachable = model.isReachable(device)
        VStack(spacing: 10) {
            HStack(spacing: 11) {
                Button { model.toggle(device) } label: {
                    HStack(spacing: 11) {
                        IconBadge(symbol: device.symbol(on: on), tint: tint, isOn: on,
                                  pending: model.pending.contains(device.id))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Text(model.statusText(device))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(reachable ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
                                .contentTransition(.numericText())
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .disabled(!device.canPower)

                if device.hasExtraControls {
                    IconButton(symbol: "chevron.right", help: "More controls", size: 24) {
                        withAnimation(.snappy(duration: 0.3)) { model.page = .device(device.id) }
                    }
                }
            }
            if device.canDim {
                PillSlider(
                    value: Double(model.state(device).brightness ?? (on ? 100 : 0)) / 100,
                    tint: tint,
                    label: "\(device.name) brightness",
                    height: 26,
                    dimmed: !on,
                    onCommit: { model.setBrightness(device, Int(($0 * 100).rounded())) }
                )
                .opacity(reachable ? 1 : 0.5)
            }
        }
        .padding(12)
        .card(tint: tint, isOn: on, hovering: hovering)
        .onHover { hovering = $0 }
        .contextMenu { DeviceContextMenu(device: device) }
        .animation(.snappy(duration: 0.3), value: on)
    }
}
