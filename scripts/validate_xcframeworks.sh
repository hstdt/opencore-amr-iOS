#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-${OUTPUT_DIR:-${repo_root}/output}}"

if [[ ! -d "$output_dir" ]]; then
  echo "Output directory does not exist: $output_dir" >&2
  exit 66
fi

shopt -s nullglob
xcframeworks=("${output_dir}"/*.xcframework)

if [[ ${#xcframeworks[@]} -eq 0 ]]; then
  echo "No XCFrameworks found in: $output_dir" >&2
  exit 66
fi

for xcframework in "${xcframeworks[@]}"; do
  name="$(basename "$xcframework" .xcframework)"

  if find "$xcframework" -mindepth 2 -maxdepth 2 -name '*.a' | grep -q .; then
    echo "Invalid XCFramework layout: static .a slice found in $xcframework" >&2
    exit 1
  fi

  framework_count="$(find "$xcframework" -mindepth 2 -maxdepth 2 -type d -name "${name}.framework" | wc -l | tr -d ' ')"
  if [[ "$framework_count" -eq 0 ]]; then
    echo "Invalid XCFramework layout: no ${name}.framework slices found in $xcframework" >&2
    exit 1
  fi

  while IFS= read -r framework; do
    binary="${framework}/${name}"
    modulemap="${framework}/Modules/module.modulemap"
    umbrella="${framework}/Headers/${name}.h"
    slice_dir="$(dirname "$framework")"
    dsym="${slice_dir}/dSYMs/${name}.framework.dSYM"
    dsym_binary="${dsym}/Contents/Resources/DWARF/${name}"

    if [[ ! -f "$binary" ]]; then
      echo "Missing framework binary: $binary" >&2
      exit 1
    fi

    if [[ ! -f "$modulemap" ]]; then
      echo "Missing module map: $modulemap" >&2
      exit 1
    fi

    if [[ ! -f "$umbrella" ]]; then
      echo "Missing umbrella header: $umbrella" >&2
      exit 1
    fi

    if ! file "$binary" | grep -Eq 'dynamically linked shared library|Mach-O.*dynamically linked shared library'; then
      echo "Framework binary is not dynamic: $binary" >&2
      file "$binary" >&2
      exit 1
    fi

    if [[ ! -f "$dsym_binary" ]]; then
      echo "Missing dSYM DWARF binary: $dsym_binary" >&2
      exit 1
    fi

    binary_uuids="$(xcrun dwarfdump --uuid "$binary" | awk '/UUID:/ { print toupper($2) }' | sort -u)"
    dsym_uuids="$(xcrun dwarfdump --uuid "$dsym_binary" | awk '/UUID:/ { print toupper($2) }' | sort -u)"

    if [[ -z "$binary_uuids" || "$binary_uuids" != "$dsym_uuids" ]]; then
      echo "dSYM UUID mismatch for: $binary" >&2
      echo "Framework UUIDs:" >&2
      echo "$binary_uuids" >&2
      echo "dSYM UUIDs:" >&2
      echo "$dsym_uuids" >&2
      exit 1
    fi
  done < <(find "$xcframework" -mindepth 2 -maxdepth 2 -type d -name "${name}.framework")
done

echo "XCFramework bundle layout and dSYM UUIDs are valid."
