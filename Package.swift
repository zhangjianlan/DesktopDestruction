// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DesktopDestruction",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DesktopDestruction",
            path: "Sources/DesktopDestruction",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "DesktopDestructionTests",
            dependencies: ["DesktopDestruction"],
            path: "Tests/DesktopDestructionTests"
        )
    ]
)
