// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TripGenerator",
    dependencies: [
        .package(url: "https://github.com/vapor/core", from: "3.2.1"),
        .package(url: "https://github.com/nsomar/Guaka", from: "0.4.1"),
        .package(url: "https://github.com/vapor/http", from: "3.2.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "TripGenerator",
            dependencies: ["Core", "Guaka", "HTTP", "SwiftyJSON"]),
    ]
)
