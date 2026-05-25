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
package_file="${repo_root}/Package.swift"
repository_url="${PACKAGE_REPOSITORY_URL:-https://github.com/hstdt/opencore-amr-iOS}"

if [[ ! -f "$package_file" ]]; then
  echo "Missing Package.swift" >&2
  exit 66
fi

nb_checksum="$(swift package compute-checksum "$nb_zip")"
wb_checksum="$(swift package compute-checksum "$wb_zip")"
nb_url="${repository_url}/releases/download/${version}/OpenCoreAMRNB.xcframework.zip"
wb_url="${repository_url}/releases/download/${version}/OpenCoreAMRWB.xcframework.zip"

missing=0

expect_contains() {
  local needle=$1
  local message=$2

  if ! grep -Fq -- "$needle" "$package_file"; then
    echo "Package.swift mismatch: $message" >&2
    missing=1
  fi
}

expect_contains "$nb_url" "missing NB URL ${nb_url}"
expect_contains "$wb_url" "missing WB URL ${wb_url}"
expect_contains "$nb_checksum" "missing NB checksum ${nb_checksum}"
expect_contains "$wb_checksum" "missing WB checksum ${wb_checksum}"

if [[ "$missing" -ne 0 ]]; then
  echo "Run: scripts/update_package_swift.sh ${version} ${nb_zip} ${wb_zip}" >&2
  exit 1
fi

echo "Package.swift matches ${version} release assets."
