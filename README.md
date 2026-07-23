opencore-amr-iOS
================

[![Build and Release XCFramework](https://github.com/hstdt/opencore-amr-iOS/actions/workflows/build_xcframework.yml/badge.svg)](https://github.com/hstdt/opencore-amr-iOS/actions/workflows/build_xcframework.yml)

Download pre-built XCFrameworks from [Release](https://github.com/hstdt/opencore-amr-iOS/releases) page.

iOS port of opencore-amr

Refer to `README` for opencore-amr info which is from original package.

Run `build_ios.sh` to build.

The build first compiles opencore-amr static libraries for iOS, macOS, tvOS, visionOS, and watchOS device/simulator SDKs, then packages them into dynamic framework bundles and finally creates standard framework-based XCFrameworks:

```text
output/OpenCoreAMRNB.xcframework
output/OpenCoreAMRWB.xcframework
```

The default dynamic framework deployment targets are iOS 8.0, macOS 10.9, tvOS 12.0, visionOS 1.0, and watchOS 6.0. Override them with `IOS_MIN_VERSION`, `MACOS_MIN_VERSION`, `TVOS_MIN_VERSION`, `VISIONOS_MIN_VERSION`, or `WATCHOS_MIN_VERSION` when running `build_ios.sh`.

Each framework slice includes:

```text
OpenCoreAMRNB.framework/OpenCoreAMRNB
OpenCoreAMRNB.framework/Headers/
OpenCoreAMRNB.framework/Modules/module.modulemap
```

This avoids shipping raw `.a + Headers` XCFramework slices and allows Swift or Objective-C consumers to import the framework module directly:

```swift
import OpenCoreAMRNB
import OpenCoreAMRWB
```

Swift Package Manager
---------------------

This repository exposes the prebuilt frameworks as remote binary targets. The source tree does not store XCFramework binaries; GitHub Actions builds and uploads the zipped XCFrameworks to GitHub Releases.

Add this repository as a Swift Package dependency and select one of:

```text
OpenCoreAMR    # NB + WB
OpenCoreAMRNB  # AMR-NB only
OpenCoreAMRWB  # AMR-WB only
OpenCoreAMRCodec # Swift AMR-NB/WB to WAV decoder
```

The package currently declares iOS 12+, macOS 10.13+, tvOS 12+, visionOS 1+, and watchOS 6+ because the release XCFrameworks contain matching slices. The framework binary deployment target still defaults to iOS 8.0; SwiftPM's current manifest API warns on older iOS platform declarations.

`OpenCoreAMRCodec` provides a Swift wrapper around the NB/WB decoder modules:

```swift
import OpenCoreAMRCodec

if OpenCoreAMRCodec.isAMR(data) {
    let wavData = try OpenCoreAMRCodec.decodeToWAVData(data)
}
```

The codec supports AMR-NB files with `#!AMR\n` headers and AMR-WB files with `#!AMR-WB\n` headers. It outputs mono 16-bit PCM WAV data at 8 kHz for NB and 16 kHz for WB.

Release flow:

Run the `Build and Release XCFramework` GitHub Action manually from the release branch, usually `master`, with `release_version` set to the release tag, for example `v0.1.6`.

The release workflow rebuilds the XCFrameworks, creates deterministic zip files, updates `Package.swift` with the CI-produced checksums, commits the manifest back to the selected branch, force-updates the version tag to that commit, and uploads:

```text
OpenCoreAMRNB.xcframework.zip
OpenCoreAMRWB.xcframework.zip
checksums.txt
```

Every framework slice includes a matching dSYM. The validation step compares the framework and dSYM UUIDs before the release assets are created, so archives built with these artifacts can upload third-party symbols to App Store Connect.

The release tag must point at the commit containing the final checksums. Do not create the tag by hand before running the workflow; the workflow owns tag creation and updates for unpublished releases.

If you need to verify or reproduce the manifest locally, download the release zip files and run:

```bash
swift package compute-checksum OpenCoreAMRNB.xcframework.zip
swift package compute-checksum OpenCoreAMRWB.xcframework.zip
./scripts/update_package_swift.sh v0.1.6 OpenCoreAMRNB.xcframework.zip OpenCoreAMRWB.xcframework.zip
./scripts/check_package_swift.sh v0.1.6 OpenCoreAMRNB.xcframework.zip OpenCoreAMRWB.xcframework.zip
```

Version tags follow the bundled opencore-amr source version from `configure.ac` (`0.1.6` in this tree), so this package release is tagged as `v0.1.6`.

Helper scripts:

```text
scripts/package_framework_xcframework.sh   # package one built static library and matching dSYMs into a framework-based XCFramework
scripts/validate_xcframeworks.sh           # validate framework layout and matching dSYM UUIDs
scripts/zip_xcframeworks.sh                # create deterministic SwiftPM zip artifacts and checksums.txt
scripts/update_package_swift.sh            # update Package.swift URLs/checksums for a release version
scripts/check_package_swift.sh             # verify Package.swift matches release zip checksums
tests/check_framework_xcframework_packaging.sh
```

For AMR-WB encoding, refer to http://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/ or AMR Codecs as Shared Libraries http://www.penguin.cz/~utx/amr
