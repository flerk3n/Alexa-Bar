// Renders the app icon PNGs into an .iconset folder.
// Usage: swift scripts/make_icon.swift <output.iconset>
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func logoPath(side s: CGFloat) -> CGPath {
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

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    let S = CGFloat(px)
    // flip to y-down to match the logo geometry
    cg.translateBy(x: 0, y: S)
    cg.scaleBy(x: 1, y: -1)

    // macOS icon grid: ~10% margin, squircle body
    let inset = S * 0.1
    let body = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
    let squircle = CGPath(roundedRect: body, cornerWidth: body.width * 0.225, cornerHeight: body.width * 0.225, transform: nil)

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: S * 0.012), blur: S * 0.03,
                 color: NSColor.black.withAlphaComponent(0.35).cgColor)
    cg.addPath(squircle)
    cg.setFillColor(NSColor.black.cgColor)
    cg.fillPath()
    cg.restoreGState()

    cg.saveGState()
    cg.addPath(squircle)
    cg.clip()
    let space = CGColorSpaceCreateDeviceRGB()
    let bg = CGGradient(colorsSpace: space, colors: [
        NSColor(red: 0.05, green: 0.09, blue: 0.20, alpha: 1).cgColor,
        NSColor(red: 0.02, green: 0.04, blue: 0.10, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(bg, start: CGPoint(x: body.minX, y: body.minY), end: CGPoint(x: body.maxX, y: body.maxY), options: [])
    // soft glow behind the ring
    let glow = CGGradient(colorsSpace: space, colors: [
        NSColor(red: 0.0, green: 0.66, blue: 0.88, alpha: 0.55).cgColor,
        NSColor(red: 0.0, green: 0.66, blue: 0.88, alpha: 0).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawRadialGradient(glow, startCenter: CGPoint(x: S * 0.52, y: S * 0.46), startRadius: 0,
                          endCenter: CGPoint(x: S * 0.52, y: S * 0.46), endRadius: S * 0.42, options: [])

    // logo
    let side = body.width * 0.62
    cg.translateBy(x: body.midX - side / 2 + side * 0.02, y: body.midY - side / 2 + side * 0.03)
    cg.addPath(logoPath(side: side))
    cg.clip()
    let ringGrad = CGGradient(colorsSpace: space, colors: [
        NSColor(red: 0.30, green: 0.88, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.13, green: 0.40, blue: 1.00, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(ringGrad, start: .zero, end: CGPoint(x: side, y: side), options: [])
    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128),
                   ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    try render(px).write(to: out.appendingPathComponent("icon_\(name).png"))
}
print("wrote \(out.path)")
