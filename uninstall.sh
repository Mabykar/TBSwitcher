#!/bin/bash
# Removes TBSwitcher completely: app, helper, launch daemon, saved settings. Turbo Boost goes back to normal.
# Usage:  bash uninstall.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
if [[ $EUID -ne 0 ]]; then exec sudo bash "$HERE/uninstall.sh" "$@"; fi

LABEL=local.tbswitcher.helper
/sbin/kextunload -b com.rugarciap.DisableTurboBoost 2>/dev/null || true
launchctl bootout system/$LABEL 2>/dev/null || true
pkill -x TBSwitcher 2>/dev/null || true
rm -rf "/Library/PrivilegedHelperTools/$LABEL" "/Library/LaunchDaemons/$LABEL.plist" /Applications/TBSwitcher.app
if [[ -n "${SUDO_USER:-}" ]]; then sudo -u "$SUDO_USER" defaults delete local.tbswitcher.app 2>/dev/null || true; fi

echo "TBSwitcher removed. Turbo Boost is back to normal."
echo "(macOS may keep listing the extension under Privacy & Security until the next restart.)"
