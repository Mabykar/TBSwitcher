#!/bin/bash
# Builds the app and the helper into ./build (you normally don't run this directly: use install.sh).
set -euo pipefail
cd "$(dirname "$0")"

command -v swift >/dev/null || { echo "Swift not found. Install the Command Line Tools:  xcode-select --install" >&2; exit 1; }

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

rm -rf build && mkdir -p build/TBSwitcher.app/Contents/MacOS
cp "$BIN/TBSwitcher" build/TBSwitcher.app/Contents/MacOS/TBSwitcher
cp Info.plist build/TBSwitcher.app/Contents/Info.plist
# Ad-hoc signature + hardened runtime (blocks DYLD injection into the app that talks to the root helper).
codesign --force --options runtime --sign - build/TBSwitcher.app
cp "$BIN/tbhelper" build/tbhelper
echo "Built: build/TBSwitcher.app and build/tbhelper"
