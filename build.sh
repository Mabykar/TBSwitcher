#!/bin/bash
# Builds the app and helper into ./build for development and release packaging.
set -euo pipefail
cd "$(dirname "$0")"

command -v swift >/dev/null || { echo "Swift not found. Install the Command Line Tools:  xcode-select --install" >&2; exit 1; }

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

APP=build/TBSwitcher.app
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/TBSwitcher" "$APP/Contents/MacOS/TBSwitcher"
cp Info.plist "$APP/Contents/Info.plist"

# App icon: Sources/Assets/ico.png -> AppIcon.icns (sips and iconutil ship with macOS).
ICON_SRC="Sources/Assets/ico.png"
if [[ -f "$ICON_SRC" ]]; then
  ISET="build/AppIcon.iconset"
  mkdir -p "$ISET"
  W=$(sips -g pixelWidth "$ICON_SRC" | awk '/pixelWidth/ {print $2}')
  mkicon() {   # <pixels> <file name>; sizes bigger than the source are skipped
    if [[ "$1" -le "$W" ]]; then sips -z "$1" "$1" "$ICON_SRC" --out "$ISET/$2" >/dev/null; fi
  }
  mkicon 16 icon_16x16.png;     mkicon 32 icon_16x16@2x.png
  mkicon 32 icon_32x32.png;     mkicon 64 icon_32x32@2x.png
  mkicon 128 icon_128x128.png;  mkicon 256 icon_128x128@2x.png
  mkicon 256 icon_256x256.png;  mkicon 512 icon_256x256@2x.png
  mkicon 512 icon_512x512.png;  mkicon 1024 icon_512x512@2x.png
  iconutil -c icns "$ISET" -o "$APP/Contents/Resources/AppIcon.icns" || echo "warning: could not build the icon, continuing without it"
  rm -rf "$ISET"
else
  echo "note: $ICON_SRC not found, building without an app icon"
fi

# Ad-hoc signature + hardened runtime (blocks DYLD injection into the app that talks to the root helper).
codesign --force --options runtime --sign - "$APP"
cp "$BIN/TBHelper" build/TBHelper
echo "Built: $APP and build/TBHelper"
