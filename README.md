# ⚡ TBSwitcher

A tiny menu bar switch for Intel Turbo Boost.
Click the bolt → Turbo Boost goes off (cooler, quieter, longer battery). Click again → it's back.
**No admin password on every click.**

🇷🇺 [Читать по-русски](README.ru.md)

> **Status:** early release, built for Intel Macs on macOS Tahoe 26. Reports from other setups are very welcome.
> **Intel Macs only** — Apple Silicon has no Turbo Boost to control.

## Install

You need an Intel Mac, macOS 13 or newer, and the Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/Mabykar/TBSwitcher.git
cd TBSwitcher
bash install.sh
```

The installer builds the app, asks for your admin password **once**, and starts the ⚡ icon.
The first time you turn Turbo Boost off, macOS asks you to allow the kernel extension:
**System Settings → Privacy & Security → Allow**, then restart and click ⚡ again.

If the installer stops with *"No code-signed kext found"*, read [Getting a signed kext](#getting-a-signed-kext).

## Use

| Action | What happens |
|---|---|
| **Left-click** ⚡ | Toggle Turbo Boost |
| **Right-click** ⚡ | Menu: status, restore choice after sleep/reboot, launch at login, credits, quit |
| ⚡ filled | Turbo Boost **ON** (normal) |
| ⚡ struck through | Turbo Boost **OFF** |

Remove everything: `bash uninstall.sh`. Something odd: `bash doctor.sh` prints a report you can paste into an issue.

## Getting a signed kext

macOS only loads kernel extensions that are **code-signed and approved by you** — no need to turn SIP off for that.
The kexts in [`Vendor/`](Vendor/) come from the open-source Turbo Boost Switcher repository. Copies without a `_CodeSignature`
folder are **not signed** and macOS will refuse them (`bash doctor.sh` tells you for sure).

So `install.sh` looks for a signed kext in this order:

1. `bash install.sh --kext /path/to/DisableTurboBoost.64bits.kext`
2. `Vendor/DisableTurboBoost.64bits.kext` — if it is signed
3. `/Applications/Turbo Boost Switcher.app` — the official app's own kext

Easiest fix: download the free official app from <https://github.com/rugarciap/Turbo-Boost-Switcher>
(download link is in its README), drag it to `/Applications` (you don't have to run it), then `bash install.sh` again.
We deliberately don't support the "partially disable SIP and use an unsigned kext" route.

## How it works

```
⚡ menu bar app (you)  ──XPC──▶  tiny helper (root, LaunchDaemon)  ──▶  kextutil / kextunload
                                  accepts only "on" / "off"            DisableTurboBoost.kext
```

The kext flips the Turbo Boost bit in the CPU's MSR register while it is loaded: **kext loaded = Turbo Boost off**.
Loading a kext needs root, so a small helper is installed once (that is the one password prompt) and does it on request.
It accepts exactly one thing — a boolean. See [SECURITY.md](SECURITY.md).

## FAQ

**Will Turbo Boost stay off after sleep or reboot?**
Other tools built on the same kext report that it can be unloaded on wake. TBSwitcher remembers your last choice and
re-applies it after wake and at launch (menu: *Restore my choice after sleep / reboot*, on by default).

**Why does macOS ask me to allow an extension?** It does that for every third-party kernel extension, once.

**Why isn't the app notarized?** That needs a paid Apple Developer ID. For now you build it yourself from source — which is also why you can read every line.

## Credits ❤️

This project exists only because of two people. **Huge thanks to:**

- **Rubén García Pérez ([rugarciap](https://github.com/rugarciap))** — author of [Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher), whose signed kernel extension makes all of this possible.
  If you want sensors, charts, auto modes and a polished, signed app, please buy his [PRO version](https://www.rugarciap.com/turbo-boost-switcher-for-os-x/) — that is what keeps the whole thing alive.
- **Adam Strzelecki ([nanoant](https://github.com/nanoant))** — author of the original [DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext).

TBSwitcher is an independent, minimal project and is not affiliated with either of them. Details: [NOTICE.md](NOTICE.md).

## License

TBSwitcher's own code is [MIT](LICENSE). Third-party files in `Vendor/` keep their original licenses — see [NOTICE.md](NOTICE.md).
