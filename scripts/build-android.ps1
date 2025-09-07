param([switch]$WithEmulator)

# Run from the repo root or via this script’s path.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Push-Location (Split-Path $PSCommandPath)
try {
    # Navigate into the audio_engine crate (not the root soundcore crate)
    Set-Location ..\engine\audio_engine

    # Ensure the aarch64 target is installed
    rustup target add aarch64-linux-android | Out-Null

    # Build the audio_engine crate for arm64‑v8a and output into the Flutter jniLibs folder.
    # Adjust the path if you need other ABIs (e.g. add -t armeabi‑v7a).
    cargo ndk -t arm64-v8a -o ..\..\android\app\src\main\jniLibs build --release
}
finally {
    Pop-Location
}
