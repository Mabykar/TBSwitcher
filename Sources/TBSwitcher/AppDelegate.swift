import AppKit
import ServiceManagement
import TBShared

// The app icon comes from the bundle (AppIcon.icns, built by build.sh from Sources/Assets/ico.png).
// macOS uses it automatically for the About panel and for alerts.

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var connection: NSXPCConnection?
    private var disabled = false      // actual state: kext loaded = Turbo Boost OFF
    private var busy = false
    private let defaults = UserDefaults.standard

    /// What the user last chose (true = wants Turbo Boost OFF). Used to restore it after sleep / reboot.
    private var wantedOff: Bool {
        get { defaults.bool(forKey: "wantedOff") }
        set { defaults.set(newValue, forKey: "wantedOff") }
    }
    private var reapplyAfterWake: Bool {
        get { defaults.object(forKey: "reapplyAfterWake") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "reapplyAfterWake") }
    }

    // MARK: lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let b = item.button {
            b.target = self
            b.action = #selector(clicked(_:))
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateIcon()
        refresh { [weak self] in self?.restoreIfNeeded() }
        Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in self?.refresh() }
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
    }

    // Left click = toggle. Right click (or ctrl+click) = menu.
    @objc private func clicked(_ sender: Any?) {
        let e = NSApp.currentEvent
        if e?.type == .rightMouseUp || e?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            toggle()
        }
    }

    // MARK: menu
    private func showMenu() {
        let m = NSMenu()
        let status = NSMenuItem(title: disabled ? "Turbo Boost: OFF" : "Turbo Boost: ON", action: nil, keyEquivalent: "")
        status.isEnabled = false
        m.addItem(status)
        m.addItem(menuItem(disabled ? "Turn Turbo Boost ON" : "Turn Turbo Boost OFF", #selector(toggleFromMenu),
                           symbol: disabled ? "bolt.fill" : "bolt.slash.fill"))
        m.addItem(.separator())

        let restore = menuItem("Restore my choice after sleep / reboot", #selector(toggleReapply), symbol: "arrow.counterclockwise")
        restore.state = reapplyAfterWake ? .on : .off
        m.addItem(restore)

        let login = menuItem("Launch at login", #selector(toggleLogin), symbol: "power")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        m.addItem(login)
        m.addItem(.separator())

        m.addItem(menuItem("About & Credits…", #selector(showAbout), symbol: "heart"))
        m.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = m
        item.button?.performClick(nil)
        item.menu = nil
    }

    private func menuItem(_ title: String, _ sel: Selector, symbol: String? = nil) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        mi.target = self
        if let symbol { mi.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) }
        return mi
    }

    @objc private func toggleFromMenu() { toggle() }
    @objc private func toggleReapply() { reapplyAfterWake.toggle() }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            alert("Could not change “Launch at login”", error.localizedDescription)
        }
    }

    @objc private func showAbout() {
        let credits = """
        Built on the work of two people:

        **Rubén García Pérez (rugarciap)** — author of Turbo Boost Switcher. His app and kernel extension are what make this one possible.
        **Adam Strzelecki (nanoant)** — author of the original DisableTurboBoost.kext.

        Huge thanks to both. 🙏

        If you find this useful, please support the original: [Turbo Boost Switcher](https://www.rugarciap.com/turbo-boost-switcher-for-os-x/)
        """
        let parsed = (try? NSAttributedString(
            markdown: credits,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? NSAttributedString(string: credits)
        let styled = NSMutableAttributedString(attributedString: parsed)
        let all = NSRange(location: 0, length: styled.length)
        styled.addAttribute(.font, value: NSFont.systemFont(ofSize: 12), range: all)
        styled.addAttribute(.foregroundColor, value: NSColor.labelColor, range: all)

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "TBSwitcher",
            .credits: styled,
        ])
    }

    // MARK: state
    private func refresh(then done: (() -> Void)? = nil) {
        DispatchQueue.global().async {
            let d = isTurboBoostDisabled()
            DispatchQueue.main.async {
                self.disabled = d
                self.updateIcon()
                done?()
            }
        }
    }

    private func updateIcon() {
        let name = disabled ? "bolt.slash.fill" : "bolt.fill"
        let text = disabled ? "Turbo Boost: OFF" : "Turbo Boost: ON"
        let img = NSImage(systemSymbolName: name, accessibilityDescription: text)
        img?.isTemplate = true
        item.button?.image = img
        item.button?.toolTip = text + " — click to toggle, right-click for menu"
        item.button?.appearsDisabled = busy      // icon dims while a switch is in progress
    }

    // MARK: restore after sleep / reboot
    @objc private func didWake() {
        // Give the system a moment to settle, then re-apply the user's last choice if the kext got unloaded.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.refresh { self?.restoreIfNeeded() }
        }
    }

    private func restoreIfNeeded() {
        guard reapplyAfterWake, wantedOff, !disabled else { return }
        apply(turboEnabled: false, userInitiated: false)
    }

    // MARK: toggle via the root helper
    private func toggle() {
        apply(turboEnabled: disabled, userInitiated: true)   // currently OFF -> turn ON, and vice versa
    }

    private func apply(turboEnabled: Bool, userInitiated: Bool) {
        guard !busy else { return }
        busy = true
        updateIcon()
        let fail: (String) -> Void = { [weak self] msg in
            DispatchQueue.main.async { self?.finish(false, msg, userInitiated: userInitiated) }
        }
        guard let proxy = helperProxy(onError: fail) else { fail("Could not connect to the helper."); return }
        proxy.setTurboBoost(enabled: turboEnabled) { [weak self] ok, msg in
            DispatchQueue.main.async {
                if ok && userInitiated { self?.wantedOff = !turboEnabled }
                self?.finish(ok, msg, userInitiated: userInitiated)
            }
        }
    }

    private func helperProxy(onError: @escaping (String) -> Void) -> TBHelperProtocol? {
        if connection == nil {
            let c = NSXPCConnection(machServiceName: TB.machService, options: .privileged)
            c.remoteObjectInterface = NSXPCInterface(with: TBHelperProtocol.self)
            let drop: () -> Void = { [weak self] in DispatchQueue.main.async { self?.connection = nil } }
            c.invalidationHandler = drop
            c.interruptionHandler = drop
            c.resume()
            connection = c
        }
        return connection?.remoteObjectProxyWithErrorHandler { err in
            onError("The helper is not reachable. Is it installed? Run: bash install.sh\n\(err.localizedDescription)")
        } as? TBHelperProtocol
    }

    private func finish(_ ok: Bool, _ msg: String, userInitiated: Bool) {
        guard busy else { return }
        busy = false
        updateIcon()
        refresh()
        guard !ok, userInitiated else { return }   // automatic restores fail silently
        alert("Could not switch Turbo Boost",
              msg + "\n\nFirst time? Allow the extension in System Settings → Privacy & Security, restart, then try again.\nStill stuck? Open an issue on GitHub (Mabykar/TBSwitcher) and include this message.")
    }

    private func alert(_ title: String, _ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        a.runModal()
    }
}
