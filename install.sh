#!/usr/bin/env bash
set -euo pipefail

# Build SGIT and install the released binary into a location on PATH.

INSTALL_DIR="${SGIT_INSTALL_DIR:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="$SCRIPT_DIR/sgit/target/release/sgit"

echo "Building SGIT..."
cargo build --release --manifest-path "$SCRIPT_DIR/sgit/Cargo.toml"

echo "Installing SGIT to $INSTALL_DIR..."
install -Dm755 "$TARGET_BIN" "$INSTALL_DIR/sgit"

echo "SGIT installed at $INSTALL_DIR/sgit."
echo "Re-run this script to rebuild and update the binary."
