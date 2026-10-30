# TBSwitcher 1.2.0

Stable release for Intel Macs running macOS 13 or newer.

## Changes

- Install a ready-built app using a PKG installer or a DMG containing the installer, instructions, licenses and uninstaller. No developer tools are needed on the destination Mac.
- Restore the complete original legacy kext, including `Contents/Info.plist~`, so its bundle hash matches Apple's signature exception.
- Validate every bundled kext file before source installation and release packaging, rejecting missing, modified or additional files.
- Include SHA-256 checksums for the PKG and DMG.
- Update installation, extension approval and troubleshooting instructions.

Installation and switching have been confirmed by the maintainer on two Macs, including approval and restart on the second Mac.

## Installation

Download `TBSwitcher-1.2.0-Intel.dmg`, open it and run the included PKG. Open TBSwitcher from Applications afterwards. The standalone PKG installs the same files.

This community build has no Developer ID signature or Apple notarization. If macOS blocks a trusted download, attempt to open it, then use System Settings → Privacy & Security → Open Anyway.

If prompted, separately allow “Legacy Developer: Rugarciap” in Privacy & Security and restart. Apple Silicon is not supported. Availability of the legacy signature exception depends on macOS.

## Release assets

- `TBSwitcher-1.2.0-Intel.dmg`
- `TBSwitcher-1.2.0-Intel.pkg`
- `TBSwitcher-1.2.0-SHA256SUMS.txt`

With all three files in the same directory:

```bash
shasum -a 256 -c TBSwitcher-1.2.0-SHA256SUMS.txt
```

Thanks to rugarciap for Turbo Boost Switcher and nanoant for the original DisableTurboBoost.kext.
