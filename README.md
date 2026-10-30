<div align="center">

<img src="Sources/Assets/ico.png" width="72" alt="TBSwitcher">

# TBSwitcher

**A Tiny Menu Bar switch for Intel Turbo Boost.**

Click the bolt → Turbo Boost goes off (cooler, quieter, longer battery).<br>
Click again → it's back. **No admin password on every click.**

[![Platform](https://img.shields.io/badge/Platform-Intel%20Mac-000000?logo=apple&logoColor=white)](#)
[![macOS](https://img.shields.io/badge/macOS-13%2B-1E90FF?logo=apple&logoColor=white)](#)
[![Status](https://img.shields.io/badge/Status-Early%20Release-orange)](#)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

> [WARNING]
> **Status: Early Release.** Verified on one Mac — MacBook Pro 16" (Intel), macOS Tahoe 26, SIP enabled.
> Reports from other setups are very welcome.

## Install

### Prebuilt installer (PKG / DMG)

On an Intel Mac running macOS 13 or newer, open the DMG and run the included
PKG installer. It installs the app, root helper and original kext. Open
`/Applications/TBSwitcher.app` afterwards and click the lightning icon.
Developer tools and an Apple Developer subscription are not needed to install.

These community packages have no Developer ID signature or Apple notarization.
If macOS blocks opening the downloaded installer, attempt to open it first, then
use **System Settings → Privacy & Security → Open Anyway** for that trusted download.
Kext approval (**Allow**, then restart) is a separate step.
See the Read Me inside the DMG for installation, removal and credits.

### Build from source

**Requirements:** an Intel Mac, macOS 13 or newer, and the Command Line Tools.

```bash
xcode-select --install
```

### One line

```bash
curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | bash
```

The script:

1. downloads the source into a temporary folder;
2. tells you exactly what it is about to install and asks you to confirm;
3. builds the app and runs `install.sh` — **admin password asked once**.

Uninstall the same way:

```bash
curl -fsSL https://raw.githubusercontent.com/Mabykar/TBSwitcher/main/get.sh | bash -s -- --uninstall
```

### Manual

```bash
git clone https://github.com/Mabykar/TBSwitcher.git
cd TBSwitcher
bash install.sh
```

macOS may ask you to allow the kernel extension the first time:
**System Settings → Privacy & Security → Allow**, then restart and click ⚡ again.

### About the kext and signing

The bundled legacy kext is unsigned. macOS recognizes the original package through
an Apple signature-exception list, using a hash of the entire bundle. Preserve all
of its files, including `Contents/Info.plist~`: despite its backup-style name, removing
it changes that hash and causes `Authenticating extension failed: Bad code signature`.
Signing the application does not replace this exception or sign the kext.

The original bundle hash is `f5b755b280b4e501bacd72362f0bb26d006d1762`
(Apple's `getAdhocSignatureHash` algorithm). This matches the
`OSKextSigExceptionHashList` entry on the investigated macOS 26.7.2 system;
availability of the exception on other macOS versions is not guaranteed.
User approval and a restart may still be required.

## Check that it really works

```bash
sudo powermetrics --samplers cpu_power -i 2000 -n 2 | grep "CPU Average frequency"
```

Run it with Turbo Boost **off**, then **on**, under some load.

| State | Observed on the author's Mac |
| :--- | :--- |
| **Off** | never above ~97 % of nominal frequency |
| **On** | peaks of ~176 % (about 4.2 GHz) |

## FAQ

<details>
<summary><b>Will Turbo Boost stay off after sleep or reboot?</b></summary>

Other tools built on the same kext report that it can be unloaded on wake. TBSwitcher remembers your last choice and
re-applies it after wake and at launch — menu: *Restore my choice after sleep / reboot*, **on by default**.

</details>

<details>
<summary><b>Why does macOS ask me to allow an extension?</b></summary>

It does that for all third-party kernel extensions.

</details>

<details>
<summary><b>Why isn't the app notarized?</b></summary>

That needs a paid Apple Developer ID. For now you build it yourself from source — which is also why you can read
every line.

</details>

## Credits ❤️

This project exists only because of two people. **Huge thanks to:**

> ### [@rugarciap](https://github.com/rugarciap)
> Author of [Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher) — the app and kernel extension that make all of this possible.
>
> Want sensors, charts, auto modes and a polished, signed app? Buy his [**PRO version**](https://rubgape.gumroad.com/l/YeBQUF) — that is what keeps the whole thing alive.

> ### [@nanoant](https://github.com/nanoant)
> Author of the original [DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext).

TBSwitcher is an independent, minimal project and is not affiliated with either of them. Details: [NOTICE.md](NOTICE.md).

## License

TBSwitcher's own code is [MIT](LICENSE).
Third-party files in `Vendor/` keep their original licenses — see [NOTICE.md](NOTICE.md).


## Build distribution packages

On an Intel Mac with the Command Line Tools installed:

```bash
bash package.sh
```

This rebuilds the app and helper, checks every file in the legacy kext against
`packaging/kext.sha256`, and creates `dist/TBSwitcher-<version>-Intel.pkg`,
`dist/TBSwitcher-<version>-Intel.dmg` and SHA-256 checksums. No paid account is
needed. The DMG contains the installer, instructions, licenses and an uninstaller.
The installer supports the running startup disk only and requires administrator
access. It does not load the kext or restart the Mac automatically.

Keep the kext bundle unchanged: even `Info.plist~` is required for Apple's legacy
signature exception. Do not re-sign it. These artifacts are unsigned community
packages; creating a DMG does not notarize its contents.
