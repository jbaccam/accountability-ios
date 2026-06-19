import Foundation
import Supabase

struct CreateChallengeInput {
    var title: String
    var description: String
    var entryFee: Double
    var frequency: ChallengeFrequency
    /// Days per period when frequency is custom (2–90).
    var periodDays: Int?
    var startAt: Date
    var endAt: Date?
    var timezone: String
    /// "HH:MM" in the challenge timezone, or nil = end of the period.
    var submissionDeadlineTime: String?
    var gracePeriodMinutes: Int
    var requiresCaption: Bool
    var requiresLocation: Bool
    var reviewMethod: ReviewMethod
    var payoutRule: PayoutRule
}

/// A brief participant embed for list rows.
struct ParticipantBrief: Codable, Hashable {
    let userId: String
    let status: String
}

/// A challenge list row with its participants embedded.
struct ChallengeListItem: Codable, Identifiable, Hashable {
    let challenge: Challenge
    let participants: [ParticipantBrief]

    var id: String { challenge.id }

    enum CodingKeys: String, CodingKey { case challengeParticipants }

    init(from decoder: Decoder) throws {
        challenge = try Challenge(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        participants = try c.decodeIfPresent([ParticipantBrief].self, forKey: .challengeParticipants) ?? []
    }

    func encode(to encoder: Encoder) throws {
        try challenge.encode(to: encoder)
    }
}

/// Assembled client-side from several queries (mirrors getChallengeDetail).
struct ChallengeDetail {
    let challenge: Challenge
    let participants: [ParticipantWithProfile]
    let periods: [CheckinPeriod]
    let mySubmissions: [Submission]
    let resolutions: [ChallengeResolution]
    let currentPeriod: CheckinPeriod?
    let notStarted: Bool
    let reviewQueueCount: Int
    let now: Date
}

enum ChallengeService {
    private static var client: SupabaseClient { Supa.client }

    static func createChallenge(_ input: CreateChallengeInput) async throws -> Challenge {
        let iso = ISO8601DateFormatter()
        let params: [String: AnyJSON] = [
            "p_title": .string(input.title),
            "p_description": .string(input.description),
            "p_entry_fee": .double(input.entryFee),
            "p_frequency": .string(input.frequency.rawValue),
            "p_start_at": .string(iso.string(from: input.startAt)),
            "p_end_at": input.endAt.map { .string(iso.string(from: $0)) } ?? .null,
            "p_timezone": .string(input.timezone),
            "p_submission_deadline_time": input.submissionDeadlineTime.map { .string($0) } ?? .null,
            "p_grace_period_minutes": .integer(input.gracePeriodMinutes),
            "p_proof_requires_photo": .bool(true), // photo proof always on in the MVP
            "p_proof_requires_caption": .bool(input.requiresCaption),
            "p_proof_requires_location": .bool(input.requiresLocation),
            "p_review_method": .string(input.reviewMethod.rawValue),
            "p_tie_handling_rule": .string("creator_resolves"),
            "p_payout_rule": .string(input.payoutRule.rawValue),
            "p_period_days": input.periodDays.map { .integer($0) } ?? .null,
        ]
        return try await client.rpc("create_challenge", params: params).execute().value
    }

    static func listMyChallenges() async throws -> [ChallengeListItem] {
        try await client
            .from("challenges")
            .select("*, challenge_participants(user_id, status)")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func getChallengePreview(code: String) async throws -> ChallengePreview {
        try await client
            .rpc("get_challenge_preview", params: ["p_invite_code": code])
            .execute().value
    }

    @discardableResult
    static func joinByInviteCode(_ code: String) async throws -> Challenge {
        try await client
            .rpc("join_challenge_by_invite_code", params: ["p_invite_code": code])
            .execute().value
    }

    /// Lazily advances server-side game state (periods, eliminations, winner).
    @discardableResult
    static func evaluate(_ challengeId: String) async throws -> Challenge {
        try await client
            .rpc("evaluate_challenge", params: ["p_challenge_id": challengeId])
            .execute().value
    }

    static func getDetail(challengeId: String, myUserId: String) async throws -> ChallengeDetail {
        let challenge = try await evaluate(challengeId)

        async let participants: [ParticipantWithProfile] = client
            .from("challenge_participants")
            .select("*, profiles(id, display_name, avatar_url)")
            .eq("challenge_id", value: challengeId)
            .order("joined_at", ascending: true)
            .execute().value

        async let periods: [CheckinPeriod] = client
            .from("checkin_periods")
            .select("*")
            .eq("challenge_id", value: challengeId)
            .order("period_index", ascending: true)
            .execute().value

        async let mySubmissions: [Submission] = client
            .from("submissions")
            .select("*")
            .eq("challenge_id", value: challengeId)
            .eq("user_id", value: myUserId)
            .execute().value

        async let resolutions: [ChallengeResolution] = client
            .from("challenge_resolutions")
            .select("*")
            .eq("challenge_id", value: challengeId)
            .order("created_at", ascending: false)
            .execute().value

        async let pendingReviews: [PendingReviewRow] = client
            .from("submissions")
            .select("id, user_id, submission_votes(voter_id)")
            .eq("challenge_id", value: challengeId)
            .eq("status", value: "pending")
            .execute().value

        let (parts, pers, mine, res, pending) =
            try await (participants, periods, mySubmissions, resolutions, pendingReviews)

        let now = Date()
        let currentPeriod = pers.first { $0.periodStart <= now && $0.submissionDeadline >= now }
        let reviewQueueCount = pending.filter { row in
            row.userId != myUserId && !row.submissionVotes.contains { $0.voterId == myUserId }
        }.count

        return ChallengeDetail(
            challenge: challenge,
            participants: parts,
            periods: pers,
            mySubmissions: mine,
            resolutions: res,
            currentPeriod: currentPeriod,
            notStarted: challenge.startAt > now,
            reviewQueueCount: reviewQueueCount,
            now: now
        )
    }

    @discardableResult
    static func resolve(
        challengeId: String,
        resolution: ResolutionType,
        notes: String
    ) async throws -> Challenge {
        let params: [String: AnyJSON] = [
            "p_challenge_id": .string(challengeId),
            "p_resolution": .string(resolution.rawValue),
            "p_notes": .string(notes),
        ]
        return try await client.rpc("resolve_challenge", params: params).execute().value
    }

    @discardableResult
    static func cancel(_ challengeId: String) async throws -> Challenge {
        try await client
            .rpc("cancel_challenge", params: ["p_challenge_id": challengeId])
            .execute().value
    }

    /// Back out of a challenge. The caller forfeits their (simulated) stake.
    @discardableResult
    static func leave(_ challengeId: String) async throws -> Challenge {
        try await client
            .rpc("leave_challenge", params: ["p_challenge_id": challengeId])
            .execute().value
    }

    /// Invite specific users; returns how many invites were sent.
    @discardableResult
    static func invite(challengeId: String, inviteeIds: [String]) async throws -> Int {
        let params: [String: AnyJSON] = [
            "p_challenge_id": .string(challengeId),
            "p_invitee_ids": .array(inviteeIds.map { .string($0) }),
        ]
        return try await client.rpc("invite_to_challenge", params: params).execute().value
    }

    static func listInvites() async throws -> [ChallengeInvite] {
        try await client.rpc("list_challenge_invites").execute().value
    }

    @discardableResult
    static func respondInvite(inviteId: String, accept: Bool) async throws -> Challenge {
        let params: [String: AnyJSON] = [
            "p_invite_id": .string(inviteId),
            "p_accept": .bool(accept),
        ]
        return try await client.rpc("respond_challenge_invite", params: params).execute().value
    }
}

private struct PendingReviewRow: Codable {
    struct Vote: Codable { let voterId: String }
    let id: String
    let userId: String
    let submissionVotes: [Vote]
}
