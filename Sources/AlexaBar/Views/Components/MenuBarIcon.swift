import AppKit

enum MenuBarIcon {
    /// Template image for the status item. `active` adds a dot when something is on.
    static func image(active: Bool, dimmed: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: true) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let s: CGFloat = 16
            ctx.translateBy(x: (rect.width - s) / 2, y: (rect.height - s) / 2 + 0.5)
            ctx.setFillColor(NSColor.black.withAlphaComponent(dimmed ? 0.45 : 1).cgColor)
            ctx.addPath(AlexaLogo.path(side: s))
            ctx.fillPath()
            if active {
                let c = CGPoint(x: 0.54 * s, y: 0.44 * s)
                let d: CGFloat = 0.30 * s
                ctx.fillEllipse(in: CGRect(x: c.x - d / 2, y: c.y - d / 2, width: d, height: d))
            }
            return true
        }
        img.isTemplate = true
        return img
    }
}
