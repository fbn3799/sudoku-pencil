// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SudokuPencil",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SudokuPencil", targets: ["SudokuPencil"])
    ],
    targets: [
        .target(name: "SudokuPencil", path: "Sources")
    ]
)
