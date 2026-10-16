#!/bin/bash
# Usage: sudo ./install.sh "/Applications/tbswitcher_resources/DisableTurboBoost.64bits.kext"
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo "Run with sudo."; exit 1; fi
HERE="$(cd "$(dirname "$0")" && pwd)"
KEXT_SRC="${1:-}"
[[ -d "$KEXT_SRC" ]] || { echo "Pass the path to the ORIGINAL DisableTurboBoost.64bits.kext (unmodified)."; exit 1; }
[[ -x "$HERE/build/tbhelper" && -d "$HERE/build/TBSwitcher.app" ]] || { echo "Run ./build.sh first."; exit 1; }

ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$KEXT_SRC/Contents/Info.plist")
[[ "$ID" == "com.rugarciap.DisableTurboBoost" ]] || { echo "Unexpected kext bundle id: $ID"; exit 1; }
echo "--- kext signature ---"
codesign -dv "$KEXT_SRC" 2>&1 | grep -E 'Identifier|TeamIdentifier|Authority' || echo "WARNING: kext is not signed"
echo "----------------------"

LABEL=local.tbswitcher.helper
SUP=/Library/PrivilegedHelperTools/$LABEL
PLIST=/Library/LaunchDaemons/$LABEL.plist

launchctl bootout system/$LABEL 2>/dev/null || true
rm -rf "$SUP" /Applications/TBSwitcher.app
mkdir -p "$SUP"
ditto "$KEXT_SRC" "$SUP/DisableTurboBoost.64bits.kext"     # ditto keeps the original signature
install -m 755 "$HERE/build/tbhelper" "$SUP/tbhelper"
ditto "$HERE/build/TBSwitcher.app" /Applications/TBSwitcher.app
chown -R root:wheel "$SUP" /Applications/TBSwitcher.app
chmod -R u+rwX,go+rX,go-w "$SUP" /Applications/TBSwitcher.app

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key><array><string>$SUP/tbhelper</string></array>
    <key>MachServices</key><dict><key>$LABEL</key><true/></dict>
</dict>
</plist>
PLISTEOF
chown root:wheel "$PLIST"; chmod 644 "$PLIST"
launchctl bootstrap system "$PLIST"

echo "Installed. Starting the app..."
[[ -n "${SUDO_USER:-}" ]] && sudo -u "$SUDO_USER" open /Applications/TBSwitcher.app || true
