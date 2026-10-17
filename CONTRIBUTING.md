# Contributing

Thanks for helping! TBSwitcher is deliberately **small**: one menu bar switch and one tiny root helper.
Features like sensors, charts or auto modes are out of scope — the original [Turbo Boost Switcher PRO](https://www.rugarciap.com/turbo-boost-switcher-for-os-x/) does those well.

## Good contributions

- Bug fixes and compatibility reports (macOS version, Mac model, `bash doctor.sh` output)
- Safer helper / installer behavior
- Docs and translations

## Build

```bash
xcode-select --install   # once
bash build.sh            # -> build/TBSwitcher.app and build/tbhelper
```

## Before you open a PR

- [ ] `swift build -c release` passes
- [ ] `bash -n install.sh uninstall.sh doctor.sh build.sh` has no errors
- [ ] You tested install → toggle → sleep/wake → uninstall on a real Intel Mac (CI can't load a kext), and say which macOS version
- [ ] The helper still accepts nothing except a boolean
- [ ] No binaries added (except the vendored kext, with a note in `NOTICE.md`)
