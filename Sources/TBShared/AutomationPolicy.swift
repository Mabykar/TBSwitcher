import Foundation

/// Temporary sessions override the power rule. Expired sessions restore the saved choice,
/// even when ordinary restoration at launch/wake is disabled.
public enum AutomationPolicy {
    public static func targetEnabled(now: Date, temporaryUntil: Date?, automaticPower: Bool,
                                     onBattery: Bool?, restore: Bool, wantedOff: Bool) -> Bool? {
        if let until = temporaryUntil, until > now { return true }
        if automaticPower { return onBattery.map { !$0 } }
        if temporaryUntil != nil || restore { return !wantedOff }
        return nil
    }
}
