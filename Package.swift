// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-link",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Link",
            targets: ["Link"]
        ),
        .library(
            name: "Link Standard Library Integration",
            targets: ["Link Standard Library Integration"]
        ),
        .library(
            name: "Link Apple Foundation Integration",
            targets: ["Link Apple Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Link",
            dependencies: [
                .product(name: "Index", package: "swift-index"),
            ]
        ),
        .target(
            name: "Link Standard Library Integration",
            dependencies: ["Link"]
        ),
        .target(
            name: "Link Apple Foundation Integration",
            dependencies: [
                "Link",
                "Link Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Link Tests",
            dependencies: [
                "Link",
                .product(name: "Index", package: "swift-index"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
