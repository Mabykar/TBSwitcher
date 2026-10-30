#!/bin/bash
# Build a free, unsigned PKG installer and DMG. No Apple Developer account needed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
[[ "$(uname -m)" == x86_64 ]] || { echo 'Build this release on an Intel Mac.' >&2; exit 1; }
bash packaging/verify-kext.sh "$HERE/Vendor/DisableTurboBoost.64bits.kext"
bash build.sh
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid release version.' >&2; exit 1; }
mkdir -p dist
WORK=$(mktemp -d /private/tmp/tbswitcher-package.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
ROOT="$WORK/root"
SUP="$ROOT/Library/PrivilegedHelperTools/local.tbswitcher.helper"
mkdir -p "$ROOT/Applications" "$ROOT/Library/LaunchDaemons" "$SUP" "$WORK/image"
ditto build/TBSwitcher.app "$ROOT/Applications/TBSwitcher.app"
install -m 755 build/TBHelper "$SUP/TBHelper"
ditto Vendor/DisableTurboBoost.64bits.kext "$SUP/DisableTurboBoost.64bits.kext"
install -m 644 packaging/local.tbswitcher.helper.plist "$ROOT/Library/LaunchDaemons/local.tbswitcher.helper.plist"
chmod -R u+rwX,go+rX,go-w "$ROOT"
bash packaging/verify-kext.sh "$SUP/DisableTurboBoost.64bits.kext"
codesign --verify --strict "$ROOT/Applications/TBSwitcher.app"
# Replace both bundles in their fixed locations, removing obsolete bundle files.
pkgbuild --root "$ROOT" --component-plist packaging/components.plist \
  --scripts packaging/scripts --ownership recommended --install-location / \
  --identifier local.tbswitcher.installer --version "$VERSION" "$WORK/payload.pkg"
cat > "$WORK/Distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>TBSwitcher $VERSION</title>
  <options customize="never" require-scripts="false" hostArchitectures="x86_64"/>
  <domains enable_localSystem="true" enable_currentUserHome="false" enable_anywhere="false"/>
  <volume-check><allowed-os-versions><os-version min="13.0"/></allowed-os-versions></volume-check>
  <welcome file="Read Me.txt" mime-type="text/plain"/>
  <conclusion file="Read Me.txt" mime-type="text/plain"/>
  <choices-outline><line choice="default"/></choices-outline>
  <choice id="default" visible="false"><pkg-ref id="local.tbswitcher.installer"/></choice>
  <pkg-ref id="local.tbswitcher.installer" version="$VERSION">payload.pkg</pkg-ref>
</installer-gui-script>
XML
PKG="TBSwitcher-$VERSION-Intel.pkg"
DMG="TBSwitcher-$VERSION-Intel.dmg"
productbuild --distribution "$WORK/Distribution.xml" --resources packaging \
  --package-path "$WORK" "$HERE/dist/$PKG"
cp "dist/$PKG" "$WORK/image/$PKG"
cp packaging/'Read Me.txt' "$WORK/image/Read Me.txt"
cp LICENSE "$WORK/image/LICENSE.txt"
cp Vendor/LICENSE-nanoant.txt "$WORK/image/LICENSE-nanoant.txt"
cp uninstall.sh "$WORK/image/uninstall.command"
chmod 755 "$WORK/image/uninstall.command"
hdiutil create -ov -format UDZO -volname "TBSwitcher $VERSION" \
  -srcfolder "$WORK/image" "$HERE/dist/$DMG"
hdiutil verify "$HERE/dist/$DMG"
(cd dist && shasum -a 256 "$PKG" "$DMG" > "TBSwitcher-$VERSION-SHA256SUMS.txt")
printf '\nBuilt: dist/%s and dist/%s\nUnsigned community release; see the included Read Me.\n' "$PKG" "$DMG"
