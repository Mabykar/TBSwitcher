// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TBSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "TBShared"),
        .executableTarget(name: "TBSwitcher", dependencies: ["TBShared"]),
        .executableTarget(name: "TBHelper", dependencies: ["TBShared"]),
    ]
)
