#!/usr/bin/env bash
set -ex

lib_name=$1
repo_root="${GITHUB_WORKSPACE:-$(pwd)}"
export OUTPUT_DIR="${OUTPUT_DIR:-${repo_root}/output}"

case "$lib_name" in
  opencore-amrnb)
    "${repo_root}/scripts/package_framework_xcframework.sh" \
      "opencore-amrnb" \
      "OpenCoreAMRNB" \
      "io.github.kuailliao.OpenCoreAMRNB" \
      "amrnb/interf_dec.h" \
      "amrnb/interf_enc.h"
    ;;
  opencore-amrwb)
    "${repo_root}/scripts/package_framework_xcframework.sh" \
      "opencore-amrwb" \
      "OpenCoreAMRWB" \
      "io.github.kuailliao.OpenCoreAMRWB" \
      "amrwb/dec_if.h" \
      "amrwb/if_rom.h"
    ;;
  *)
    echo "Unsupported library: $lib_name" >&2
    exit 64
    ;;
esac
