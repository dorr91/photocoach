// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoCoachCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PhotoCoachCore",
            targets: ["PhotoCoachCore"]),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "PhotoCoachCore",
            dependencies: [],
            exclude: [
                "Protocols/README.md",
                "Services/README.md"
            ],
            resources: [
                .process("Models/PhotoCoach.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "PhotoCoachCoreTests",
            dependencies: ["PhotoCoachCore"]),
    ]
)