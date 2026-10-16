#!/bin/bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo "Run with sudo."; exit 1; fi
LABEL=local.tbswitcher.helper
/sbin/kextunload -b com.rugarciap.DisableTurboBoost 2>/dev/null || true
launchctl bootout system/$LABEL 2>/dev/null || true
pkill -x TBSwitcher 2>/dev/null || true
rm -rf /Library/PrivilegedHelperTools/$LABEL /Library/LaunchDaemons/$LABEL.plist /Applications/TBSwitcher.app
echo "Removed."
