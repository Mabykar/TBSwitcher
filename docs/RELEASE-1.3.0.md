# TBSwitcher 1.3.0

- Install exclusively through PKG/DMG. Removed the source-building `get.sh` and `install.sh`; development builds still use `build.sh`, and `package.sh` produces installers.
- Optional automatic mode: Turbo Boost off on battery and on with external power.
- Temporary enable for 15, 30 or 60 minutes. Deadlines survive app restarts, and expired sessions restore on wake or next launch. The app must run to enforce deadlines.
- Optional global Control–Option–Command–T shortcut, with registration conflict reporting.
- Russian and English interface, following the system language.
- Unknown state when detection fails, verified switching, operation timeouts, and protection against stale status results.
- Copy diagnostics and inspect the last error, including automatic restoration failures.
- Less frequent background status checks, and accurate uninstall messages when extension unload fails.

Temporary sessions override the automatic power rule. Manual toggles exit both modes only after success.

## Manual verification before publishing

- Install the PKG on an Intel Mac; test both switching directions and helper recovery.
- Check Russian and English menu, tooltip, error alerts and About panel.
- Enable the power rule, unplug/reconnect power, then repeat during a temporary session.
- Test temporary expiry, cancellation, extension, sleep/wake and quit/relaunch before and after expiry.
- Test the global shortcut from another app, turning it off, and a registration conflict.
- Verify failed switching preserves the previous mode and exposes diagnostics.
- Run the DMG uninstaller, including the case where extension unload fails.
