import AppKit
import SwiftUI

extension Color {
    /// True for pale colours (cool white, yellow) where white text is hard to read.
    var isPale: Bool {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return false }
        let luminance = 0.2126 * c.redComponent + 0.7152 * c.greenComponent + 0.0722 * c.blueComponent
        return luminance > 0.72
    }

    /// Foreground for glyphs and text drawn on this colour.
    var onColor: Color { isPale ? Color.black.opacity(0.68) : .white }
}
