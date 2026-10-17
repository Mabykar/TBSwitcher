# Security

## What runs with root, and what it can do

TBSwitcher installs one small helper (`tbhelper`) as a LaunchDaemon. It runs as root **only on demand** and exposes a single XPC call:

```
setTurboBoost(enabled: Bool)
```

It takes a boolean — no paths, no command strings — and does exactly two things: load or unload the bundled
`DisableTurboBoost` kext via `kextutil` / `kextunload` (with `kmutil` as fallback).

Safeguards:

- **Caller check:** the helper only accepts connections from `/Applications/TBSwitcher.app/Contents/MacOS/TBSwitcher`, and only if that file is owned by root.
- **Hardened runtime:** the app is built with it, which blocks `DYLD_*` injection into the trusted app.
- **Locked-down files:** helper, kext and app are installed root-owned and not writable by others.
- **Kext signature is reported, not enforced:** the installer prefers a code-signed kext and warns when it uses an unsigned one (the bundled one is unsigned and works on the author's Mac). macOS itself decides whether to load it.

## Known limitations (honest list)

- The app is ad-hoc signed (no paid Apple Developer ID), so the helper cannot pin a Team ID; it relies on the path/ownership check above instead.
  Any process running **as you** may still find ways to ask the helper to toggle Turbo Boost. The worst outcome is that Turbo Boost is switched on or off — it cannot run arbitrary commands as root.
- The kext is third-party code running in the kernel, and the bundled copy is **unsigned**, so nothing cryptographically ties it to its author. Verify where you got it (see [NOTICE.md](NOTICE.md)) and prefer a signed build if you have one.
- Turbo Boost state is detected via `kextstat` / `kmutil`, which Apple has deprecated.

## Reporting a vulnerability

Please use GitHub's **"Report a vulnerability"** (Security tab → *Advisories*) rather than a public issue.
If that is not available, open an issue that says only "security contact requested" and no details.
