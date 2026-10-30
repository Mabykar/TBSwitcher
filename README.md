<div align="center">

<img src="Sources/Assets/ico.png" width="72" alt="TBSwitcher">

# TBSwitcher

**A small menu bar switch for Intel Turbo Boost.**

Click the lightning icon to turn Turbo Boost off. Click again to turn it back on.<br>
**No administrator password on every click.**

[![Platform](https://img.shields.io/badge/Platform-Intel%20Mac-000000?logo=apple&logoColor=white)](#compatibility)
[![macOS](https://img.shields.io/badge/macOS-13%2B-1E90FF?logo=apple&logoColor=white)](#compatibility)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen)](https://github.com/Mabykar/TBSwitcher/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[**Download the latest release**](https://github.com/Mabykar/TBSwitcher/releases/latest)

</div>

## Install

1. Download `TBSwitcher-<version>-Intel.dmg` from [Releases](https://github.com/Mabykar/TBSwitcher/releases/latest).
2. Open the DMG and run the included `.pkg` installer. Enter your administrator password to install the app and helper.
3. Open **TBSwitcher** from Applications and click the lightning icon in the menu bar.
4. If macOS requests extension approval, open **System Settings → Privacy & Security**, allow **Legacy Developer: Rugarciap**, and restart. Open TBSwitcher and try the switch again.

You can also download and run the standalone `.pkg`. Developer tools and an Apple Developer subscription are not needed to install.

### If macOS blocks the installer

The installer has no Developer ID signature or Apple notarization. After attempting to open a trusted download, go to **System Settings → Privacy & Security → Open Anyway** and confirm.

Opening the installer and allowing the kernel extension are separate approvals. The extension may require a restart. There is no need to disable SIP or Gatekeeper globally.

## Use

| Action | Result |
| :--- | :--- |
| Left-click the lightning icon | Toggle Turbo Boost |
| Right-click or Control-click | Open the menu |
| Launch at login | Start TBSwitcher when you sign in |
| Restore my choice after sleep / reboot | Reapply your last choice after wake and at app launch; enabled by default |

The menu and tooltip show the detected Turbo Boost state. Turning Turbo Boost off can reduce heat, fan noise and power use at the cost of peak CPU performance. Results depend on your workload and Mac.

To restore your choice after signing in automatically, enable **Launch at login** as well.

## Compatibility

- **Intel Mac**, macOS **13 or newer**. Apple Silicon is not supported.
- Installation and switching have been confirmed by the maintainer on two Macs. One tested system is a MacBook Pro 16-inch with Intel CPU, macOS Tahoe 26 and SIP enabled.
- The legacy kernel extension relies on an Apple signature exception. Availability on every macOS version and Mac configuration is not guaranteed.

## Uninstall

Run `uninstall.command` from the DMG and enter your administrator password. It removes the app and helper and attempts to unload the extension. Restart if the extension remains active.

The driver is shared with the original Turbo Boost Switcher: unloading it also affects that application's current Turbo Boost state.

Alternatively, remove an installation using the source installer:

```bash
curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | bash -s -- --uninstall
```

## Troubleshooting

**The extension needs approval or a restart.** Open Privacy & Security, allow the extension, restart, then try again. Reinstalling alone does not complete this approval.

**The helper is unavailable.** Run the PKG installer again, then reopen `/Applications/TBSwitcher.app`.

**The error says `Bad code signature`.** Use the complete kext shipped with this project. Do not remove `Contents/Info.plist~`, edit the bundle, or re-sign it. The source installer and release packager check the bundled files before installation or packaging.

If the problem persists, [open an issue](https://github.com/Mabykar/TBSwitcher/issues) with your Mac model, macOS version and the complete error message.

### Verify the effect

For an optional frequency check, compare Turbo Boost off and on under a similar CPU load:

```bash
sudo powermetrics --samplers cpu_power -i 2000 -n 2 | grep "CPU Average frequency"
```

On the author's Mac, off stayed below approximately 97% of nominal frequency, while on reached approximately 176% (4.2 GHz). These are observations for that machine, not targets for all Macs.

## Build from source

An Intel Mac running macOS 13 or newer and the Command Line Tools are required:

```bash
xcode-select --install
```

### One-line installation

```bash
curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | bash
```

The script downloads the source, explains the installation and asks for confirmation, then builds the app. An administrator password is requested to install the helper.

### Manual installation

```bash
git clone https://github.com/Mabykar/TBSwitcher.git
cd TBSwitcher
bash install.sh
```

To build without installing, run `bash build.sh`. Outputs are in `build/`.

### Build PKG and DMG

```bash
bash package.sh
```

The script rebuilds the app and helper, validates the original kext using `packaging/kext.sha256`, and creates:

- `dist/TBSwitcher-<version>-Intel.pkg`
- `dist/TBSwitcher-<version>-Intel.dmg`
- `dist/TBSwitcher-<version>-SHA256SUMS.txt`

The DMG includes the installer, instructions, licenses and an uninstaller. Packaging is free and needs no Apple Developer account. The installer supports the running startup disk only; it does not load the kext or restart the Mac automatically.

To verify downloaded release files, place the PKG, DMG and checksum file in the same directory and run:

```bash
shasum -a 256 -c TBSwitcher-<version>-SHA256SUMS.txt
```

Replace `<version>` with the downloaded version. Both files should report `OK`.

### Preserve the legacy kext

The bundled kext is unsigned. macOS recognizes the original bundle through an Apple signature-exception list using a hash of the entire package. Even the backup-looking `Contents/Info.plist~` contributes to that hash and must be preserved.

The original bundle hash is `f5b755b280b4e501bacd72362f0bb26d006d1762` using Apple's `getAdhocSignatureHash` algorithm. It matches the `OSKextSigExceptionHashList` entry inspected on macOS 26.7.2. This exception does not replace user approval. Signing the application does not sign the kext.

## Credits ❤️

TBSwitcher builds on the work of:

- **[Rubén García Pérez (@rugarciap)](https://github.com/rugarciap)** — author of [Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher) and its version of the kernel extension. Please support his work through the [original Turbo Boost Switcher project](https://www.rugarciap.com/turbo-boost-switcher-for-os-x/).
- **[Adam Strzelecki (@nanoant)](https://github.com/nanoant)** — author of the original [DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext).

TBSwitcher is an independent project and is not affiliated with either author.

## License

TBSwitcher's own code is [MIT](LICENSE). The original kernel extension's license and attribution are included in [Vendor/LICENSE-nanoant.txt](Vendor/LICENSE-nanoant.txt).
