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

  if ! grep -Fq "$pattern" "$file"; then
    fail "$message"
  fi
}

expect_not_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if grep -Fq "$pattern" "$file"; then
    fail "$message"
  fi
}

workflow=".github/workflows/build_xcframework.yml"
ci_helper=".github/actions/create_xcframework.sh"
local_builder="build_ios.sh"

expect_not_contains "$workflow" 'fat/lib${lib}-${platform}.a' \
  "workflow must not pass platform-suffixed static library basenames to xcodebuild"
expect_not_contains "$workflow" '${lib}-iphoneos.a' \
  "workflow must not create iOS device libraries with an -iphoneos suffix"
expect_not_contains "$workflow" '${lib}-iphonesimulator.a' \
  "workflow must not create simulator libraries with an -iphonesimulator suffix"
expect_not_contains "$workflow" '${lib}-macos.a' \
  "workflow must not create macOS libraries with a -macos suffix"
expect_contains "$workflow" '${OUTPUT_DIR}/fat/${platform}/lib${lib}.a' \
  "workflow must pass the same lib<name>.a basename for every xcframework slice"

for file in "$ci_helper" "$local_builder"; do
  expect_not_contains "$file" 'iphonesimulator-lib$lib_name.a' \
    "$file must not create a simulator library with a platform-specific basename"
  expect_not_contains "$file" 'macosx-lib$lib_name.a' \
    "$file must not create a macOS library with a platform-specific basename"
  expect_contains "$file" 'iphonesimulator/lib/lib$lib_name.a' \
    "$file must create the simulator slice with the canonical lib<name>.a basename"
  expect_contains "$file" 'macosx/lib/lib$lib_name.a' \
    "$file must create the macOS slice with the canonical lib<name>.a basename"
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

printf 'XCFramework static library basenames are stable across slices.\n'
