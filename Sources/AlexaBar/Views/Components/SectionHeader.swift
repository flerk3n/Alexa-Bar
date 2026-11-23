import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let title: String
    var count: Int?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            if let count {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, 4)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, count: Int? = nil) {
        self.init(title: title, count: count) { EmptyView() }
    }
}
