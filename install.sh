#!/bin/bash
# TBSwitcher installer — builds the app, asks for your admin password ONCE, installs everything.
# Usage:  bash install.sh [--kext /path/to/DisableTurboBoost.64bits.kext]
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
ORIG_ARGS=("$@")

say() { printf '%s\n' "$*"; }
ok()  { printf '  ✓ %s\n' "$*"; }
die() { printf '\n✗ %s\n' "$*" >&2; exit 1; }

KEXT_ARG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kext) [[ $# -ge 2 ]] || die "--kext needs a path"; KEXT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) KEXT_ARG="$1"; shift ;;   # old style: bash install.sh /path/to.kext
  esac
done

if ! sysctl -n machdep.cpu.brand_string | grep -qi intel; then
  die "This Mac does not have an Intel CPU. Turbo Boost can't be controlled this way on Apple Silicon."
fi

# ---- as a normal user: build, then re-run ourselves with sudo (one password prompt)
if [[ $EUID -ne 0 ]]; then
  say "TBSwitcher installer"
  say "1/3 Building…"
  bash "$HERE/build.sh" >/dev/null || die "Build failed. Run 'bash build.sh' to see the error (no Swift? run: xcode-select --install)."
  ok "built"
  say "2/3 Administrator password is needed once to install the helper."
  exec sudo bash "$HERE/install.sh" ${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"}
fi

# ---- from here on we are root
[[ -x build/tbhelper && -d build/TBSwitcher.app ]] || die "Build output missing. Run 'bash install.sh' as a normal user (without sudo)."

is_signed() { codesign --verify --strict "$1" >/dev/null 2>&1; }

# Pick the kext: --kext PATH, else Vendor/, else the official app's. A code-signed one is preferred;
# an unsigned one is still used (it can load on some Macs) but we say so.
KEXT_SRC=""
UNSIGNED_FALLBACK=""
if [[ -n "$KEXT_ARG" ]]; then
  [[ -d "$KEXT_ARG" ]] || die "Kext not found: $KEXT_ARG"
  KEXT_SRC="$KEXT_ARG"
else
  for c in "$HERE/Vendor/DisableTurboBoost.64bits.kext" \
           "/Applications/Turbo Boost Switcher.app/Contents/Resources/DisableTurboBoost.64bits.kext"; do
    [[ -d "$c" ]] || continue
    if is_signed "$c"; then KEXT_SRC="$c"; break; fi
    [[ -n "$UNSIGNED_FALLBACK" ]] || UNSIGNED_FALLBACK="$c"
  done
  [[ -n "$KEXT_SRC" ]] || KEXT_SRC="$UNSIGNED_FALLBACK"
fi
[[ -n "$KEXT_SRC" ]] || die "No kext found. Put DisableTurboBoost.64bits.kext into Vendor/ or run: bash install.sh --kext /path/to/it"

ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$KEXT_SRC/Contents/Info.plist" 2>/dev/null || true)
[[ "$ID" == "com.rugarciap.DisableTurboBoost" ]] || die "Unexpected kext bundle id: '$ID'"
ok "kext: $KEXT_SRC"
if is_signed "$KEXT_SRC"; then
  codesign -dv "$KEXT_SRC" 2>&1 | grep -E 'TeamIdentifier|Authority=' | sed 's/^/      /' || true
else
  say "  ! This kext is not code-signed. It does load on some Macs; if macOS refuses it, see README → 'About the kext and signing'."
fi

say "3/3 Installing…"
LABEL=local.tbswitcher.helper
SUP=/Library/PrivilegedHelperTools/$LABEL
PLIST=/Library/LaunchDaemons/$LABEL.plist
APP=/Applications/TBSwitcher.app

pkill -x TBSwitcher 2>/dev/null || true
launchctl bootout system/$LABEL 2>/dev/null || true
rm -rf "$SUP" "$APP"
mkdir -p "$SUP"
ditto "$KEXT_SRC" "$SUP/DisableTurboBoost.64bits.kext"     # ditto keeps the original bytes and any signature
install -m 755 "$HERE/build/tbhelper" "$SUP/tbhelper"
ditto "$HERE/build/TBSwitcher.app" "$APP"
chown -R root:wheel "$SUP" "$APP"
chmod -R u+rwX,go+rX,go-w "$SUP" "$APP"

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
ok "helper installed (starts on demand)"
ok "app installed: $APP"

if [[ -n "${SUDO_USER:-}" ]]; then sudo -u "$SUDO_USER" open "$APP" || true; fi

cat <<'DONE'

Done. Look for the ⚡ icon in your menu bar.
  • Left-click  = toggle Turbo Boost.   Right-click = menu (launch at login, credits, quit).
  • First time, macOS may ask you to allow the extension:
    System Settings → Privacy & Security → "Allow", then restart and click ⚡ again.
  • Something wrong?  bash doctor.sh
DONE
