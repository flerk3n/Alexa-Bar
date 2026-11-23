import AppKit

/// The standard macOS About window, with a short credits blurb.
enum AboutPanel {
    static func show() {
        let credits = NSMutableAttributedString(
            string: "Control your Alexa smart home from the menu bar.\n\n"
                + "Not affiliated with or endorsed by Amazon. Alexa and Echo are trademarks of Amazon.com, Inc. "
                + "Built with AlexaPy.",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        credits.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: credits.length))

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}
