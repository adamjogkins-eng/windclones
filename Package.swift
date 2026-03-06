// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WinClone",
    platforms: [
        .iOS(.v18) 
    ],
    products: [
        .executable(name: "WinClone", targets: ["WinClone"])
    ],
    targets: [
        .executableTarget(
            name: "WinClone",
            path: "Sources"
        )
    ]
)
