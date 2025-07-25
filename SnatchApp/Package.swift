// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snatch",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SnatchApp", targets: ["SnatchApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SnatchApp",
            dependencies: [],
            path: "Sources/SnatchApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
) 