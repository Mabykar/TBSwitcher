# Changelog

## 1.2.0
- One-line install/uninstall: `curl -fsSL …/get.sh | bash` (shows what it will do, asks for confirmation, optional `TBSWITCHER_REF` version pin).
- README banner (`docs/banner.svg`, an illustration of the menu bar states).
- App look: icon drawn in code (About panel and alerts), icons in menu items, the bolt dims while Turbo Boost is being switched.
- NOTICE: nanoant's kext is MIT; license text added as `Vendor/LICENSE-nanoant.txt`.

## 1.1.1
- Unsigned kext is now a warning, not a blocker: `install.sh` prefers a code-signed kext but uses the bundled unsigned one (it loads on the author's Mac with SIP enabled).
- Helper no longer refuses unsigned kexts; success = `kextutil`/`kmutil` exit status or detected state, with a signing hint only when loading fails.
- `doctor.sh` reports both `kextstat` and `kmutil`, and points to the `powermetrics` check.
- README, NOTICE, SECURITY, Vendor/README: removed unverified claims about the kext being signed; added how to verify with `powermetrics`.

## 1.1.0
- One-command installer: `bash install.sh` builds, asks for the admin password once, installs and launches.
- New `doctor.sh` diagnostic report; self-elevating `uninstall.sh`.
- App: restores your last choice after sleep/wake and at launch, "Launch at login", About & Credits window, clearer error messages.
- App built with hardened runtime.
- README (EN/RU), NOTICE with credits to rugarciap and nanoant, SECURITY, CONTRIBUTING, MIT license, CI.

## 1.0.0
- First version: lightning icon in the menu bar, root helper over XPC, no password per toggle.
