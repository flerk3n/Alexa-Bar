import AppKit
import SwiftUI

enum AlexaLogo {
    /// Ring with a speech-bubble tail, in a y-down square of side `s`.
    static func path(side s: CGFloat) -> CGPath {
        let c = CGPoint(x: 0.54 * s, y: 0.44 * s)
        let r = 0.36 * s
        let lw = 0.14 * s
        let ring = CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r), transform: nil)
            .copy(strokingWithWidth: lw, lineCap: .round, lineJoin: .round, miterLimit: 4)
        func onRing(_ deg: CGFloat) -> CGPoint {
            let a = deg * .pi / 180
            return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
        }
        let tail = CGMutablePath()
        tail.move(to: onRing(98))
        tail.addLine(to: CGPoint(x: 0.07 * s, y: 0.95 * s))
        tail.addLine(to: onRing(165))
        tail.closeSubpath()
        return ring.union(tail)
    }
}

struct AlexaLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        var t = CGAffineTransform(translationX: rect.midX - s / 2, y: rect.midY - s / 2)
        return Path(AlexaLogo.path(side: s).copy(using: &t) ?? AlexaLogo.path(side: s))
    }
}

/// The brand mark: gradient ring logo, optionally on a soft glow.
struct AlexaGlyph: View {
    var size: CGFloat = 28
    var glow = false

    var body: some View {
        AlexaLogoShape()
            .fill(Theme.brand)
            .frame(width: size, height: size)
            .shadow(color: glow ? Theme.alexaBlue.opacity(0.55) : .clear, radius: size * 0.35)
    }
}
