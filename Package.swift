// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AlexaBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AlexaBar",
            path: "Sources/AlexaBar",
            swiftSettings: [.unsafeFlags(["-Osize"], .when(configuration: .release))]
        )
    ]
)
