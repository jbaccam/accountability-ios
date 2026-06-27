import XCTest
@testable import Accountability

/// Locks the user-facing money/trust copy so the "simulated / not gambling"
/// language can't silently drift.
final class CopyTests: XCTestCase {
    func testLabels() {
        XCTAssertEqual(Copy.simulatedPotLabel, "Simulated pot")
        XCTAssertEqual(Copy.simulatedBalanceLabel, "Simulated balance")
    }

    func testDisclaimersAreNonEmpty() {
        XCTAssertFalse(Copy.trustDisclaimer.isEmpty)
        XCTAssertFalse(Copy.simulatedBalanceNote.isEmpty)
    }

    func testTrustDisclaimerMentionsTrust() {
        XCTAssertTrue(Copy.trustDisclaimer.lowercased().contains("trust"))
    }

    func testBalanceNoteKeepsSimulatedFraming() {
        let note = Copy.simulatedBalanceNote.lowercased()
        XCTAssertTrue(note.contains("simulated"))
        XCTAssertTrue(note.contains("no real money"))
    }
}
