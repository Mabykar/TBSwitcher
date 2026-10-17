# Notice and credits

## With gratitude

TBSwitcher would not exist without these two people. Thank you both. 🙏

**Rubén García Pérez ([rugarciap](https://github.com/rugarciap))**
Author of [Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher) (GPL-2.0), the app this project is a minimal re-imagining of.
His app and the kernel extension it builds on are what make Turbo Boost control practical on macOS.
If you want the full-featured, signed app (sensors, charts, auto modes), please support him by buying the PRO version:
<https://www.rugarciap.com/turbo-boost-switcher-for-os-x/>

**Adam Strzelecki ([nanoant](https://github.com/nanoant))**
Author of the original [DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext) (MIT, © 2012 Adam Strzelecki), the idea and code that Turbo Boost Switcher
(per its own README) builds on.

## Third-party components

| Path | What | Origin | License |
|---|---|---|---|
| `Vendor/DisableTurboBoost.*.kext` | Kernel extension that sets the Turbo Boost disable bit in the CPU's MSR | Taken from rugarciap's Turbo Boost Switcher repository; derived from nanoant's DisableTurboBoost.kext | The original kext code is MIT (full text in [Vendor/LICENSE-nanoant.txt](Vendor/LICENSE-nanoant.txt)); the Turbo Boost Switcher repository that distributes this build is GPL-2.0 |

Source for the original kext: <https://github.com/nanoant/DisableTurboBoost.kext>. These files are included unmodified and keep their original licenses.

## This project

TBSwitcher's own code (everything outside `Vendor/`) is MIT-licensed, see [LICENSE](LICENSE).
It was written from scratch and does not copy source code from Turbo Boost Switcher.
It is an independent project and is **not affiliated with or endorsed by** rugarciap or nanoant.
This notice is informational and not legal advice; if you redistribute, check the upstream licenses yourself.
