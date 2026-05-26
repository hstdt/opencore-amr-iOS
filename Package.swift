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
            checksum: "3a84382cb9549afe5fe0f3ba8f771cf0b72394fd5c6ab5fc703bc541c332d996"
        ),
        .binaryTarget(
            name: "OpenCoreAMRWB",
            url: "https://github.com/hstdt/opencore-amr-iOS/releases/download/v0.1.6/OpenCoreAMRWB.xcframework.zip",
            checksum: "b455897d0549c260290e79015e3a14c63a19ca70d85c57bd54e880655f215a5d"
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
