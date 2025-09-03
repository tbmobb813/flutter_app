#!/usr/bin/env bash
set -euo pipefail


# Requires: rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
# And ANDROID_NDK_HOME set


if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
echo "Set ANDROID_NDK_HOME to your NDK path"; exit 1
fi


API=24
CRATE_DIR=$(cd "$(dirname "$0")/../audio_engine" && pwd)
OUT_DIR="$CRATE_DIR/../out/android"
mkdir -p "$OUT_DIR"


build_arch(){
local target="$1"; local triple="$2"; local abi="$3";
export CARGO_TARGET_${target//-/_}_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/${triple}${API}-clang"
cargo +stable build --manifest-path "$CRATE_DIR/Cargo.toml" --target "$target" --release
mkdir -p "$OUT_DIR/$abi"
cp "$CRATE_DIR/target/$target/release/libsoundcore.so" "$OUT_DIR/$abi/"
}


build_arch aarch64-linux-android aarch64-linux-android- arm64-v8a
build_arch armv7-linux-androideabi armv7a-linux-androideabi- armeabi-v7a
build_arch x86_64-linux-android x86_64-linux-android- x86_64


echo "Copy the .so folders into flutter_app/android/app/src/main/jniLibs/"