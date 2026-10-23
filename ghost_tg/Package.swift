// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "GhostTG",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(name: "GhostTG", path: "Sources/GhostTG")
    ]
)
