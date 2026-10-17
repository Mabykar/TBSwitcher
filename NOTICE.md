# Notice and credits

## With gratitude

TBSwitcher would not exist without these two people. Thank you both. 🙏

**Rubén García Pérez ([rugarciap](https://github.com/rugarciap))**
Author of [Turbo Boost Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher) (GPL-2.0), the app this project is a minimal re-imagining of.
His signed kernel extension is what lets Turbo Boost be controlled on modern macOS without turning SIP off.
If you want the full-featured, signed app (sensors, charts, auto modes), please support him by buying the PRO version:
<https://www.rugarciap.com/turbo-boost-switcher-for-os-x/>

**Adam Strzelecki ([nanoant](https://github.com/nanoant))**
Author of the original [DisableTurboBoost.kext](https://github.com/nanoant/DisableTurboBoost.kext), the idea and code that Turbo Boost Switcher
(per its own README) builds on.

## Third-party components

| Path | What | Origin | License |
|---|---|---|---|
| `Vendor/DisableTurboBoost.*.kext` | Kernel extension that sets the Turbo Boost disable bit | Distributed with rugarciap's Turbo Boost Switcher; based on nanoant's DisableTurboBoost.kext | GPL-2.0 for the Turbo Boost Switcher repository; check the upstream kext repository for nanoant's terms |

The corresponding source for the kext is available upstream at <https://github.com/nanoant/DisableTurboBoost.kext>
and in the Turbo Boost Switcher repository linked above. These files are included unmodified and keep their original licenses.

## This project

TBSwitcher's own code (everything outside `Vendor/`) is MIT-licensed, see [LICENSE](LICENSE).
It was written from scratch and does not copy source code from Turbo Boost Switcher.
It is an independent project and is **not affiliated with or endorsed by** rugarciap or nanoant.
This notice is informational and not legal advice; if you redistribute, check the upstream licenses yourself.
