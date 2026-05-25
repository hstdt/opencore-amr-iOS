#!/bin/bash
set -ex

platform=$1
arch=$2
sdk=$3
OUTPUT_DIR="${GITHUB_WORKSPACE}/output"
DEVELOPER=$(xcode-select --print-path)
PLATFORMSROOT="${DEVELOPER}/Platforms"
IOS_MIN_VERSION="${IOS_MIN_VERSION:-8.0}"
MACOS_MIN_VERSION="${MACOS_MIN_VERSION:-10.9}"
TVOS_MIN_VERSION="${TVOS_MIN_VERSION:-12.0}"
VISIONOS_MIN_VERSION="${VISIONOS_MIN_VERSION:-1.0}"
WATCHOS_MIN_VERSION="${WATCHOS_MIN_VERSION:-6.0}"

config_library() {
    ROOTDIR="${OUTPUT_DIR}/${platform}-${arch}-${sdk}"
    mkdir -p "${ROOTDIR}"

    SDKROOT="${PLATFORMSROOT}/${sdk}.platform/Developer/SDKs/${sdk}.sdk/"
    CFLAGS="-arch ${ARCH2:-${arch}} -pipe -isysroot ${SDKROOT} -O3 -DNDEBUG"
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
    
    ./configure --host=${CONFIGURE_HOST_ARCH}-apple-darwin --prefix=${ROOTDIR} \
    --build=$(./config.guess) \
    --disable-shared --enable-static \
    CXX="${CXX} ${CXX_TARGET_FLAGS}" \
    CFLAGS="${CFLAGS}" \
    CXXFLAGS="${CFLAGS} -isystem ${SDKROOT}/usr/include"
}

config_library

make -j4 V=0
make install
make clean
