# Changelog

## 1.1.0
- One-command installer: `bash install.sh` builds, asks for the admin password once, installs and launches.
- Installer picks a **code-signed** kext automatically (`--kext` → `Vendor/` → official app) and explains clearly when none is found.
- New `doctor.sh` diagnostic report; self-elevating `uninstall.sh`.
- App: restores your last choice after sleep/wake and at launch, "Launch at login", About & Credits window, clearer error messages.
- Helper verifies the kext signature before loading and reports a readable error.
- App built with hardened runtime.
- README (EN/RU), NOTICE with credits to rugarciap and nanoant, SECURITY, CONTRIBUTING, MIT license, CI.

## 1.0.0
- First version: lightning icon in the menu bar, root helper over XPC, no password per toggle.
