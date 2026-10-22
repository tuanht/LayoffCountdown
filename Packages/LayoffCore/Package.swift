// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "LayoffCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LayoffCore", targets: ["LayoffCore"]),
    ],
    targets: [
        .target(name: "LayoffCore"),
        .testTarget(name: "LayoffCoreTests", dependencies: ["LayoffCore"]),
    ]
)
