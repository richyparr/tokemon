// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tokemon",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess.git", from: "1.2.2"),
        .package(url: "https://github.com/orchetect/SettingsAccess.git", from: "2.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/kevinhermawan/swift-lemon-squeezy-license.git", from: "1.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "tokemon",
            dependencies: [
                "MenuBarExtraAccess",
                "SettingsAccess",
                "KeychainAccess",
                .product(name: "LemonSqueezyLicense", package: "swift-lemon-squeezy-license"),
            ],
            path: "Tokemon",
            exclude: ["Info.plist"]
        ),
    ]
)
