#!/usr/bin/env bash
set -ex

# Set variables
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OUTPUT_DIR="${OUTPUT_DIR:-${SRC_DIR}/output}"
readonly DEVELOPER=$(xcode-select --print-path)
readonly PLATFORMSROOT="${DEVELOPER}/Platforms"
export IOS_MIN_VERSION="${IOS_MIN_VERSION:-8.0}"
export MACOS_MIN_VERSION="${MACOS_MIN_VERSION:-10.9}"
export TVOS_MIN_VERSION="${TVOS_MIN_VERSION:-12.0}"
export VISIONOS_MIN_VERSION="${VISIONOS_MIN_VERSION:-1.0}"
export WATCHOS_MIN_VERSION="${WATCHOS_MIN_VERSION:-6.0}"

aclocal && autoconf && automake --add-missing

# Create output directory
mkdir -p "$OUTPUT_DIR"

config_library() {
    local platform=$1
    local arch=$2
    local sdk=$3
    
    ROOTDIR="${OUTPUT_DIR}/${platform}-${arch}-${sdk}"
    mkdir -p "${ROOTDIR}"

    SDKROOT="${PLATFORMSROOT}/"
    SDKROOT+="${sdk}.platform/Developer/SDKs/${sdk}.sdk/"
    CFLAGS="-arch ${ARCH2:-${arch}} -pipe -isysroot ${SDKROOT} -O3 -g -DNDEBUG"
    CXX_TARGET_FLAGS="-arch ${ARCH2:-${arch}} "

    if [[ ${platform} == "iphoneos" ]]; then
        CFLAGS+=" -miphoneos-version-min=${IOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi
    if [[ ${platform} == "iphonesimulator" ]]; then
        CFLAGS+=" -mios-simulator-version-min=${IOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi
    if [[ ${platform} == "appletvos" ]]; then
        CFLAGS+=" -mtvos-version-min=${TVOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi
    if [[ ${platform} == "appletvsimulator" ]]; then
        CFLAGS+=" -mtvos-simulator-version-min=${TVOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi
    if [[ ${platform} == "xros" ]]; then
        CFLAGS+=" -target ${arch}-apple-xros${VISIONOS_MIN_VERSION} ${EXTRA_CFLAGS}"
        CXX_TARGET_FLAGS="-target ${arch}-apple-xros${VISIONOS_MIN_VERSION} "
    fi
    if [[ ${platform} == "xrsimulator" ]]; then
        CFLAGS+=" -target ${arch}-apple-xros${VISIONOS_MIN_VERSION}-simulator ${EXTRA_CFLAGS}"
        CXX_TARGET_FLAGS="-target ${arch}-apple-xros${VISIONOS_MIN_VERSION}-simulator "
    fi
    if [[ ${platform} == "watchos" ]]; then
        CFLAGS+=" -mwatchos-version-min=${WATCHOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi
    if [[ ${platform} == "watchsimulator" ]]; then
        CFLAGS+=" -mwatchos-simulator-version-min=${WATCHOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi
    if [[ ${platform} == "macosx" ]]; then
        CFLAGS+=" -mmacosx-version-min=${MACOS_MIN_VERSION} ${EXTRA_CFLAGS}"
    fi

    CXX="xcrun --sdk ${platform} clang++ "
    CONFIGURE_HOST_ARCH="${arch}"
    if [[ ${arch} == "arm64_32" ]]; then
        CONFIGURE_HOST_ARCH="arm"
    fi
    
    ${SRC_DIR}/configure --host=${CONFIGURE_HOST_ARCH}-apple-darwin --prefix=${ROOTDIR} \
    --build=$(${SRC_DIR}/config.guess) \
    --disable-shared --enable-static \
    CXX="${CXX} ${CXX_TARGET_FLAGS}" \
    CFLAGS="${CFLAGS}" \
	  CXXFLAGS="${CFLAGS} -isystem ${SDKROOT}/usr/include"
}

# Function to build for a specific platform and architecture
build_library() {
    local platform=$1
    local arch=$2
    local sdk=$3
    local out_dir="$OUTPUT_DIR/$platform-$arch-$sdk"

    mkdir -p "$out_dir"

    config_library $platform $arch $sdk
  
    make -j4 V=0
    make install
    make clean
}

create_xcframework() {
    local lib_name=$1

    case "$lib_name" in
      opencore-amrnb)
        "${SRC_DIR}/scripts/package_framework_xcframework.sh" \
          "opencore-amrnb" \
          "OpenCoreAMRNB" \
          "io.github.kuailliao.OpenCoreAMRNB" \
          "amrnb/interf_dec.h" \
          "amrnb/interf_enc.h"
        ;;
      opencore-amrwb)
        "${SRC_DIR}/scripts/package_framework_xcframework.sh" \
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
}

# Build for different platforms and architectures
build_library "macosx" "arm64" "MacOSX"
build_library "macosx" "x86_64" "MacOSX"
build_library "iphoneos" "arm64" "iPhoneOS"
build_library "iphonesimulator" "x86_64" "iPhoneSimulator"
build_library "iphonesimulator" "arm64" "iPhoneSimulator"
build_library "appletvos" "arm64" "AppleTVOS"
build_library "appletvsimulator" "x86_64" "AppleTVSimulator"
build_library "appletvsimulator" "arm64" "AppleTVSimulator"
build_library "xros" "arm64" "XROS"
build_library "xrsimulator" "x86_64" "XRSimulator"
build_library "xrsimulator" "arm64" "XRSimulator"
build_library "watchos" "arm64_32" "WatchOS"
build_library "watchos" "arm64" "WatchOS"
build_library "watchsimulator" "x86_64" "WatchSimulator"
build_library "watchsimulator" "arm64" "WatchSimulator"


# Create framework-based XCFrameworks
rm -rf "${OUTPUT_DIR}/OpenCoreAMRNB.xcframework"
create_xcframework "opencore-amrnb"

rm -rf "${OUTPUT_DIR}/OpenCoreAMRWB.xcframework"
create_xcframework "opencore-amrwb"

"${SRC_DIR}/scripts/validate_xcframeworks.sh" "$OUTPUT_DIR"

echo "Universal XCFramework built successfully in $OUTPUT_DIR"
