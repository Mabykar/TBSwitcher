import AppKit
import ServiceManagement
import TBShared

// The app icon comes from the bundle (AppIcon.icns, built by build.sh from Sources/Assets/ico.png).
// macOS uses it automatically for the About panel and for alerts.

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var connection: NSXPCConnection?
    private var connectionErrorHandler: ((String) -> Void)?
    private var state: TurboState = .unknown
    private var disabled: Bool { state == .disabled }
    private let stateQueue = DispatchQueue(label: "local.tbswitcher.state")
    private var stateGeneration = 0
    private var operationID: UUID?
    private var lastError = "None"
    private var helperStatus = tr("Not contacted", "Подключение ещё не выполнялось")
    private var busy = false
    private let defaults = UserDefaults.standard
    private let powerMonitor = PowerMonitor()
    private let hotKey = ToggleHotKey()
    private var observedBattery: Bool?
    private var temporaryTimer: Timer?
    private var pendingAutomation = false
    private var automaticPower: Bool {
        get { defaults.bool(forKey: "automaticPower") }
        set { defaults.set(newValue, forKey: "automaticPower") }
    }
    private var temporaryUntil: Date? {
        get { defaults.object(forKey: "temporaryUntil") as? Date }
        set {
            if let newValue { defaults.set(newValue, forKey: "temporaryUntil") }
            else { defaults.removeObject(forKey: "temporaryUntil") }
            scheduleTemporaryTimer()
        }
    }

    /// What the user last chose (true = wants Turbo Boost OFF). Used to restore it after sleep / reboot.
    private var wantedOff: Bool {
        get { defaults.bool(forKey: "wantedOff") }
        set { defaults.set(newValue, forKey: "wantedOff") }
    }
    private var reapplyAfterWake: Bool {
        get { defaults.object(forKey: "reapplyAfterWake") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "reapplyAfterWake") }
    }

    private var stateText: String {
        switch state {
        case .enabled: return tr("ON", "ВКЛ")
        case .disabled: return tr("OFF", "ВЫКЛ")
        case .unknown: return tr("Unknown", "Неизвестно")
        }
    }

    // MARK: lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let b = item.button {
            b.target = self
            b.action = #selector(clicked(_:))
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateIcon()
        observedBattery = PowerMonitor.onBattery
        powerMonitor.changed = { [weak self] in
            guard let self else { return }
            let battery = PowerMonitor.onBattery
            guard battery != self.observedBattery else { return }
            self.observedBattery = battery
            if self.automaticPower { self.requestAutomation() }
        }
        hotKey.pressed = { [weak self] in self?.toggle() }
        if defaults.bool(forKey: "hotKeyEnabled"), !hotKey.register() {
            defaults.set(false, forKey: "hotKeyEnabled")
            lastError = tr("Could not register ⌃⌥⌘T. It may be in use by another app.", "Не удалось зарегистрировать ⌃⌥⌘T. Возможно, сочетание занято другим приложением.")
        }
        scheduleTemporaryTimer()
        requestAutomation()
        Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in self?.refresh() }
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
        refresh()
        let m = NSMenu()
        m.autoenablesItems = false
        let status = NSMenuItem(title: "Turbo Boost: " + stateText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        m.addItem(status)
        let toggleItem = menuItem(disabled ? tr("Turn Turbo Boost ON", "Включить Turbo Boost") : tr("Turn Turbo Boost OFF", "Выключить Turbo Boost"), #selector(toggleFromMenu),
                           symbol: disabled ? "bolt.fill" : "bolt.slash.fill")
        toggleItem.isEnabled = !busy && state != .unknown
        m.addItem(toggleItem)
        m.addItem(.separator())
        let automatic = menuItem(tr("Automatic: battery OFF / power ON", "Автоматически: батарея — ВЫКЛ / сеть — ВКЛ"), #selector(toggleAutomatic), symbol: "battery.100percent")
        automatic.state = automaticPower ? .on : .off
        automatic.isEnabled = !busy
        m.addItem(automatic)

        let temporary = NSMenuItem(title: tr("Enable temporarily", "Включить временно"), action: nil, keyEquivalent: "")
        let durations = NSMenu()
        durations.autoenablesItems = false
        for minutes in [15, 30, 60] {
            let entry = menuItem(tr("For \(minutes) minutes", "На \(minutes) мин."), #selector(startTemporary(_:)))
            entry.tag = minutes
            entry.isEnabled = !busy && state != .unknown
            durations.addItem(entry)
        }
        temporary.submenu = durations
        m.addItem(temporary)
        if let until = temporaryUntil {
            let text = until > Date() ? tr("Enabled until ", "Включено до ") + until.formatted(date: .omitted, time: .shortened) : tr("Temporary session expired", "Время временного режима истекло")
            let info = NSMenuItem(title: text, action: nil, keyEquivalent: "")
            info.isEnabled = false
            m.addItem(info)
            let cancel = menuItem(tr("End temporary session", "Завершить временный режим"), #selector(cancelTemporary))
            cancel.isEnabled = !busy
            m.addItem(cancel)
        }
        let shortcut = menuItem(tr("Global shortcut: ⌃⌥⌘T", "Горячая клавиша: ⌃⌥⌘T"), #selector(toggleHotKey), symbol: "keyboard")
        shortcut.state = defaults.bool(forKey: "hotKeyEnabled") ? .on : .off
        m.addItem(shortcut)
        m.addItem(.separator())

        let restore = menuItem(tr("Restore my choice after sleep / reboot", "Восстанавливать режим после сна / перезапуска"), #selector(toggleReapply), symbol: "arrow.counterclockwise")
        restore.state = reapplyAfterWake ? .on : .off
        m.addItem(restore)

        let login = menuItem(tr("Launch at login", "Запускать при входе"), #selector(toggleLogin), symbol: "power")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        m.addItem(login)
        m.addItem(.separator())

        m.addItem(menuItem(tr("Copy diagnostics", "Скопировать диагностику"), #selector(copyDiagnostics), symbol: "doc.on.doc"))
        if lastError != "None" {
            m.addItem(menuItem(tr("Show last error…", "Показать последнюю ошибку…"), #selector(showLastError), symbol: "exclamationmark.triangle"))
        }
        m.addItem(menuItem(tr("About & Credits…", "О программе и авторах…"), #selector(showAbout), symbol: "heart"))
        m.addItem(NSMenuItem(title: tr("Quit", "Выйти"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

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

    @objc private func toggleAutomatic() {
        guard !busy else { return }
        automaticPower.toggle()
        // Turning the rule off leaves the current state and any temporary session intact.
        if automaticPower { requestAutomation() }
    }

    @objc private func startTemporary(_ sender: NSMenuItem) {
        guard !busy, state != .unknown else { return }
        let duration = TimeInterval(sender.tag * 60)
        let wasDisabled = disabled
        // Save only after the helper confirms success. Keep the previous persistent choice.
        apply(turboEnabled: true, userInitiated: true) { [weak self] in
            guard let self else { return }
            if self.temporaryUntil == nil, !self.automaticPower { self.wantedOff = wasDisabled }
            self.temporaryUntil = Date().addingTimeInterval(duration)
        }
    }

    @objc private func cancelTemporary() {
        guard !busy else { return }
        // Keep an expired marker until the previous mode has actually been restored.
        temporaryUntil = Date.distantPast
        requestAutomation()
    }

    private func clearExpiredTemporary() {
        if let until = temporaryUntil, until <= Date() { temporaryUntil = nil }
    }

    private func scheduleTemporaryTimer() {
        temporaryTimer?.invalidate()
        temporaryTimer = nil
        guard let until = temporaryUntil, until > Date() else { return }
        let timer = Timer(fire: until, interval: 0, repeats: false) { [weak self] _ in
            self?.requestAutomation()
        }
        RunLoop.main.add(timer, forMode: .common)
        temporaryTimer = timer
    }

    @objc private func toggleHotKey() {
        if defaults.bool(forKey: "hotKeyEnabled") {
            hotKey.unregister()
            defaults.set(false, forKey: "hotKeyEnabled")
        } else if hotKey.register() {
            defaults.set(true, forKey: "hotKeyEnabled")
        } else {
            lastError = tr("Could not register ⌃⌥⌘T. It may be in use by another app.", "Не удалось зарегистрировать ⌃⌥⌘T. Возможно, сочетание занято другим приложением.")
            alert(tr("Shortcut unavailable", "Горячая клавиша недоступна"), lastError)
        }
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            alert(tr("Could not change “Launch at login”", "Не удалось изменить запуск при входе"), error.localizedDescription)
        }
    }

    @objc private func showAbout() {
        let credits = tr("""
        Built on the work of two people:

        **Rubén García Pérez (rugarciap)** — author of Turbo Boost Switcher. His app and kernel extension are what make this one possible.
        **Adam Strzelecki (nanoant)** — author of the original DisableTurboBoost.kext.

        Huge thanks to both. 🙏

        If you find this useful, please support the original: [Turbo Boost Switcher](https://www.rugarciap.com/turbo-boost-switcher-for-os-x/)
        """, """
        Создано благодаря работе двух авторов:

        **Rubén García Pérez (rugarciap)** — автор Turbo Boost Switcher и используемой здесь версии расширения ядра.
        **Adam Strzelecki (nanoant)** — автор оригинального DisableTurboBoost.kext.

        Спасибо обоим! 🙏

        Поддержите оригинальный проект: [Turbo Boost Switcher](https://www.rugarciap.com/turbo-boost-switcher-for-os-x/)
        """)
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
        let generation = stateGeneration
        stateQueue.async {
            let d = turboBoostState()
            DispatchQueue.main.async {
                guard generation == self.stateGeneration else {
                    // Do not lose a wake/power/deadline event that overlapped a switch.
                    if done != nil { self.requestAutomation() }
                    return
                }
                self.state = d
                self.updateIcon()
                done?()
            }
        }
    }

    private func updateIcon() {
        let name = state == .unknown ? "questionmark.circle" : (disabled ? "bolt.slash.fill" : "bolt.fill")
        let text = "Turbo Boost: " + stateText
        let img = NSImage(systemSymbolName: name, accessibilityDescription: text)
        img?.isTemplate = true
        item.button?.image = img
        item.button?.toolTip = text + tr(" — click to toggle, right-click for menu", " — нажмите для переключения, правая кнопка — меню")
        item.button?.appearsDisabled = busy      // icon dims while a switch is in progress
    }

    // MARK: restore after sleep / reboot
    @objc private func didWake() {
        // Give the system a moment to settle, then re-apply the user's last choice if the kext got unloaded.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.requestAutomation()
        }
    }

    private func requestAutomation() {
        guard !busy else { pendingAutomation = true; return }
        refresh { [weak self] in self?.restoreIfNeeded() }
    }

    private func restoreIfNeeded() {
        guard !busy else { pendingAutomation = true; return }
        guard let target = AutomationPolicy.targetEnabled(now: Date(), temporaryUntil: temporaryUntil,
            automaticPower: automaticPower, onBattery: PowerMonitor.onBattery,
            restore: reapplyAfterWake && defaults.object(forKey: "wantedOff") != nil, wantedOff: wantedOff), state != .unknown else { return }
        if state == (target ? .enabled : .disabled) { clearExpiredTemporary(); return }
        apply(turboEnabled: target, userInitiated: false) { [weak self] in self?.clearExpiredTemporary() }
    }

    // MARK: toggle via the root helper
    private func toggle() {
        guard !busy else { return }
        guard state != .unknown else {
            refresh()
            alert(tr("Turbo Boost state is unknown", "Состояние Turbo Boost неизвестно"), tr("Could not read the extension state. Try again or copy diagnostics from the menu.", "Не удалось определить состояние расширения. Повторите попытку или скопируйте диагностику из меню."))
            return
        }
        let target = disabled
        apply(turboEnabled: target, userInitiated: true) { [weak self] in
            // A manual choice exits automatic and temporary modes.
            self?.wantedOff = !target
            self?.automaticPower = false
            self?.temporaryUntil = nil
        }
    }

    private func apply(turboEnabled: Bool, userInitiated: Bool, onSuccess: (() -> Void)? = nil) {
        guard !busy else { return }
        busy = true
        stateGeneration += 1
        let id = UUID()
        operationID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 100) { [weak self] in
            guard let self, self.operationID == id else { return }
            self.connection?.invalidate()
            self.connection = nil
            self.finish(false, tr("The helper did not reply in time. Copy diagnostics and try again.", "Служба не ответила вовремя. Скопируйте диагностику и повторите попытку."), userInitiated: userInitiated)
        }
        updateIcon()
        let fail: (String) -> Void = { [weak self] msg in
            DispatchQueue.main.async {
                guard let self, self.operationID == id else { return }
                self.finish(false, msg, userInitiated: userInitiated)
            }
        }
        guard let proxy = helperProxy(onError: fail) else { fail(tr("Could not connect to the helper.", "Не удалось подключиться к службе.")); return }
        proxy.setTurboBoost(enabled: turboEnabled) { [weak self] ok, msg in
            DispatchQueue.main.async {
                guard self?.operationID == id else { return }
                if ok { onSuccess?() }
                self?.finish(ok, msg, userInitiated: userInitiated)
            }
        }
    }

    private func helperProxy(onError: @escaping (String) -> Void) -> TBHelperProtocol? {
        connectionErrorHandler = onError
        if connection == nil {
            let c = NSXPCConnection(machServiceName: TB.machService, options: .privileged)
            c.remoteObjectInterface = NSXPCInterface(with: TBHelperProtocol.self)
            let drop: () -> Void = { [weak self, weak c] in
                DispatchQueue.main.async {
                    guard let self, self.connection === c else { return }
                    self.connection = nil
                    self.connectionErrorHandler?(tr("The helper connection was interrupted.", "Соединение со службой прервано."))
                }
            }
            c.invalidationHandler = drop
            c.interruptionHandler = drop
            c.resume()
            connection = c
        }
        return connection?.remoteObjectProxyWithErrorHandler { err in
            onError(tr("The helper is unavailable. Reinstall using the PKG installer.", "Служба недоступна. Повторите установку через PKG.") + "\n" + err.localizedDescription)
        } as? TBHelperProtocol
    }

    private func finish(_ ok: Bool, _ msg: String, userInitiated: Bool) {
        guard busy else { return }
        busy = false
        operationID = nil
        stateGeneration += 1
        helperStatus = ok ? tr("Last request succeeded", "Последний запрос выполнен") : tr("Last request failed", "Последний запрос завершился ошибкой")
        if !ok { lastError = msg.isEmpty ? tr("Requested state could not be verified.", "Не удалось подтвердить выбранное состояние.") : msg }
        state = .unknown
        updateIcon()
        let reconcile = pendingAutomation
        pendingAutomation = false
        if reconcile { requestAutomation() } else { refresh() }
        guard !ok, userInitiated else { return }   // automatic errors remain available in diagnostics without a modal alert
        alert(tr("Could not switch Turbo Boost", "Не удалось переключить Turbo Boost"),
              lastError + "\n\n" + tr("Allow the extension in System Settings → Privacy & Security, restart, then try again. If the problem persists, open an issue on GitHub (Mabykar/TBSwitcher) and include diagnostics.", "Разрешите расширение в Системных настройках → Конфиденциальность и безопасность, перезагрузите Mac и повторите попытку. Если ошибка повторится, создайте issue на GitHub (Mabykar/TBSwitcher) и приложите диагностику."))
    }

    @objc private func showLastError() {
        alert(tr("Last operation error", "Последняя ошибка"), lastError)
    }

    @objc private func copyDiagnostics() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let report = """
        TBSwitcher: \(version)
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Turbo Boost (extension state): \(state.label)
        Helper: \(helperStatus)
        Kext installed: \(FileManager.default.fileExists(atPath: TB.kextPath))
        Restore after wake: \(reapplyAfterWake)
        Last choice OFF: \(wantedOff)
        Automatic power mode: \(automaticPower)
        On battery: \(String(describing: PowerMonitor.onBattery))
        Temporary until: \(String(describing: temporaryUntil))
        Global shortcut: \(defaults.bool(forKey: "hotKeyEnabled"))
        Last error: \(lastError)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
    }

    private func alert(_ title: String, _ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        a.runModal()
    }
}
