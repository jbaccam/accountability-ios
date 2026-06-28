import XCTest
@testable import Accountability

/// Locks the wire strings our enums decode from. These must match the Postgres
/// enum values exactly — a rename here silently breaks decoding from the backend.
final class EnumWireTests: XCTestCase {
    private struct Wrap<T: Codable>: Codable { let v: T }

    private func decode<T: Codable>(_ type: T.Type, _ raw: String) throws -> T {
        try JSONDecoder().decode(Wrap<T>.self, from: Data("{\"v\":\"\(raw)\"}".utf8)).v
    }

    func testMultiWordValuesDecode() throws {
        XCTAssertEqual(try decode(ChallengeStatus.self, "needs_resolution"), .needsResolution)
        XCTAssertEqual(try decode(ChallengeType.self, "elimination_streak"), .eliminationStreak)
        XCTAssertEqual(try decode(ReviewMethod.self, "auto_approve"), .autoApprove)
        XCTAssertEqual(try decode(PayoutRule.self, "winner_takes_all"), .winnerTakesAll)
        XCTAssertEqual(try decode(TransactionType.self, "payout_received"), .payoutReceived)
        XCTAssertEqual(try decode(ResolutionType.self, "manual_winner"), .manualWinner)
    }

    func testSimpleValuesDecode() throws {
        XCTAssertEqual(try decode(ChallengeFrequency.self, "weekly"), .weekly)
        XCTAssertEqual(try decode(ParticipantStatus.self, "eliminated"), .eliminated)
        XCTAssertEqual(try decode(VoteValue.self, "approve"), .approve)
        XCTAssertEqual(try decode(FriendshipStatus.self, "accepted"), .accepted)
    }

    func testRawValuesStaySnakeCase() {
        XCTAssertEqual(ChallengeStatus.needsResolution.rawValue, "needs_resolution")
        XCTAssertEqual(SubmissionStatus.needsResolution.rawValue, "needs_resolution")
        XCTAssertEqual(TieHandlingRule.creatorResolves.rawValue, "creator_resolves")
        XCTAssertEqual(ChallengeType.fixedDuration.rawValue, "fixed_duration")
        XCTAssertEqual(TransactionType.stakeReserved.rawValue, "stake_reserved")
    }
}
