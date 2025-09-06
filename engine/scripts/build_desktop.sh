#!/usr/bin/env bash
set -euo pipefail

# Build script for desktop testing
CRATE_DIR=$(cd "$(dirname "$0")/audio_engine" && pwd)
OUT_DIR="$CRATE_DIR/../out/desktop"
mkdir -p "$OUT_DIR"

echo "Building Rust audio engine for desktop..."
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release

# Copy to out directory
cp "$CRATE_DIR/target/release/libsoundcore.so" "$OUT_DIR/"

echo "Desktop library built at: $OUT_DIR/libsoundcore.so"
echo "Run 'export LD_LIBRARY_PATH=$OUT_DIR:$LD_LIBRARY_PATH' before testing"
