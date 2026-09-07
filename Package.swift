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
        .library(name: "Link", targets: ["Link"]),
        .library(name: "Link Standard Library Integration", targets: ["Link Standard Library Integration"]),
        .library(name: "Link Foundation Library Integration", targets: ["Link Foundation Library Integration"]),
        .library(name: "Link Test Support", targets: ["Link Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-affine.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-cardinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ordinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
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
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Ordinal", package: "swift-ordinal"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Vector", package: "swift-vector"),
            ],
            path: "Sources/Link"
        ),
        .target(
            name: "Link Standard Library Integration",
            dependencies: [
                .target(name: "Link"),
            ],
            path: "Sources/Link Standard Library Integration"
        ),
        .target(
            name: "Link Foundation Library Integration",
            dependencies: [
                .target(name: "Link"),
                .target(name: "Link Standard Library Integration"),
            ],
            path: "Sources/Link Foundation Library Integration"
        ),
        .target(
            name: "Link Test Support",
            dependencies: [
                .target(name: "Link"),
                .product(name: "Index Test Support", package: "swift-index"),
                .product(name: "Vector Test Support", package: "swift-vector"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Link Tests",
            dependencies: [
                .target(name: "Link"),
                .target(name: "Link Test Support"),
                .product(name: "Affine", package: "swift-affine"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Ordinal", package: "swift-ordinal"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Tagged Standard Library Integration", package: "swift-tagged"),
                .target(name: "Link Standard Library Integration"),
                .target(name: "Link Foundation Library Integration"),
            ],
            path: "Tests/Link Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
