import AppKit
import TBShared

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var connection: NSXPCConnection?
    private var disabled = false      // true = kext loaded = Turbo Boost OFF
    private var busy = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let b = item.button {
            b.target = self
            b.action = #selector(clicked(_:))
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateIcon()
        refresh()
        Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in self?.refresh() }
    }

    // Left click = toggle. Right click (or ctrl+click) = tiny menu with Quit.
    @objc private func clicked(_ sender: Any?) {
        let e = NSApp.currentEvent
        if e?.type == .rightMouseUp || e?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            toggle()
        }
    }

    private func showMenu() {
        let m = NSMenu()
        let s = NSMenuItem(title: disabled ? "Turbo Boost: OFF" : "Turbo Boost: ON", action: nil, keyEquivalent: "")
        s.isEnabled = false
        m.addItem(s)
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = m
        item.button?.performClick(nil)
        item.menu = nil
    }

    // MARK: state
    private func refresh() {
        DispatchQueue.global().async {
            let d = isTurboBoostDisabled()
            DispatchQueue.main.async { self.disabled = d; self.updateIcon() }
        }
    }

    private func updateIcon() {
        let name = disabled ? "bolt.slash.fill" : "bolt.fill"
        let text = disabled ? "Turbo Boost: OFF" : "Turbo Boost: ON"
        let img = NSImage(systemSymbolName: name, accessibilityDescription: text)
        img?.isTemplate = true
        item.button?.image = img
        item.button?.toolTip = text + " (click to toggle)"
    }

    // MARK: toggle via root helper
    private func toggle() {
        guard !busy else { return }
        busy = true
        let wantEnabled = disabled            // currently OFF -> turn ON, and vice versa
        guard let proxy = helperProxy() else { finish(false, "Helper connection failed."); return }
        proxy.setTurboBoost(enabled: wantEnabled) { [weak self] ok, msg in
            DispatchQueue.main.async { self?.finish(ok, msg) }
        }
    }

    private func helperProxy() -> TBHelperProtocol? {
        if connection == nil {
            let c = NSXPCConnection(machServiceName: TB.machService, options: .privileged)
            c.remoteObjectInterface = NSXPCInterface(with: TBHelperProtocol.self)
            let drop: () -> Void = { [weak self] in DispatchQueue.main.async { self?.connection = nil } }
            c.invalidationHandler = drop
            c.interruptionHandler = drop
            c.resume()
            connection = c
        }
        return connection?.remoteObjectProxyWithErrorHandler { [weak self] err in
            DispatchQueue.main.async {
                self?.finish(false, "Helper not reachable (is it installed? run install.sh).\n\(err.localizedDescription)")
            }
        } as? TBHelperProtocol
    }

    private func finish(_ ok: Bool, _ msg: String) {
        guard busy else { return }
        busy = false
        refresh()
        guard !ok else { return }
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "Could not switch Turbo Boost"
        a.informativeText = msg + "\n\nFirst time? Allow the extension in System Settings → Privacy & Security, restart, then try again."
        a.runModal()
    }
}
