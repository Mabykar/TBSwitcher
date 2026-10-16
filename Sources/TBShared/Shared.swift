import Foundation

public enum TB {
    public static let machService   = "local.tbswitcher.helper"
    public static let kextBundleID  = "com.rugarciap.DisableTurboBoost"
    public static let supportDir    = "/Library/PrivilegedHelperTools/local.tbswitcher.helper"
    public static let kextPath      = supportDir + "/DisableTurboBoost.64bits.kext"
    public static let appExecutable = "/Applications/TBSwitcher.app/Contents/MacOS/TBSwitcher"
}

/// The ONLY thing the root helper can be asked to do: a boolean. No paths, no commands.
@objc public protocol TBHelperProtocol {
    /// enabled == true  -> Turbo Boost ON  (kext unloaded)
    /// enabled == false -> Turbo Boost OFF (kext loaded)
    func setTurboBoost(enabled: Bool, reply: @escaping (Bool, String) -> Void)
}

@discardableResult
public func runProcess(_ exe: String, _ args: [String], timeout: TimeInterval = 20) -> (status: Int32, output: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: exe)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (-1, "cannot launch \(exe): \(error.localizedDescription)") }
    DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { if p.isRunning { p.terminate() } }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(decoding: data, as: UTF8.self))
}

/// Kext loaded == Turbo Boost disabled. Does not need root.
public func isTurboBoostDisabled() -> Bool {
    let a = runProcess("/usr/sbin/kextstat", ["-l"])
    if a.status == 0 && !a.output.isEmpty { return a.output.contains(TB.kextBundleID) }
    let b = runProcess("/usr/bin/kmutil", ["showloaded", "--list-only"])
    return b.output.contains(TB.kextBundleID)
}
