import XCTest
@testable import TBShared

final class StateTests: XCTestCase {
    func testFailedProbeDoesNotReportTurboEnabled() {
        XCTAssertEqual(parseTurboState(status: 1, output: "permission denied"), .unknown)
        XCTAssertEqual(parseTurboState(status: 1, output: TB.kextBundleID), .unknown)
    }

    func testSuccessfulProbeDistinguishesLoadedExtension() {
        XCTAssertEqual(parseTurboState(status: 0, output: "other.extension"), .enabled)
        XCTAssertEqual(parseTurboState(status: 0, output: "loaded " + TB.kextBundleID), .disabled)
    }

    func testCommandTimeoutTerminatesUnresponsiveProcess() {
        let start = Date()
        let result = runProcess("/bin/sh", ["-c", "trap '' TERM; while :; do :; done"], timeout: 0.1)
        XCTAssertNotEqual(result.status, 0)
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
    }
}
