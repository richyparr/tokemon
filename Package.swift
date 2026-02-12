// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeMon",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess.git", from: "1.2.2"),
        .package(url: "https://github.com/orchetect/SettingsAccess.git", from: "2.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "ClaudeMon",
            dependencies: [
                "MenuBarExtraAccess",
                "SettingsAccess",
                "KeychainAccess",
            ],
            path: "ClaudeMon",
            exclude: ["Info.plist"]
        ),
    ]
)
