// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Refreshing",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "Refreshing", targets: ["Refreshing"])
    ],
    targets: [
        .target(
            name: "Refreshing",
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ]
)
