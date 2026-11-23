import AppKit
import SwiftUI

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// A ScrollView as tall as its content, up to `maxHeight`.
struct FittingScrollView<Content: View>: View {
    var maxHeight: CGFloat
    @ViewBuilder var content: Content
    @ViewState private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView(.vertical) {
            content
                .background(GeometryReader { g in
                    Color.clear.preference(key: HeightKey.self, value: g.size.height)
                })
        }
        .scrollIndicators(contentHeight > maxHeight ? .automatic : .never)
        .frame(height: min(max(contentHeight, 40), maxHeight))
        .onPreferenceChange(HeightKey.self) { contentHeight = $0 }
    }
}

enum PanelMetrics {
    static var maxScrollHeight: CGFloat {
        let screen = NSScreen.main?.visibleFrame.height ?? 800
        return min(560, screen - 160)
    }
}
