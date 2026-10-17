#!/bin/bash
# TBSwitcher one-line installer.
#
#   Install:    curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | bash
#   Uninstall:  curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | bash -s -- --uninstall
#   Pin a version (branch, tag or commit):
#               curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | TBSWITCHER_REF=v1.2.0 bash
#
# Please read this script before running it: it ends up installing a root helper and a kernel extension.
# It downloads the source into a temporary folder, tells you what it will do, asks for confirmation,
# then runs install.sh (build + one admin password prompt). The temporary folder is deleted afterwards.
set -euo pipefail

REPO="Mabykar/TBSwitcher"
REF="${TBSWITCHER_REF:-main}"
MODE="install"
[[ "${1:-}" == "--uninstall" ]] && MODE="uninstall"

die() { printf '\n✗ %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "TBSwitcher is for macOS."
sysctl -n machdep.cpu.brand_string | grep -qi intel || die "Intel Mac required (Apple Silicon has no Turbo Boost to control)."
command -v curl >/dev/null 2>&1 || die "curl not found."
if [[ "$MODE" == "install" ]]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    die "Command Line Tools are missing. Run:  xcode-select --install   then run this command again."
  fi
fi

# ---- tell the user what is about to happen and ask (via the terminal, since stdin is the pipe)
if [[ "${TBSWITCHER_YES:-}" != "1" ]]; then
  [[ -r /dev/tty ]] || die "No terminal available to ask for confirmation. Re-run with TBSWITCHER_YES=1 if you are sure."
  if [[ "$MODE" == "install" ]]; then
    cat <<EOF

TBSwitcher  ($REPO @ $REF)
This will:
  1. download the source into a temporary folder and build it
  2. ask for your admin password ONCE
  3. install: /Applications/TBSwitcher.app, a root helper in /Library/PrivilegedHelperTools,
     a LaunchDaemon plist, and the Turbo Boost kernel extension used by the helper
EOF
  else
    printf '\nThis will remove TBSwitcher (app, helper, LaunchDaemon) and unload its kext.\n'
  fi
  read -r -p "Continue? [y/N] " ans < /dev/tty
  [[ "$ans" =~ ^[Yy]$ ]] || die "Cancelled."
fi

# ---- download
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf 'Downloading %s @ %s …\n' "$REPO" "$REF"
curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" | tar -xz -C "$TMP" --strip-components=1 \
  || die "Download failed. Check that '$REF' exists and that the repository is public."
cd "$TMP"

run() { if [[ -r /dev/tty ]]; then bash "$@" < /dev/tty; else bash "$@"; fi; }

if [[ "$MODE" == "uninstall" ]]; then
  run uninstall.sh
else
  run install.sh
  printf '\nTo uninstall later:\n  curl -fsSL https://raw.githubusercontent.com/%s/main/get.sh | bash -s -- --uninstall\n' "$REPO"
fi
