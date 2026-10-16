# Vendor — third-party kernel extensions

These are **not our code**. They come from the open-source
[Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher) project by rugarciap, which builds on
[DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext) by nanoant. Thank you both — see [../NOTICE.md](../NOTICE.md).

| Folder | Used? | Notes |
|---|---|---|
| `DisableTurboBoost.64bits.kext` | Yes | The one TBSwitcher loads (bundle id `com.rugarciap.DisableTurboBoost`). |
| `DisableTurboBoost.32bits.kext` | No | Legacy 32-bit build. Modern macOS is 64-bit only; safe to delete. |

## Important: signing

macOS 13+ only loads kexts that are code-signed **and** approved by the user. A signed kext has a
`Contents/_CodeSignature/` folder. Check with:

```bash
codesign -dv --verbose=4 Vendor/DisableTurboBoost.64bits.kext
```

If it says *"code object is not signed at all"*, `install.sh` skips it and uses the kext from the official
Turbo Boost Switcher app instead (see the main README, "Getting a signed kext").

Don't modify these files: any change invalidates the signature (and the Team ID macOS approved).
