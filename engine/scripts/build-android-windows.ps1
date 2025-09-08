# PowerShell script for building Android audio engine on Windows
param(
    [string]$AndroidNDK = $env:ANDROID_NDK_HOME
)

# Check if Android NDK is available
if (-not $AndroidNDK) {
    # Try common Android SDK locations
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\ndk",
        "$env:ANDROID_HOME\ndk", 
        "C:\Android\Sdk\ndk",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\ndk"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $ndkVersions = Get-ChildItem $path -Directory | Sort-Object Name -Descending
            if ($ndkVersions.Count -gt 0) {
                $AndroidNDK = $ndkVersions[0].FullName
                Write-Host "Found Android NDK at: $AndroidNDK"
                break
            }
        }
    }
}

if (-not $AndroidNDK -or -not (Test-Path $AndroidNDK)) {
    Write-Error "Android NDK not found. Please set ANDROID_NDK_HOME environment variable or install Android SDK with NDK."
    exit 1
}

# Set environment variables
$env:ANDROID_NDK_HOME = $AndroidNDK
$API = "24"
$CRATE_DIR = Resolve-Path "$PSScriptRoot\..\audio_engine"
$OUT_DIR = "$CRATE_DIR\..\out\android"

# Create output directory
New-Item -ItemType Directory -Force -Path $OUT_DIR | Out-Null

Write-Host "Building for Android..."
Write-Host "NDK Path: $AndroidNDK"
Write-Host "Crate Dir: $CRATE_DIR"
Write-Host "Output Dir: $OUT_DIR"

function Build-Arch {
    param($target, $triple, $abi)
    
    Write-Host "Building for $abi ($target)..."
    
    # Build with cargo using linker from .cargo/config.toml
    $buildResult = & cargo build --manifest-path "$CRATE_DIR\Cargo.toml" --target $target --release

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build for $target"
        return $false
    }

    # Copy library to output
    $abiDir = "$OUT_DIR\$abi"
    New-Item -ItemType Directory -Force -Path $abiDir | Out-Null

    $libSource = "$CRATE_DIR\target\$target\release\libaudio_engine.so"
    $libDest = "$abiDir\libaudio_engine.so"

    if (Test-Path $libSource) {
        Copy-Item $libSource $libDest -Force
        Write-Host "✓ Built $abi library: $(Get-Item $libDest | Select-Object -ExpandProperty Length) bytes"
        return $true
    } else {
        Write-Error "Library not found: $libSource"
        return $false
    }
}

# Build for different architectures
$success = $true
$success = (Build-Arch "aarch64-linux-android" "aarch64-linux-android" "arm64-v8a") -and $success
$success = (Build-Arch "armv7-linux-androideabi" "armv7a-linux-androideabi" "armeabi-v7a") -and $success
$success = (Build-Arch "x86_64-linux-android" "x86_64-linux-android" "x86_64") -and $success

if ($success) {
    Write-Host "`n✅ Build completed successfully!"
    Write-Host "Copy the .so files to: android\app\src\main\jniLibs\"
    
    # Automatically copy to Flutter project if jniLibs exists
    $jniLibsDir = "$PSScriptRoot\..\..\android\app\src\main\jniLibs"
    if (Test-Path "$PSScriptRoot\..\..\android") {
        Write-Host "`nCopying libraries to Flutter project..."
        New-Item -ItemType Directory -Force -Path $jniLibsDir | Out-Null
        Copy-Item "$OUT_DIR\*" $jniLibsDir -Recurse -Force
        Write-Host "✓ Libraries copied to jniLibs"
    }
} else {
    Write-Error "Build failed!"
    exit 1
}
