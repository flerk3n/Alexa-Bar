import SwiftUI

struct DeviceTile: View {
    @EnvironmentObject var model: AppModel
    let device: SmartDevice
    @ViewState private var hovering = false

    var body: some View {
        let on = model.isOn(device)
        let tint = model.tint(for: device)
        Button { model.toggle(device) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    IconBadge(symbol: device.symbol(on: on), tint: tint, isOn: on,
                              pending: model.pending.contains(device.id), size: 32)
                    Spacer()
                    PowerDot(on: on, tint: tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 12.5, weight: .semibold))
                        .lineLimit(1)
                    Text(model.statusText(device))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(model.isReachable(device) ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
                        .lineLimit(1)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(tint: tint, isOn: on, hovering: hovering)
            .contentShape(RoundedRectangle(cornerRadius: Theme.corner))
        }
        .buttonStyle(PressableStyle())
        .disabled(!device.canPower)
        .onHover { hovering = $0 }
        .contextMenu { DeviceContextMenu(device: device) }
        .help(device.subtitle)
    }
}
