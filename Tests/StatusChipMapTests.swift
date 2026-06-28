import XCTest
@testable import Accountability

/// Locks the status -> label/color mappings. The participant labels in
/// particular are product-load-bearing ("Still in" leads, per PRODUCT.md).
final class StatusChipMapTests: XCTestCase {
    func testParticipantLabels() {
        XCTAssertEqual(StatusChip(participantStatus: .active).text, "Still in")
        XCTAssertEqual(StatusChip(participantStatus: .eliminated).text, "Out")
        XCTAssertEqual(StatusChip(participantStatus: .winner).text, "Winner")
        XCTAssertEqual(StatusChip(participantStatus: .invited).text, "Invited")
        XCTAssertEqual(StatusChip(participantStatus: .refunded).text, "Refunded")
    }

    func testChallengeLabels() {
        XCTAssertEqual(StatusChip(challengeStatus: .active).text, "Active")
        XCTAssertEqual(StatusChip(challengeStatus: .needsResolution).text, "Needs resolution")
        XCTAssertEqual(StatusChip(challengeStatus: .completed).text, "Completed")
    }

    func testSubmissionKinds() {
        XCTAssertTrue(StatusChip(submissionStatus: .approved).kind == .success)
        XCTAssertTrue(StatusChip(submissionStatus: .rejected).kind == .danger)
        XCTAssertTrue(StatusChip(submissionStatus: .pending).kind == .warning)
    }

    func testEliminatedIsDanger() {
        XCTAssertTrue(StatusChip(participantStatus: .eliminated).kind == .danger)
        XCTAssertTrue(StatusChip(participantStatus: .active).kind == .success)
    }
}
