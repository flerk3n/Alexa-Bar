import SwiftUI

enum Theme {
    static let panelWidth: CGFloat = 352
    static let corner: CGFloat = 14
    static let alexaBlue = Color(red: 0.00, green: 0.66, blue: 0.88)
    static let alexaDeep = Color(red: 0.13, green: 0.32, blue: 0.95)
    static let plugTint = Color(red: 0.20, green: 0.78, blue: 0.45)
    static let speakerTint = Color(red: 0.16, green: 0.62, blue: 1.00)

    static var brand: LinearGradient {
        LinearGradient(colors: [alexaBlue, alexaDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var cardFill: Color { Color.primary.opacity(0.055) }
    static var cardStroke: Color { Color.primary.opacity(0.07) }
}
