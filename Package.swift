// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCoreAMR",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .visionOS(.v1),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "OpenCoreAMR", targets: ["OpenCoreAMRNB", "OpenCoreAMRWB", "OpenCoreAMRCodec"]),
        .library(name: "OpenCoreAMRNB", targets: ["OpenCoreAMRNB"]),
        .library(name: "OpenCoreAMRWB", targets: ["OpenCoreAMRWB"]),
        .library(name: "OpenCoreAMRCodec", targets: ["OpenCoreAMRCodec"]),
    ],
    targets: [
        .binaryTarget(
            name: "OpenCoreAMRNB",
            url: "https://github.com/hstdt/opencore-amr-iOS/releases/download/v0.1.6/OpenCoreAMRNB.xcframework.zip",
            checksum: "ce1539bbd150c55eb29b9b943269645153143e4eb5f4fd85a9a5c65a358a89a5"
        ),
        .binaryTarget(
            name: "OpenCoreAMRWB",
            url: "https://github.com/hstdt/opencore-amr-iOS/releases/download/v0.1.6/OpenCoreAMRWB.xcframework.zip",
            checksum: "dd87f96a232040f485eba56d1ec958fdcf6bb9ec4990c11cef9a7ab363d6358e"
        ),
        .target(
            name: "OpenCoreAMRCodec",
            dependencies: ["OpenCoreAMRNB", "OpenCoreAMRWB"]
        ),
        .testTarget(
            name: "OpenCoreAMRCodecTests",
            dependencies: ["OpenCoreAMRCodec"],
            path: "tests/OpenCoreAMRCodecTests"
        ),
    ]
)
