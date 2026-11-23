import Foundation

/// An Amazon marketplace; its domain decides which Alexa servers we use.
struct AmazonRegion: Identifiable, Hashable {
    let id: String
    let name: String
    let flag: String

    static let all: [AmazonRegion] = [
        .init(id: "amazon.com", name: "United States", flag: "🇺🇸"),
        .init(id: "amazon.in", name: "India", flag: "🇮🇳"),
        .init(id: "amazon.co.uk", name: "United Kingdom", flag: "🇬🇧"),
        .init(id: "amazon.ca", name: "Canada", flag: "🇨🇦"),
        .init(id: "amazon.com.au", name: "Australia", flag: "🇦🇺"),
        .init(id: "amazon.de", name: "Germany", flag: "🇩🇪"),
        .init(id: "amazon.fr", name: "France", flag: "🇫🇷"),
        .init(id: "amazon.it", name: "Italy", flag: "🇮🇹"),
        .init(id: "amazon.es", name: "Spain", flag: "🇪🇸"),
        .init(id: "amazon.co.jp", name: "Japan", flag: "🇯🇵"),
        .init(id: "amazon.com.br", name: "Brazil", flag: "🇧🇷"),
        .init(id: "amazon.com.mx", name: "Mexico", flag: "🇲🇽"),
    ]

    static func named(_ domain: String) -> AmazonRegion {
        all.first { $0.id == domain } ?? .init(id: domain, name: domain, flag: "🌐")
    }

    /// Best guess from the Mac's region setting.
    static var guess: AmazonRegion {
        let map = [
            "IN": "amazon.in", "GB": "amazon.co.uk", "CA": "amazon.ca", "AU": "amazon.com.au",
            "DE": "amazon.de", "AT": "amazon.de", "FR": "amazon.fr", "IT": "amazon.it",
            "ES": "amazon.es", "JP": "amazon.co.jp", "BR": "amazon.com.br", "MX": "amazon.com.mx",
        ]
        return named(map[Locale.current.region?.identifier ?? ""] ?? "amazon.com")
    }
}
