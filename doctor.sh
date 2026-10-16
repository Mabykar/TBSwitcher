#!/bin/bash
# Prints a diagnostic report. Read-only, no sudo needed. Paste the output into a GitHub issue.
HERE="$(cd "$(dirname "$0")" && pwd)"
row() { printf '%-18s %s\n' "$1" "$2"; }

echo "TBSwitcher doctor"
echo "-----------------"
row "macOS"  "$(sw_vers -productVersion) ($(sw_vers -buildVersion))"
row "CPU"    "$(sysctl -n machdep.cpu.brand_string)"
if sysctl -n machdep.cpu.brand_string | grep -qi intel; then
  row "Intel Mac" "yes"
else
  row "Intel Mac" "NO — Turbo Boost can't be controlled on this Mac"
fi
row "SIP" "$(csrutil status 2>/dev/null | sed 's/.*: //' || echo unknown)"

for k in "$HERE/Vendor/DisableTurboBoost.64bits.kext" \
         "/Applications/Turbo Boost Switcher.app/Contents/Resources/DisableTurboBoost.64bits.kext"; do
  if [[ -d "$k" ]]; then
    if codesign --verify --strict "$k" >/dev/null 2>&1; then s="signed ✓"; else s="NOT signed ✗ (macOS will refuse it)"; fi
    row "kext" "$s"
    row "" "$k"
  fi
done

[[ -d /Applications/TBSwitcher.app ]] && row "app" "installed" || row "app" "not installed  → bash install.sh"
[[ -x /Library/PrivilegedHelperTools/local.tbswitcher.helper/tbhelper ]] && row "helper" "installed" || row "helper" "not installed  → bash install.sh"
[[ -f /Library/LaunchDaemons/local.tbswitcher.helper.plist ]] && row "launch daemon" "present" || row "launch daemon" "missing"

if /usr/sbin/kextstat -l 2>/dev/null | grep -q com.rugarciap.DisableTurboBoost; then
  row "Turbo Boost" "OFF (kext loaded)"
else
  row "Turbo Boost" "ON (kext not loaded)"
fi
