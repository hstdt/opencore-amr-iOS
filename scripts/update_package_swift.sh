#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <version> <OpenCoreAMRNB.xcframework.zip> <OpenCoreAMRWB.xcframework.zip>" >&2
  exit 64
fi

version=$1
nb_zip=$2
wb_zip=$3

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_url="${PACKAGE_REPOSITORY_URL:-https://github.com/hstdt/opencore-amr-iOS}"

if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-+][A-Za-z0-9.-]+)?$ ]]; then
  echo "Invalid version: $version" >&2
  exit 64
fi

if [[ ! -f "$nb_zip" ]]; then
  echo "Missing NB zip: $nb_zip" >&2
  exit 66
fi

if [[ ! -f "$wb_zip" ]]; then
  echo "Missing WB zip: $wb_zip" >&2
  exit 66
fi

nb_checksum="$(swift package compute-checksum "$nb_zip")"
wb_checksum="$(swift package compute-checksum "$wb_zip")"

cat > "${repo_root}/Package.swift" <<EOF
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
            url: "${repository_url}/releases/download/${version}/OpenCoreAMRNB.xcframework.zip",
            checksum: "${nb_checksum}"
        ),
        .binaryTarget(
            name: "OpenCoreAMRWB",
            url: "${repository_url}/releases/download/${version}/OpenCoreAMRWB.xcframework.zip",
            checksum: "${wb_checksum}"
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
EOF

echo "Updated Package.swift for ${version}"
