import AppKit
import Carbon
import IOKit.ps

/// Uses system notifications rather than polling the battery.
final class PowerMonitor {
    private var source: CFRunLoopSource?
    var changed: (() -> Void)?

    static var onBattery: Bool? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return nil }
        switch type as String {
        case kIOPSBatteryPowerValue: return true
        case kIOPSACPowerValue: return false
        default: return nil
        }
    }

    init() {
        source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue().changed?()
        }, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue()
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
    }

    deinit { if let source { CFRunLoopSourceInvalidate(source) } }
}

/// RegisterEventHotKey avoids requiring Accessibility or Input Monitoring permission.
final class ToggleHotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var pressed: (() -> Void)?

    func register() -> Bool {
        unregister()
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<ToggleHotKey>.fromOpaque(context).takeUnretainedValue().pressed?()
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard installed == noErr else { return false }
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(controlKey | optionKey | cmdKey),
                                        EventHotKeyID(signature: 0x54425357, id: 1),
                                        GetApplicationEventTarget(), 0, &reference)
        if result != noErr { unregister(); return false }
        return true
    }

    func unregister() {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
        reference = nil
        handler = nil
    }

    deinit { unregister() }
}

func tr(_ english: String, _ russian: String) -> String {
    (Locale.preferredLanguages.first?.hasPrefix("ru") == true) ? russian : english
}
