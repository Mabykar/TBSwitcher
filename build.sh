#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
BIN="$(swift build -c release --show-bin-path)"
rm -rf build && mkdir -p build/TBSwitcher.app/Contents/MacOS
cp "$BIN/TBSwitcher" build/TBSwitcher.app/Contents/MacOS/TBSwitcher
cp Info.plist build/TBSwitcher.app/Contents/Info.plist
codesign --force --sign - build/TBSwitcher.app
cp "$BIN/tbhelper" build/tbhelper
echo "Built: build/TBSwitcher.app and build/tbhelper"
