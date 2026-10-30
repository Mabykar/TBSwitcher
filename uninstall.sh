#!/bin/bash
# Removes TBSwitcher completely: app, helper, launch daemon, saved settings. Turbo Boost goes back to normal.
# Usage:  bash uninstall.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
if [[ $EUID -ne 0 ]]; then exec sudo bash "$HERE/uninstall.sh" "$@"; fi

LABEL=local.tbswitcher.helper
pkill -x TBSwitcher 2>/dev/null || true
UNLOADED=false
if /sbin/kextunload -b com.rugarciap.DisableTurboBoost 2>/dev/null ||
   /usr/bin/kmutil unload -b com.rugarciap.DisableTurboBoost 2>/dev/null; then
  UNLOADED=true
fi
launchctl bootout system/$LABEL 2>/dev/null || true
pkill -x TBSwitcher 2>/dev/null || true
rm -rf "/Library/PrivilegedHelperTools/$LABEL" "/Library/LaunchDaemons/$LABEL.plist" /Applications/TBSwitcher.app
if [[ -n "${SUDO_USER:-}" ]]; then sudo -u "$SUDO_USER" defaults delete local.tbswitcher.app 2>/dev/null || true; fi

echo "TBSwitcher removed."
if [[ "$UNLOADED" == true ]]; then
  echo "The extension was unloaded."
else
  echo "Could not confirm extension unload. Restart your Mac to restore the default Turbo Boost state."
fi
echo "(macOS may keep listing the extension under Privacy & Security until the next restart.)"
