// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EssentialFeed",
    products: [
        .library(
            name: "EssentialFeed",
            targets: ["EssentialFeed"]),
        .library(
            name: "EssentialFeedAPITestUtilities",
            targets: ["EssentialFeedAPITestUtilities"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "EssentialFeed",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .target(
            name: "EssentialFeedAPITestUtilities",
            dependencies: ["EssentialFeed"]),
        .testTarget(
            name: "EssentialFeedCacheIntegrationTests",
            dependencies: ["EssentialFeed"]),
        .testTarget(
            name: "EssentialFeedTests",
            dependencies: ["EssentialFeed", "EssentialFeedAPITestUtilities"]),
        .testTarget(
            name: "EssentialFeedAPIEndToEndTests",
            dependencies: ["EssentialFeed", "EssentialFeedAPITestUtilities"]),
    ]
)
