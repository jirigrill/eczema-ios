// swift-tools-version: 6.2

import PackageDescription

// macOS is declared alongside iOS so `swift test` runs this package on the host
// without booting a simulator. iOS 26 is the only shipping floor; nothing here may
// depend on macOS at runtime.
let package = Package(
    name: "EczemaCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "EczemaDomain", targets: ["EczemaDomain"]),
        .library(name: "EczemaCatalog", targets: ["EczemaCatalog"]),
        .library(name: "EczemaPersistence", targets: ["EczemaPersistence"]),
    ],
    targets: [
        .target(name: "EczemaDomain"),
        .target(name: "EczemaCatalog"),
        .target(name: "EczemaPersistence", dependencies: ["EczemaDomain"]),
        .testTarget(
            name: "EczemaCoreTests",
            dependencies: ["EczemaDomain", "EczemaCatalog", "EczemaPersistence"]
        ),
    ]
)
