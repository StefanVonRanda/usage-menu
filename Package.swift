// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UsageMenu",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "UsageMenuApp",
            path: "Sources/UsageMenuApp"
        )
    ]
)
