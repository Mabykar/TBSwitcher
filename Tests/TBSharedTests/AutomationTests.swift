import XCTest
@testable import TBShared

final class AutomationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func target(until: Date? = nil, automatic: Bool = false, battery: Bool? = nil,
                        restore: Bool = false, off: Bool = true) -> Bool? {
        AutomationPolicy.targetEnabled(now: now, temporaryUntil: until, automaticPower: automatic,
                                       onBattery: battery, restore: restore, wantedOff: off)
    }

    func testTemporarySessionOverridesBatteryRule() {
        XCTAssertEqual(target(until: now.addingTimeInterval(60), automatic: true, battery: true), true)
        XCTAssertEqual(target(until: now.addingTimeInterval(60), automatic: true, battery: nil), true)
    }

    func testExpiredSessionReturnsToCurrentPowerSource() {
        XCTAssertEqual(target(until: now, automatic: true, battery: true), false)
        XCTAssertEqual(target(until: now.addingTimeInterval(-60), automatic: true, battery: false), true)
    }

    func testExpiredSessionRestoresManualChoiceEvenWithRestoreDisabled() {
        XCTAssertEqual(target(until: now, off: true), false)
        XCTAssertEqual(target(until: now, off: false), true)
    }

    func testUnknownPowerSourceNeverGuesses() {
        XCTAssertNil(target(automatic: true, battery: nil, restore: true))
        XCTAssertNil(target(until: now, automatic: true, battery: nil))
    }

    func testAutomaticPowerRule() {
        XCTAssertEqual(target(automatic: true, battery: true), false)
        XCTAssertEqual(target(automatic: true, battery: false), true)
    }

    func testOrdinaryRestorationRespectsPreferenceAndBothChoices() {
        XCTAssertNil(target(restore: false))
        XCTAssertEqual(target(restore: true, off: true), false)
        XCTAssertEqual(target(restore: true, off: false), true)
    }
}
