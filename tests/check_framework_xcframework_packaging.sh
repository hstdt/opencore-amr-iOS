#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failed=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failed=1
}

expect_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if ! grep -Fq -- "$pattern" "$file"; then
    fail "$message"
  fi
}

expect_not_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if grep -Fq -- "$pattern" "$file"; then
    fail "$message"
  fi
}

workflow=".github/workflows/build_xcframework.yml"
ci_helper=".github/actions/create_xcframework.sh"
ci_builder=".github/actions/build_library.sh"
local_builder="build_ios.sh"
packager="scripts/package_framework_xcframework.sh"
validator="scripts/validate_xcframeworks.sh"
zipper="scripts/zip_xcframeworks.sh"
package_checker="scripts/check_package_swift.sh"
package_updater="scripts/update_package_swift.sh"
package_manifest="Package.swift"

for file in "$workflow" "$ci_helper" "$ci_builder" "$local_builder" "$packager" "$validator" "$zipper" "$package_checker" "$package_updater" "$package_manifest"; do
  if [[ ! -f "$file" ]]; then
    fail "required file is missing: $file"
  fi
done

expect_contains "$workflow" './.github/actions/create_xcframework.sh opencore-amrnb' \
  "workflow must package OpenCoreAMRNB through the shared helper"
expect_contains "$workflow" './.github/actions/create_xcframework.sh opencore-amrwb' \
  "workflow must package OpenCoreAMRWB through the shared helper"
expect_contains "$workflow" './scripts/validate_xcframeworks.sh "$OUTPUT_DIR"' \
  "workflow must validate framework-based XCFramework output"
expect_contains "$workflow" './scripts/zip_xcframeworks.sh "${OUTPUT_DIR}"' \
  "workflow must create deterministic release zips through the shared helper"
expect_contains "$workflow" './scripts/update_package_swift.sh' \
  "workflow must update Package.swift with CI-produced checksums"
expect_contains "$workflow" './scripts/check_package_swift.sh' \
  "workflow must verify Package.swift after updating CI checksums"
expect_contains "$workflow" 'git tag -f "$VERSION" HEAD' \
  "workflow must move the release tag after updating Package.swift"
expect_contains "$workflow" 'git push origin "refs/tags/${VERSION}" --force' \
  "workflow must push the release tag after updating Package.swift"
expect_contains "$workflow" '${{ env.OUTPUT_DIR }}/checksums.txt' \
  "workflow must upload CI-produced checksums"
expect_contains "$workflow" "sdk: 'appletvos'" \
  "workflow must build tvOS device slices"
expect_contains "$workflow" "sdk: 'xros'" \
  "workflow must build visionOS device slices"
expect_contains "$workflow" "sdk: 'watchos'" \
  "workflow must build watchOS device slices"

expect_contains "$ci_helper" 'scripts/package_framework_xcframework.sh' \
  "CI helper must delegate to the shared framework packager"
expect_contains "$ci_builder" '-O3 -g -DNDEBUG' \
  "CI builds must preserve debug information for dSYM generation"
expect_contains "$local_builder" 'scripts/package_framework_xcframework.sh' \
  "local build must delegate to the shared framework packager"
expect_contains "$local_builder" '-O3 -g -DNDEBUG' \
  "local builds must preserve debug information for dSYM generation"
expect_contains "$local_builder" 'build_library "appletvos" "arm64" "AppleTVOS"' \
  "local build must include tvOS"
expect_contains "$local_builder" 'build_library "xros" "arm64" "XROS"' \
  "local build must include visionOS"
expect_contains "$local_builder" 'build_library "watchos" "arm64_32" "WatchOS"' \
  "local build must include watchOS"
expect_contains "$packager" 'xcodebuild -create-xcframework' \
  "packager must create XCFrameworks with xcodebuild"
expect_contains "$packager" 'xcrun dsymutil' \
  "packager must generate a dSYM for each framework slice"
expect_contains "$packager" '-debug-symbols "$iphoneos_dsym"' \
  "packager must include dSYMs in the XCFramework"
expect_contains "$packager" '-framework "$iphoneos_framework"' \
  "packager must pass framework slices, not static libraries"
expect_contains "$packager" '-framework "$appletvos_framework"' \
  "packager must include tvOS frameworks"
expect_contains "$packager" '-framework "$xros_framework"' \
  "packager must include visionOS frameworks"
expect_contains "$packager" '-framework "$watchos_framework"' \
  "packager must include watchOS frameworks"
expect_contains "$packager" '-dynamiclib' \
  "packager must link dynamic framework binaries"
expect_contains "$packager" 'Modules/module.modulemap' \
  "packager must create a module map for Swift imports"
expect_contains "$packager" 'Headers/${framework_name}.h' \
  "packager must create an umbrella header"
expect_contains "$validator" 'xcrun dwarfdump --uuid' \
  "validator must compare framework and dSYM UUIDs"
expect_contains "$zipper" 'swift package compute-checksum' \
  "zip helper must compute SwiftPM checksums"
expect_contains "$zipper" 'COPYFILE_DISABLE=1 TZ=UTC zip -Xqr' \
  "zip helper must create deterministic zips"
expect_contains "$package_checker" 'Package.swift matches' \
  "package checker must validate manifest URLs and checksums"
expect_contains "$package_updater" 'OpenCoreAMRNB.xcframework.zip' \
  "package updater must generate NB binary target URLs"
expect_contains "$package_manifest" '.binaryTarget(' \
  "Package.swift must expose remote binary targets"
expect_contains "$package_manifest" 'OpenCoreAMRNB.xcframework.zip' \
  "Package.swift must reference the NB release asset"
expect_contains "$package_manifest" 'OpenCoreAMRWB.xcframework.zip' \
  "Package.swift must reference the WB release asset"
expect_contains "$package_manifest" '.tvOS(.v12)' \
  "Package.swift must declare tvOS support"
expect_contains "$package_manifest" '.visionOS(.v1)' \
  "Package.swift must declare visionOS support"
expect_contains "$package_manifest" '.watchOS(.v6)' \
  "Package.swift must declare watchOS support"

expect_not_contains "$workflow" ' -library ${OUTPUT_DIR}' \
  "workflow must not pass static libraries directly to xcodebuild"
expect_not_contains "$workflow" "tags:" \
  "workflow must use manual release dispatch instead of tag-push release triggers"
expect_not_contains "$ci_helper" '-library "$OUTPUT_DIR' \
  "CI helper must not pass static libraries directly to xcodebuild"
expect_not_contains "$local_builder" '-library "$OUTPUT_DIR' \
  "local build must not pass static libraries directly to xcodebuild"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

printf 'Framework-based XCFramework packaging scripts are wired correctly.\n'
