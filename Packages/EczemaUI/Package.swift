// swift-tools-version: 6.2

import PackageDescription

// macOS is declared only so `swift test` can build this package on the host. iOS is the
// only platform this app ships to. If a view here ever needs `#if os(iOS)` to compile,
// read that as the signal that the logic under it belongs in EczemaCore — not as an
// invitation to start supporting macOS.
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
            resources: [.process("Resources")]
        ),
        .testTarget(name: "EczemaUITests", dependencies: ["EczemaUI"]),
    ]
)
