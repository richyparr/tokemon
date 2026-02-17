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
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "tokemon",
            dependencies: [
                "MenuBarExtraAccess",
                "SettingsAccess",
                "KeychainAccess",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Tokemon",
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/tokemon_logo_white.png"),
                .copy("Resources/tokemon_logo.png"),
                .copy("Resources/tokemon-statusline.sh"),
            ]
        ),
    ]
)
