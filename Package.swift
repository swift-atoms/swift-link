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
            name: "Link Test Support",
            targets: ["Link Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-vector.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Link",
            dependencies: [
                .product(name: "Index", package: "swift-index"),
                .product(name: "Vector", package: "swift-vector"),
            ]
        ),
        .target(
            name: "Link Test Support",
            dependencies: [
                .target(name: "Link"),
                .product(name: "Index Test Support", package: "swift-index"),
                .product(
                    name: "Vector Test Support",
                    package: "swift-vector"
                ),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Link Tests",
            dependencies: [
                .target(name: "Link"),
                .target(name: "Link Test Support"),
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
