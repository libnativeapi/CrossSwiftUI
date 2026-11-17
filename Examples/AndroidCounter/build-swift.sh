#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
output=${1:?Pass the generated jniLibs directory and at least one Android ABI}
shift
if [[ $# == 0 ]]; then
  echo 'Pass at least one Android ABI (arm64-v8a or x86_64).' >&2
  exit 1
fi

: "${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME to the Android NDK r30 directory}"
ndk_toolchains=("$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*)
ndk=${ndk_toolchains[0]}
if [[ ! -x "$ndk/bin/llvm-strip" ]]; then
  echo "No LLVM tools found under $ANDROID_NDK_HOME" >&2
  exit 1
fi

swift=${SWIFT_TOOLCHAIN_BIN:+$SWIFT_TOOLCHAIN_BIN/}swift
sdk_options=(--swift-sdk swift-6.4.2-RELEASE_android)
if [[ -n ${SWIFTUI_ANDROID_SDKS_PATH:-} ]]; then
  sdk_options+=(--swift-sdks-path "$SWIFTUI_ANDROID_SDKS_PATH")
fi
export SWIFTUI_PORT_ANDROID=1

for abi in "$@"; do
  case "$abi" in
    arm64-v8a) arch=aarch64 ;;
    x86_64) arch=x86_64 ;;
    *) echo "Unsupported Android ABI: $abi" >&2; exit 1 ;;
  esac

  options=(--package-path "$repo" --scratch-path "$repo/.build/android/$abi"
    "${sdk_options[@]}" --triple "$arch-unknown-linux-android23" --static-swift-stdlib
    --configuration release --product AndroidCounter)
  "$swift" build "${options[@]}"
  bin=$("$swift" build "${options[@]}" --show-bin-path)
  mkdir -p "$output/$abi"
  "$ndk/bin/llvm-strip" --strip-unneeded "$bin/libAndroidCounter.so" -o "$output/$abi/libAndroidCounter.so"
  "$ndk/bin/llvm-strip" --strip-unneeded \
    "$ndk/sysroot/usr/lib/$arch-linux-android/libc++_shared.so" -o "$output/$abi/libc++_shared.so"
done
