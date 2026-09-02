// swift-tools-version: 6.2

import PackageDescription

// Repeated verbatim from EczemaCore/Package.swift because manifests cannot share code;
// the reasoning lives in ../README.md § Strict settings only.
let strictSettings: [SwiftSetting] = [.enableUpcomingFeature("ExistentialAny")]

// macOS is declared only so `swift test` can build this package on the host; iOS is the
// only platform this app ships to. See ../README.md for why the split is drawn here and
// what a `#if os(iOS)` in this target would mean.
let package = Package(
    name: "EczemaUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "EczemaUI", targets: ["EczemaUI"]),
    ],
    dependencies: [
        .package(name: "EczemaCore", path: "../EczemaCore"),
    ],
    targets: [
        .target(
            name: "EczemaUI",
            dependencies: [
                .product(name: "EczemaDomain", package: "EczemaCore"),
                .product(name: "EczemaCatalog", package: "EczemaCore"),
                .product(name: "EczemaPersistence", package: "EczemaCore"),
            ],
            resources: [.process("Resources")],
            swiftSettings: strictSettings
        ),
        .testTarget(name: "EczemaUITests", dependencies: ["EczemaUI"], swiftSettings: strictSettings),
    ]
)
