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
- **Kext check:** the helper verifies the kext's code signature (`codesign --verify --strict`) before loading it.
- **Locked-down files:** helper, kext and app are installed root-owned and not writable by others.

## Known limitations (honest list)

- The app is ad-hoc signed (no paid Apple Developer ID), so the helper cannot pin a Team ID; it relies on the path/ownership check above instead.
  Any process running **as you** may still find ways to ask the helper to toggle Turbo Boost. The worst outcome is that Turbo Boost is switched on or off — it cannot run arbitrary commands as root.
- Turbo Boost state is detected via `kextstat` / `kmutil`, which Apple has deprecated.
- The kext itself is third-party code running in the kernel. It is small, but it is not ours — see [NOTICE.md](NOTICE.md).

## Reporting a vulnerability

Please use GitHub's **"Report a vulnerability"** (Security tab → *Advisories*) rather than a public issue.
If that is not available, open an issue that says only "security contact requested" and no details.
