// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LambdaspireSwiftNotifications",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LambdaspireSwiftNotifications",
            targets: ["LambdaspireSwiftNotifications"]),
    ],
    targets: [
        .target(
            name: "LambdaspireSwiftNotifications"),
        .testTarget(
            name: "LambdaspireSwiftNotificationsTests",
            dependencies: ["LambdaspireSwiftNotifications"]),
    ]
)
