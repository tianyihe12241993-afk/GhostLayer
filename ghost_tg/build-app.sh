#!/bin/bash
# Build GhostTG and assemble a runnable .app bundle. Works with just the
# Command Line Tools (no full Xcode). Produces a universal (Intel + Apple
# Silicon) binary so it runs on any Mac.
set -euo pipefail
cd "$(dirname "$0")"

ARCHS=(--arch arm64 --arch x86_64)
swift build -c release "${ARCHS[@]}"
BIN=$(swift build -c release "${ARCHS[@]}" --show-bin-path)

APP="GhostTG.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN/GhostTG" "$APP/Contents/MacOS/GhostTG"
cp Info.plist "$APP/Contents/Info.plist"

# Ad-hoc signature — unsigned apps won't launch on modern macOS.
codesign --force --sign - "$APP"

echo "Built $PWD/$APP"
lipo -info "$APP/Contents/MacOS/GhostTG" || true
