import SwiftUI

struct DeviceDetailView: View {
    @EnvironmentObject var model: AppModel
    let device: SmartDevice

    var body: some View {
        let st = model.state(device)
        let on = st.on == true
        let tint = model.tint(for: device)

        VStack(spacing: 0) {
            PageHeader(title: device.name, subtitle: device.subtitle) {
                if device.canPower {
                    Toggle("", isOn: Binding(get: { on }, set: { model.setPower(device, on: $0) }))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .tint(tint)
                        .padding(.trailing, 6)
                }
            }
            Divider().opacity(0.5)

            FittingScrollView(maxHeight: PanelMetrics.maxScrollHeight) {
                VStack(alignment: .leading, spacing: 18) {
                    hero(on: on, tint: tint, st: st)

                    if device.canDim {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Brightness")
                            PillSlider(
                                value: Double(st.brightness ?? (on ? 100 : 0)) / 100,
                                tint: tint, label: "Brightness", height: 40, dimmed: !on,
                                onCommit: { model.setBrightness(device, Int(($0 * 100).rounded())) }
                            )
                            HStack(spacing: 6) {
                                ForEach([10, 25, 50, 75, 100], id: \.self) { pct in
                                    QuickChip(label: "\(pct)%",
                                              selected: on && st.brightness == pct) {
                                        model.setBrightness(device, pct)
                                    }
                                }
                            }
                        }
                    }

                    if device.canWhite {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "White")
                            HStack(spacing: 0) {
                                ForEach(WhitePreset.all) { p in
                                    Swatch(color: p.color, label: p.label,
                                           selected: on && st.colorName == p.id, size: 34) {
                                        model.setWhite(device, p)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }

                    if device.canColor {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Colour")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                                      spacing: 12) {
                                ForEach(ColorPreset.all) { p in
                                    Swatch(color: p.color, label: nil,
                                           selected: on && st.colorName == p.id, size: 32) {
                                        model.setColor(device, p)
                                    }
                                    .help(p.label)
                                    .accessibilityLabel(p.label)
                                }
                            }
                        }
                    }

                    HStack {
                        Label(device.isLight ? "Light" : AppModel.prettyName(device.kind), systemImage: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        LinkButton(title: "Hide from menu bar") {
                            model.setHidden(device, true)
                            withAnimation(.snappy(duration: 0.3)) { model.page = .home }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(14)
            }
        }
    }

    private func heroTitle(on: Bool, st: DeviceState) -> String {
        if !model.isReachable(device) { return "Not responding" }
        guard let isOn = st.on else { return "Unknown" }
        guard isOn else { return "Off" }
        if device.canDim, let b = st.brightness { return "On · \(b)%" }
        return "On"
    }

    private func heroDetail(on: Bool, st: DeviceState) -> String? {
        guard on else { return nil }
        var parts: [String] = []
        if let label = st.colorLabel ?? st.colorName.map(AppModel.prettyName) { parts.append(label) }
        if let k = st.kelvin, st.isWhite { parts.append("\(k) K") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Big glowing icon showing the light's current colour.
    @ViewBuilder
    private func hero(on: Bool, tint: Color, st: DeviceState) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(on ? tint.opacity(0.28) : Color.primary.opacity(0.05))
                    .frame(width: 74, height: 74)
                    .blur(radius: on ? 8 : 0)
                IconBadge(symbol: device.symbol(on: on), tint: tint, isOn: on,
                          pending: model.pending.contains(device.id), size: 56)
            }
            .onTapGesture { model.toggle(device) }
            VStack(alignment: .leading, spacing: 4) {
                Text(heroTitle(on: on, st: st))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                if let detail = heroDetail(on: on, st: st) {
                    Text(detail)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(model.isReachable(device) ? "Click the bulb to toggle" : "Check the device's power and Wi‑Fi")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(14)
        .card(tint: tint, isOn: on)
        .animation(.snappy(duration: 0.35), value: on)
    }
}
