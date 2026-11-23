import SwiftUI

struct DeviceContextMenu: View {
    @EnvironmentObject var model: AppModel
    let device: SmartDevice

    var body: some View {
        if device.canPower {
            Button("Turn On") { model.setPower(device, on: true) }
            Button("Turn Off") { model.setPower(device, on: false) }
        }
        if device.hasExtraControls {
            Button("More Controls…") { model.page = .device(device.id) }
        }
        Divider()
        Button("Hide from Menu Bar") { model.setHidden(device, true) }
    }
}
