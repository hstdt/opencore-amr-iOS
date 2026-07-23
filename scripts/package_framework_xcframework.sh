#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <library-name> <framework-name> <bundle-id> <header> [<header> ...]" >&2
  exit 64
fi

lib_name=$1
framework_name=$2
bundle_id=$3
shift 3
headers=("$@")

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
output_dir="${OUTPUT_DIR:-${repo_root}/output}"
developer="$(xcode-select --print-path)"
platforms_root="${developer}/Platforms"

ios_min_version="${IOS_MIN_VERSION:-8.0}"
macos_min_version="${MACOS_MIN_VERSION:-10.9}"
tvos_min_version="${TVOS_MIN_VERSION:-12.0}"
visionos_min_version="${VISIONOS_MIN_VERSION:-1.0}"
watchos_min_version="${WATCHOS_MIN_VERSION:-6.0}"
framework_version="${FRAMEWORK_VERSION:-0.1.6}"
framework_build="${FRAMEWORK_BUILD:-1}"

require_file() {
  local path=$1

  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 66
  fi
}

resolve_library() {
  local direct_path=$1
  local artifact_path=$2

  if [[ -f "$direct_path" ]]; then
    printf '%s\n' "$direct_path"
    return
  fi

  if [[ -f "$artifact_path" ]]; then
    printf '%s\n' "$artifact_path"
    return
  fi

  echo "Missing required library. Checked:" >&2
  echo "  $direct_path" >&2
  echo "  $artifact_path" >&2
  exit 66
}

iphoneos_lib="$(resolve_library \
  "${output_dir}/iphoneos-arm64-iPhoneOS/lib/lib${lib_name}.a" \
  "${output_dir}/build-iphoneos-arm64/iphoneos-arm64-iPhoneOS/lib/lib${lib_name}.a")"
iphonesimulator_x86_64_lib="$(resolve_library \
  "${output_dir}/iphonesimulator-x86_64-iPhoneSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-iphonesimulator-x86_64/iphonesimulator-x86_64-iPhoneSimulator/lib/lib${lib_name}.a")"
iphonesimulator_arm64_lib="$(resolve_library \
  "${output_dir}/iphonesimulator-arm64-iPhoneSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-iphonesimulator-arm64/iphonesimulator-arm64-iPhoneSimulator/lib/lib${lib_name}.a")"
macos_x86_64_lib="$(resolve_library \
  "${output_dir}/macosx-x86_64-MacOSX/lib/lib${lib_name}.a" \
  "${output_dir}/build-macosx-x86_64/macosx-x86_64-MacOSX/lib/lib${lib_name}.a")"
macos_arm64_lib="$(resolve_library \
  "${output_dir}/macosx-arm64-MacOSX/lib/lib${lib_name}.a" \
  "${output_dir}/build-macosx-arm64/macosx-arm64-MacOSX/lib/lib${lib_name}.a")"
appletvos_lib="$(resolve_library \
  "${output_dir}/appletvos-arm64-AppleTVOS/lib/lib${lib_name}.a" \
  "${output_dir}/build-appletvos-arm64/appletvos-arm64-AppleTVOS/lib/lib${lib_name}.a")"
appletvsimulator_x86_64_lib="$(resolve_library \
  "${output_dir}/appletvsimulator-x86_64-AppleTVSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-appletvsimulator-x86_64/appletvsimulator-x86_64-AppleTVSimulator/lib/lib${lib_name}.a")"
appletvsimulator_arm64_lib="$(resolve_library \
  "${output_dir}/appletvsimulator-arm64-AppleTVSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-appletvsimulator-arm64/appletvsimulator-arm64-AppleTVSimulator/lib/lib${lib_name}.a")"
xros_lib="$(resolve_library \
  "${output_dir}/xros-arm64-XROS/lib/lib${lib_name}.a" \
  "${output_dir}/build-xros-arm64/xros-arm64-XROS/lib/lib${lib_name}.a")"
xrsimulator_x86_64_lib="$(resolve_library \
  "${output_dir}/xrsimulator-x86_64-XRSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-xrsimulator-x86_64/xrsimulator-x86_64-XRSimulator/lib/lib${lib_name}.a")"
xrsimulator_arm64_lib="$(resolve_library \
  "${output_dir}/xrsimulator-arm64-XRSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-xrsimulator-arm64/xrsimulator-arm64-XRSimulator/lib/lib${lib_name}.a")"
watchos_arm64_32_lib="$(resolve_library \
  "${output_dir}/watchos-arm64_32-WatchOS/lib/lib${lib_name}.a" \
  "${output_dir}/build-watchos-arm64_32/watchos-arm64_32-WatchOS/lib/lib${lib_name}.a")"
watchos_arm64_lib="$(resolve_library \
  "${output_dir}/watchos-arm64-WatchOS/lib/lib${lib_name}.a" \
  "${output_dir}/build-watchos-arm64/watchos-arm64-WatchOS/lib/lib${lib_name}.a")"
watchsimulator_x86_64_lib="$(resolve_library \
  "${output_dir}/watchsimulator-x86_64-WatchSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-watchsimulator-x86_64/watchsimulator-x86_64-WatchSimulator/lib/lib${lib_name}.a")"
watchsimulator_arm64_lib="$(resolve_library \
  "${output_dir}/watchsimulator-arm64-WatchSimulator/lib/lib${lib_name}.a" \
  "${output_dir}/build-watchsimulator-arm64/watchsimulator-arm64-WatchSimulator/lib/lib${lib_name}.a")"

for header in "${headers[@]}"; do
  require_file "${repo_root}/${header}"
done

fat_dir="${output_dir}/fat"
frameworks_dir="${output_dir}/frameworks/${framework_name}"
headers_dir="${output_dir}/Headers/${framework_name}"
xcframework_path="${output_dir}/${framework_name}.xcframework"

rm -rf "$frameworks_dir" "$headers_dir" "$xcframework_path"
mkdir -p \
  "${fat_dir}/iphonesimulator" \
  "${fat_dir}/macosx" \
  "${fat_dir}/appletvsimulator" \
  "${fat_dir}/watchos" \
  "${fat_dir}/watchsimulator" \
  "$headers_dir"

lipo -create "$iphonesimulator_x86_64_lib" "$iphonesimulator_arm64_lib" \
  -output "${fat_dir}/iphonesimulator/lib${lib_name}.a"

lipo -create "$macos_x86_64_lib" "$macos_arm64_lib" \
  -output "${fat_dir}/macosx/lib${lib_name}.a"

lipo -create "$appletvsimulator_x86_64_lib" "$appletvsimulator_arm64_lib" \
  -output "${fat_dir}/appletvsimulator/lib${lib_name}.a"

lipo -create "$watchos_arm64_32_lib" "$watchos_arm64_lib" \
  -output "${fat_dir}/watchos/lib${lib_name}.a"

lipo -create "$watchsimulator_x86_64_lib" "$watchsimulator_arm64_lib" \
  -output "${fat_dir}/watchsimulator/lib${lib_name}.a"

copy_headers() {
  local destination=$1

  mkdir -p "${destination}/Headers" "${destination}/Modules"
  for header in "${headers[@]}"; do
    cp "${repo_root}/${header}" "${destination}/Headers/"
  done
}

write_umbrella_header() {
  local destination=$1
  local umbrella="${destination}/Headers/${framework_name}.h"

  {
    echo "#ifndef ${framework_name}_h"
    echo "#define ${framework_name}_h"
    echo
    for header in "${headers[@]}"; do
      echo "#include \"$(basename "$header")\""
    done
    echo
    echo "#endif /* ${framework_name}_h */"
  } > "$umbrella"
}

write_module_map() {
  local destination=$1

  cat > "${destination}/Modules/module.modulemap" <<EOF
framework module ${framework_name} {
  umbrella header "${framework_name}.h"
  export *
  module * { export * }
}
EOF
}

write_info_plist() {
  local destination=$1
  local platform_name=$2
  local minimum_key=$3
  local minimum_version=$4

  cat > "${destination}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${framework_name}</string>
  <key>CFBundleIdentifier</key>
  <string>${bundle_id}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${framework_name}</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>${framework_version}</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>${platform_name}</string>
  </array>
  <key>CFBundleVersion</key>
  <string>${framework_build}</string>
  <key>${minimum_key}</key>
  <string>${minimum_version}</string>
</dict>
</plist>
EOF
}

link_dynamic_framework() {
  local sdk=$1
  local platform_name=$2
  local static_lib=$3
  local destination=$4
  local minimum_key=$5
  local minimum_version=$6
  shift 6
  local arch_flags=("$@")

  local sdk_root
  sdk_root="${platforms_root}/${sdk}.platform/Developer/SDKs/${sdk}.sdk"

  mkdir -p "$destination"
  copy_headers "$destination"
  write_umbrella_header "$destination"
  write_module_map "$destination"
  write_info_plist "$destination" "$platform_name" "$minimum_key" "$minimum_version"

  xcrun --sdk "$(tr '[:upper:]' '[:lower:]' <<< "$sdk")" clang++ \
    -g \
    -dynamiclib \
    "${arch_flags[@]}" \
    -isysroot "$sdk_root" \
    -install_name "@rpath/${framework_name}.framework/${framework_name}" \
    -Wl,-force_load,"${static_lib}" \
    -o "${destination}/${framework_name}"
}

link_dynamic_framework_from_archives() {
  local sdk=$1
  local platform_name=$2
  local destination=$3
  local minimum_key=$4
  local minimum_version=$5
  shift 5
  local arch_specs=("$@")

  local sdk_root
  sdk_root="${platforms_root}/${sdk}.platform/Developer/SDKs/${sdk}.sdk"

  local scratch
  scratch="$(mktemp -d "${TMPDIR:-/tmp}/${framework_name}.${sdk}.XXXXXX")"
  trap 'rm -rf "$scratch"' RETURN

  mkdir -p "$destination"
  copy_headers "$destination"
  write_umbrella_header "$destination"
  write_module_map "$destination"
  write_info_plist "$destination" "$platform_name" "$minimum_key" "$minimum_version"

  local binaries=()
  local spec arch target static_lib binary
  for spec in "${arch_specs[@]}"; do
    IFS=':' read -r arch target static_lib <<< "$spec"
    binary="${scratch}/${framework_name}-${arch}"

    xcrun --sdk "$(tr '[:upper:]' '[:lower:]' <<< "$sdk")" clang++ \
      -g \
      -dynamiclib \
      -target "$target" \
      -isysroot "$sdk_root" \
      -install_name "@rpath/${framework_name}.framework/${framework_name}" \
      -Wl,-force_load,"${static_lib}" \
      -o "$binary"

    binaries+=("$binary")
  done

  lipo -create "${binaries[@]}" -output "${destination}/${framework_name}"
}

create_debug_symbols() {
  local framework=$1
  local binary="${framework}/${framework_name}"
  local dsym="${framework}.dSYM"

  rm -rf "$dsym"
  xcrun dsymutil "$binary" -o "$dsym"
  require_file "${dsym}/Contents/Resources/DWARF/${framework_name}"
}

absolute_path() {
  local path=$1
  local directory
  directory="$(cd "$(dirname "$path")" && pwd)"
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

iphoneos_framework="${frameworks_dir}/iphoneos/${framework_name}.framework"
iphonesimulator_framework="${frameworks_dir}/iphonesimulator/${framework_name}.framework"
macos_framework="${frameworks_dir}/macosx/${framework_name}.framework"
appletvos_framework="${frameworks_dir}/appletvos/${framework_name}.framework"
appletvsimulator_framework="${frameworks_dir}/appletvsimulator/${framework_name}.framework"
xros_framework="${frameworks_dir}/xros/${framework_name}.framework"
xrsimulator_framework="${frameworks_dir}/xrsimulator/${framework_name}.framework"
watchos_framework="${frameworks_dir}/watchos/${framework_name}.framework"
watchsimulator_framework="${frameworks_dir}/watchsimulator/${framework_name}.framework"

link_dynamic_framework "iPhoneOS" "iPhoneOS" "$iphoneos_lib" "$iphoneos_framework" \
  "MinimumOSVersion" "$ios_min_version" \
  -arch arm64 -miphoneos-version-min="$ios_min_version"

link_dynamic_framework "iPhoneSimulator" "iPhoneSimulator" "${fat_dir}/iphonesimulator/lib${lib_name}.a" "$iphonesimulator_framework" \
  "MinimumOSVersion" "$ios_min_version" \
  -arch x86_64 -arch arm64 -mios-simulator-version-min="$ios_min_version"

link_dynamic_framework "MacOSX" "MacOSX" "${fat_dir}/macosx/lib${lib_name}.a" "$macos_framework" \
  "LSMinimumSystemVersion" "$macos_min_version" \
  -arch x86_64 -arch arm64 -mmacosx-version-min="$macos_min_version"

link_dynamic_framework "AppleTVOS" "AppleTVOS" "$appletvos_lib" "$appletvos_framework" \
  "MinimumOSVersion" "$tvos_min_version" \
  -arch arm64 -mtvos-version-min="$tvos_min_version"

link_dynamic_framework "AppleTVSimulator" "AppleTVSimulator" "${fat_dir}/appletvsimulator/lib${lib_name}.a" "$appletvsimulator_framework" \
  "MinimumOSVersion" "$tvos_min_version" \
  -arch x86_64 -arch arm64 -mtvos-simulator-version-min="$tvos_min_version"

link_dynamic_framework_from_archives "XROS" "XROS" "$xros_framework" \
  "MinimumOSVersion" "$visionos_min_version" \
  "arm64:arm64-apple-xros${visionos_min_version}:${xros_lib}"

link_dynamic_framework_from_archives "XRSimulator" "XRSimulator" "$xrsimulator_framework" \
  "MinimumOSVersion" "$visionos_min_version" \
  "x86_64:x86_64-apple-xros${visionos_min_version}-simulator:${xrsimulator_x86_64_lib}" \
  "arm64:arm64-apple-xros${visionos_min_version}-simulator:${xrsimulator_arm64_lib}"

link_dynamic_framework "WatchOS" "WatchOS" "${fat_dir}/watchos/lib${lib_name}.a" "$watchos_framework" \
  "MinimumOSVersion" "$watchos_min_version" \
  -arch arm64_32 -arch arm64 -mwatchos-version-min="$watchos_min_version"

link_dynamic_framework "WatchSimulator" "WatchSimulator" "${fat_dir}/watchsimulator/lib${lib_name}.a" "$watchsimulator_framework" \
  "MinimumOSVersion" "$watchos_min_version" \
  -arch x86_64 -arch arm64 -mwatchos-simulator-version-min="$watchos_min_version"

framework_slices=(
  "$iphoneos_framework"
  "$iphonesimulator_framework"
  "$macos_framework"
  "$appletvos_framework"
  "$appletvsimulator_framework"
  "$xros_framework"
  "$xrsimulator_framework"
  "$watchos_framework"
  "$watchsimulator_framework"
)

for framework in "${framework_slices[@]}"; do
  create_debug_symbols "$framework"
done

iphoneos_dsym="$(absolute_path "${iphoneos_framework}.dSYM")"
iphonesimulator_dsym="$(absolute_path "${iphonesimulator_framework}.dSYM")"
macos_dsym="$(absolute_path "${macos_framework}.dSYM")"
appletvos_dsym="$(absolute_path "${appletvos_framework}.dSYM")"
appletvsimulator_dsym="$(absolute_path "${appletvsimulator_framework}.dSYM")"
xros_dsym="$(absolute_path "${xros_framework}.dSYM")"
xrsimulator_dsym="$(absolute_path "${xrsimulator_framework}.dSYM")"
watchos_dsym="$(absolute_path "${watchos_framework}.dSYM")"
watchsimulator_dsym="$(absolute_path "${watchsimulator_framework}.dSYM")"

xcodebuild -create-xcframework \
  -framework "$iphoneos_framework" \
  -debug-symbols "$iphoneos_dsym" \
  -framework "$iphonesimulator_framework" \
  -debug-symbols "$iphonesimulator_dsym" \
  -framework "$macos_framework" \
  -debug-symbols "$macos_dsym" \
  -framework "$appletvos_framework" \
  -debug-symbols "$appletvos_dsym" \
  -framework "$appletvsimulator_framework" \
  -debug-symbols "$appletvsimulator_dsym" \
  -framework "$xros_framework" \
  -debug-symbols "$xros_dsym" \
  -framework "$xrsimulator_framework" \
  -debug-symbols "$xrsimulator_dsym" \
  -framework "$watchos_framework" \
  -debug-symbols "$watchos_dsym" \
  -framework "$watchsimulator_framework" \
  -debug-symbols "$watchsimulator_dsym" \
  -output "$xcframework_path"

echo "Created ${xcframework_path}"
