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
            checksum: "97877b15d6205f22e6d883fd270324c4f0860bb3c0649cee74a0c9041140df0d"
        ),
        .binaryTarget(
            name: "OpenCoreAMRWB",
            url: "https://github.com/hstdt/opencore-amr-iOS/releases/download/v0.1.6/OpenCoreAMRWB.xcframework.zip",
            checksum: "8b2463733db8cb15bd62375f5cb7cf21f9098920aa523ee501c849bfc470b516"
        ),
    ]
)
