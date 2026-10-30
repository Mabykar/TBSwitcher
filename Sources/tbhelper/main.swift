import Foundation
import Darwin
import TBShared

final class Helper: NSObject, NSXPCListenerDelegate, TBHelperProtocol {
    private let lock = NSLock()

    // MARK: XPC trust check
    // No paid Developer ID => no Team ID to pin. Instead the caller must be the exact executable
    // installed by install.sh, and that file must be owned by root (so a normal user process
    // cannot replace it). The app is built with the hardened runtime, which blocks DYLD injection.
    private func isTrusted(_ c: NSXPCConnection) -> Bool {
        var buf = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(c.processIdentifier, &buf, UInt32(buf.count)) > 0 else { return false }
        guard String(cString: buf) == TB.appExecutable else { return false }
        let attrs = try? FileManager.default.attributesOfItem(atPath: TB.appExecutable)
        return (attrs?[.ownerAccountID] as? NSNumber)?.intValue == 0
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection c: NSXPCConnection) -> Bool {
        guard isTrusted(c) else { return false }
        c.exportedInterface = NSXPCInterface(with: TBHelperProtocol.self)
        c.exportedObject = self
        c.resume()
        return true
    }

    // MARK: Action
    func setTurboBoost(enabled: Bool, reply: @escaping (Bool, String) -> Void) {
        lock.lock(); defer { lock.unlock() }

        if enabled {
            // Turbo ON -> unload kext
            var r = runProcess("/sbin/kextunload", ["-b", TB.kextBundleID])
            if r.status != 0 { r = runProcess("/usr/bin/kmutil", ["unload", "-b", TB.kextBundleID]) }
            reply(turboBoostState() == .enabled, r.output)
        } else {
            // Turbo OFF -> load kext
            guard FileManager.default.fileExists(atPath: TB.kextPath) else {
                reply(false, "Kext not found at \(TB.kextPath)"); return
            }
            var r = runProcess("/usr/bin/kextutil", [TB.kextPath])
            if r.status != 0 { r = runProcess("/usr/bin/kmutil", ["load", "-p", TB.kextPath]) }
            let ok = turboBoostState() == .disabled
            var out = r.output
            if !ok {
                // The kext is not required to be signed to *try* loading it (it loads on some Macs),
                // but if loading failed, say so: it is the first thing to rule out.
                let v = runProcess("/usr/bin/codesign", ["--verify", "--strict", TB.kextPath])
                if v.status != 0 {
                    out += "\nNote: the installed kext is not code-signed; macOS may refuse it. See README, “About the kext and signing”."
                }
            }
            reply(ok, out)
        }
    }
}

let helper = Helper()
let listener = NSXPCListener(machServiceName: TB.machService)
listener.delegate = helper
listener.resume()
RunLoop.main.run()
