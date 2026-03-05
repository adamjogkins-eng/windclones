// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WinClone",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "WinClone", targets: ["WinClone"]),
    ],
    targets: [
        .executableTarget(
            name: "WinClone",
            path: "Sources")
    ]
)
