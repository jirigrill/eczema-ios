// swift-tools-version: 6.2

import PackageDescription

// Applied to every target here and in EczemaUI. Manifests cannot share code, so this line
// is repeated there verbatim; the reasoning lives in ../README.md § Strict settings only.
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
        // Not a product: nothing outside this package builds it, and the app must never
        // link it. It exists only so `EczemaCoreTests` has a child process to run the
        // mirroring-enabled container init in — see Sources/SchemaLoadProbe/main.swift for
        // why that init cannot happen inside the test process.
        .executableTarget(
            name: "SchemaLoadProbe",
            dependencies: ["EczemaPersistence"],
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "EczemaCoreTests",
            dependencies: ["EczemaDomain", "EczemaCatalog", "EczemaPersistence", "SchemaLoadProbe"],
            swiftSettings: strictSettings
        ),
    ]
)
