// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WinClone",
    platforms: [.iOS(.v17)],
    products: [.library(name: "WinClone", targets: ["WinClone"])],
    targets: [.target(name: "WinClone", path: "Sources")]
)
