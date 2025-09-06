param([switch]$WithEmulator)

# Build the Rust audio engine for Android and copy the resulting .so into the Flutter project.
# Requires cargo-ndk to be installed (`cargo install cargo-ndk`).
# Run this from the repository root or via the script path.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

pushd (Split-Path $PSCommandPath)
try {
    # Navigate into the engine crate
    Set-Location ..\engine

    # Ensure the target is installed
    rustup target add aarch64-linux-android | Out-Null

    # Build the engine for arm64-v8a.  Add other -t arguments if you need more ABIs.
    cargo ndk -t arm64-v8a -o ..\app\android\app\src\main\jniLibs build --release
} finally {
    popd
}
