// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ASCIIUI",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "ASCIIUI", targets: ["ASCIIUI"])],
    targets: [
        .target(name: "ASCIIUI"),
        .testTarget(name: "ASCIIUITests", dependencies: ["ASCIIUI"]),
    ]
)
