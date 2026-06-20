import XCTest
@testable import Accountability

final class ModelsTests: XCTestCase {
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let raw = try c.decode(String.self)
            guard let date = PostgresDate.parse(raw) else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "bad date \(raw)")
            }
            return date
        }
        return d
    }

    func testDecodesChallenge() throws {
        let json = """
        {
          "id": "c1", "creator_id": "u1", "title": "Gym daily", "description": "no excuses",
          "entry_fee": 25, "status": "active", "challenge_type": "elimination_streak",
          "frequency": "daily", "period_days": 1, "start_at": "2026-06-18T00:00:00Z",
          "end_at": null, "timezone": "America/Chicago", "submission_deadline_time": null,
          "grace_period_minutes": 30, "proof_requires_photo": true, "proof_requires_caption": false,
          "proof_requires_location": false, "proof_requires_timestamp": true,
          "review_method": "majority", "tie_handling_rule": "creator_resolves",
          "payout_rule": "winner_takes_all", "invite_code": "ABC123",
          "created_at": "2026-06-17T12:30:00.123Z"
        }
        """.data(using: .utf8)!

        let challenge = try decoder().decode(Challenge.self, from: json)
        XCTAssertEqual(challenge.id, "c1")
        XCTAssertEqual(challenge.title, "Gym daily")
        XCTAssertEqual(challenge.entryFee, 25)
        XCTAssertEqual(challenge.status, .active)
        XCTAssertEqual(challenge.challengeType, .eliminationStreak)
        XCTAssertEqual(challenge.periodDays, 1)
        XCTAssertNil(challenge.endAt)
    }

    func testDecodesSubmissionWithDetails() throws {
        let json = """
        {
          "id": "s1", "challenge_id": "c1", "period_id": "p1", "user_id": "u2",
          "photo_path": "c1/u2/1.jpg", "caption": "done", "location_lat": null,
          "location_lng": null, "submitted_at": "2026-06-18T09:00:00Z",
          "status": "pending", "resolved_by": null,
          "profiles": { "id": "u2", "display_name": "Sam" },
          "submission_votes": [
            { "id": "v1", "submission_id": "s1", "voter_id": "u3", "vote": "approve",
              "reason": null, "created_at": "2026-06-18T10:00:00Z",
              "profiles": { "id": "u3", "display_name": "Jo" } }
          ]
        }
        """.data(using: .utf8)!

        let sub = try decoder().decode(SubmissionWithDetails.self, from: json)
        XCTAssertEqual(sub.profiles.displayName, "Sam")
        XCTAssertEqual(sub.submissionVotes.count, 1)
        XCTAssertEqual(sub.submissionVotes.first?.vote, .approve)
    }
}
