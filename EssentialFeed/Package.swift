// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EssentialFeed",
    products: [
        .library(
            name: "EssentialFeed",
            targets: ["EssentialFeed"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "EssentialFeed",
            dependencies: []),
        .testTarget(
            name: "EssentialFeedTests",
            dependencies: ["EssentialFeed"]),
        .testTarget(
            name: "EssentialFeedAPIEndToEndTests",
            dependencies: ["EssentialFeed"]),
    ]
)
