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
        .library(name: "OpenCoreAMR", targets: ["OpenCoreAMRNB", "OpenCoreAMRWB"]),
        .library(name: "OpenCoreAMRNB", targets: ["OpenCoreAMRNB"]),
        .library(name: "OpenCoreAMRWB", targets: ["OpenCoreAMRWB"]),
    ],
    targets: [
        .binaryTarget(
            name: "OpenCoreAMRNB",
            url: "https://github.com/hstdt/opencore-amr-iOS/releases/download/v0.1.6/OpenCoreAMRNB.xcframework.zip",
            checksum: "099a0070f8e7963f4aa483b9d7aec2903ecba6ca47b60817a13fe26562bd5441"
        ),
        .binaryTarget(
            name: "OpenCoreAMRWB",
            url: "https://github.com/hstdt/opencore-amr-iOS/releases/download/v0.1.6/OpenCoreAMRWB.xcframework.zip",
            checksum: "8cb5c95294bff30ed951db94ba87b69057bb4c8fb56991dd9a68e1313740a02d"
        ),
    ]
)
