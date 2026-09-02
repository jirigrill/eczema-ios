// swift-tools-version: 6.2

import PackageDescription

// Parity with Config/Base.xcconfig. Swift 6 language mode — and with it complete strict
// concurrency — already comes from the 6.2 tools version; this adds the one upcoming
// feature that does not.
let strictSettings: [SwiftSetting] = [.enableUpcomingFeature("ExistentialAny")]

// macOS is declared alongside iOS so `swift test` runs this package on the host without
// booting a simulator. iOS 26 is the only shipping floor; nothing here may depend on
// macOS at runtime. See ../README.md for the reasoning.
let package = Package(
    name: "EczemaCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "EczemaDomain", targets: ["EczemaDomain"]),
        .library(name: "EczemaCatalog", targets: ["EczemaCatalog"]),
        .library(name: "EczemaPersistence", targets: ["EczemaPersistence"]),
    ],
    targets: [
        .target(name: "EczemaDomain", swiftSettings: strictSettings),
        .target(name: "EczemaCatalog", swiftSettings: strictSettings),
        .target(
            name: "EczemaPersistence",
            dependencies: ["EczemaDomain"],
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "EczemaCoreTests",
            dependencies: ["EczemaDomain", "EczemaCatalog", "EczemaPersistence"],
            swiftSettings: strictSettings
        ),
    ]
)
