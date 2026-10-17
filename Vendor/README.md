# Vendor — third-party kernel extensions

These are **not our code**. They come from the open-source
[Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher) project by rugarciap, which builds on
[DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext) by nanoant. Thank you both — see [../NOTICE.md](../NOTICE.md).

| Folder | Used? | Notes |
|---|---|---|
| `DisableTurboBoost.64bits.kext` | Yes | The one TBSwitcher loads (bundle id `com.rugarciap.DisableTurboBoost`). |
| `DisableTurboBoost.32bits.kext` | No | Legacy 32-bit build. Modern macOS is 64-bit only; safe to delete. |

## Signing

A code-signed kext has a `Contents/_CodeSignature/` folder. The copy here has none, so it is **unsigned** — check with:

```bash
codesign -dv --verbose=4 Vendor/DisableTurboBoost.64bits.kext
```

(It prints *"code object is not signed at all"*.) Even so, on the author's Intel MacBook Pro 16" with macOS Tahoe 26 and SIP enabled
it loads after the usual approval and Turbo Boost really switches off. Other Macs may behave differently; if yours refuses it,
see the main README, "About the kext and signing".

Don't modify these files: any change would alter the bytes you are loading into the kernel.
