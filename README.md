# TBSwitcher (minimal)

Menu bar lightning icon: left click = toggle Turbo Boost, right click = Quit.
Root helper (LaunchDaemon) loads/unloads the original DisableTurboBoost kext, so no password per toggle.

1. xcode-select --install   (if you have no Xcode / Command Line Tools)
2. ./build.sh
3. sudo ./install.sh "/path/to/DisableTurboBoost.64bits.kext"   (original, unmodified kext)
4. Click the bolt. First load: allow the extension in System Settings > Privacy & Security, restart, click again.
5. If the helper is blocked: System Settings > General > Login Items & Extensions > allow it.

Remove: sudo ./uninstall.sh
