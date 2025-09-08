# Build the Rust audio engine for Windows.  This outputs engine.dll in the target folder.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

pushd (Split-Path $PSCommandPath)
try {
    Set-Location ..\engine
    rustup target add x86_64-pc-windows-msvc | Out-Null
    cargo build --release --target x86_64-pc-windows-msvc
} finally {
    popd
}
