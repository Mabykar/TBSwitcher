import Foundation
import Darwin

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
    DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { if p.isRunning {
        p.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            if p.isRunning { kill(p.processIdentifier, SIGKILL) }
        }
    } }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(decoding: data, as: UTF8.self))
}

/// Kext state is a proxy for Turbo Boost state; command failures remain unknown.
public enum TurboState: Equatable {
    case enabled, disabled, unknown

    public var label: String {
        switch self {
        case .enabled: return "ON"
        case .disabled: return "OFF"
        case .unknown: return "Unknown"
        }
    }
}

public func parseTurboState(status: Int32, output: String) -> TurboState {
    guard status == 0 else { return .unknown }
    return output.contains(TB.kextBundleID) ? .disabled : .enabled
}

public func turboBoostState() -> TurboState {
    let a = runProcess("/usr/sbin/kextstat", ["-l"])
    if a.status == 0 { return parseTurboState(status: a.status, output: a.output) }
    let b = runProcess("/usr/bin/kmutil", ["showloaded", "--list-only"])
    return parseTurboState(status: b.status, output: b.output)
}
