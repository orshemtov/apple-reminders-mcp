// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "apple-reminders-mcp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "AppleRemindersMCP", targets: ["AppleRemindersMCP"]),
        .executable(name: "apple-reminders-mcp", targets: ["apple-reminders-mcp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
    ],
    targets: [
        .target(
            name: "AppleRemindersMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ],
            linkerSettings: [
                .linkedFramework("EventKit"),
                .linkedFramework("CoreLocation"),
            ]
        ),
        .executableTarget(
            name: "apple-reminders-mcp",
            dependencies: [
                "AppleRemindersMCP"
            ]
        ),
        .testTarget(
            name: "AppleRemindersMCPTests",
            dependencies: [
                "AppleRemindersMCP",
                .product(name: "MCP", package: "swift-sdk"),
            ]
        ),
    ],
)
