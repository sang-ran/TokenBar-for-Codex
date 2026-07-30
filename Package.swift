// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TokenBarForCodex",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "TokenBar", targets: ["TokenBar"]),
    ],
    targets: [
        .executableTarget(
            name: "TokenBar",
            path: "Sources/TokenBar",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]),
        .testTarget(
            name: "TokenBarTests",
            dependencies: ["TokenBar"],
            path: "Tests/TokenBarTests"),
    ])
