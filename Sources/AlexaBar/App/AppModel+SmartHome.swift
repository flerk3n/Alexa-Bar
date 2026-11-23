import SwiftUI

extension AppModel {
    func toggle(_ d: SmartDevice) {
        setPower(d, on: !isOn(d))
    }

    func setPower(_ d: SmartDevice, on: Bool) {
        control(d, params: ["action": on ? "turnOn" : "turnOff"],
                phrase: "turn \(on ? "on" : "off") \(d.name)") { $0.on = on }
    }

    func setBrightness(_ d: SmartDevice, _ pct: Int) {
        let pct = min(max(pct, 1), 100)
        applyOptimistic(d) {
            $0.on = true
            $0.brightness = pct
        }
        debouncer.submit("brightness:\(d.id)") { [weak self] in
            self?.control(d, params: ["action": "setBrightness", "brightness": String(pct)],
                          phrase: "set \(d.name) to \(pct) percent") {
                $0.on = true
                $0.brightness = pct
            }
        }
    }

    func setColor(_ d: SmartDevice, _ preset: ColorPreset) {
        control(d, params: ["action": "setColor", "colorName": preset.id],
                phrase: "set \(d.name) to \(preset.label.lowercased())") {
            $0.on = true
            $0.colorName = preset.id
            $0.colorLabel = preset.label
        }
    }

    func setWhite(_ d: SmartDevice, _ preset: WhitePreset) {
        control(d, params: ["action": "setColorTemperature", "colorTemperatureName": preset.id],
                phrase: "set \(d.name) to \(preset.label.lowercased()) white") {
            $0.on = true
            $0.colorName = preset.id
            $0.colorLabel = preset.label + " White"
            $0.kelvin = preset.kelvin
            $0.color = nil
        }
    }

    func allOff(_ list: [SmartDevice]) {
        for d in list where isOn(d) && d.canPower { setPower(d, on: false) }
    }

    private func applyOptimistic(_ d: SmartDevice, _ change: (inout DeviceState) -> Void) {
        var st = states[d.id] ?? DeviceState()
        change(&st)
        withAnimation(.snappy(duration: 0.25)) { states[d.id] = st }
    }

    /// Update the UI immediately, send the command, and roll back on failure.
    private func control(_ d: SmartDevice, params: [String: String], phrase: String,
                         optimistic: (inout DeviceState) -> Void) {
        let before = states[d.id] ?? DeviceState()
        var after = before
        optimistic(&after)
        withAnimation(.snappy(duration: 0.25)) {
            states[d.id] = after
            pending.insert(d.id)
        }
        Task {
            defer { withAnimation(.snappy) { _ = pending.remove(d.id) } }
            do {
                var args: [String: Any] = ["id": d.id, "params": params, "phrase": phrase]
                if let s = defaultSpeaker?.serial { args["serial"] = s }
                let reply: ControlReply = try await backend.call("control", args)
                if reply.skipped == true { return }
                if reply.via == "voice" {
                    showToast("Sent to \(d.name) through your Echo", .info)
                }
                scheduleFollowUp()
            } catch {
                withAnimation(.snappy) { states[d.id] = before }
                handleActionError(error, fallback: "Couldn't control \(d.name)")
            }
        }
    }
}
