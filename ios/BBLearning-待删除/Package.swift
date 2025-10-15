// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BBLearning",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "BBLearning",
            targets: ["BBLearning"]
        )
    ],
    dependencies: [
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),

        // Database
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.0"),

        // Dependency Injection
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0"),

        // Keychain
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),

        // Image Loading
        .package(url: "https://github.com/kean/Nuke.git", from: "12.1.0"),

        // Logging (optional)
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "BBLearning",
            dependencies: [
                "Alamofire",
                .product(name: "RealmSwift", package: "realm-swift"),
                "Swinject",
                "KeychainAccess",
                "Nuke",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "BBLearning",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "BBLearningTests",
            dependencies: ["BBLearning"],
            path: "Tests/BBLearningTests"
        )
    ]
)
