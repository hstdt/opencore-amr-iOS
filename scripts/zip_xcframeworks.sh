#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-${OUTPUT_DIR:-${repo_root}/output}}"

if [[ ! -d "$output_dir" ]]; then
  echo "Output directory does not exist: $output_dir" >&2
  exit 66
fi

frameworks=(
  "OpenCoreAMRNB.xcframework"
  "OpenCoreAMRWB.xcframework"
)

checksum_file="${output_dir}/checksums.txt"
rm -f "$checksum_file"

for framework in "${frameworks[@]}"; do
  framework_path="${output_dir}/${framework}"
  zip_path="${output_dir}/${framework}.zip"

  if [[ ! -d "$framework_path" ]]; then
    echo "Missing XCFramework: $framework_path" >&2
    exit 66
  fi

  find "$framework_path" -exec touch -h -t 202001010000.00 {} +
  rm -f "$zip_path"

  (
    cd "$output_dir"
    COPYFILE_DISABLE=1 TZ=UTC zip -Xqr "$(basename "$zip_path")" "$framework"
  )

  checksum="$(swift package compute-checksum "$zip_path")"
  printf '%s  %s\n' "$checksum" "$(basename "$zip_path")" | tee -a "$checksum_file"
done

echo "Checksums written to ${checksum_file}"
