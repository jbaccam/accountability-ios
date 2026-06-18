import Foundation

// Codable row types mirroring src/lib/types.ts. Decoded with
// `.convertFromSnakeCase` (see SupabaseClientProvider), so properties are
// camelCase and map from the snake_case columns PostgREST returns.

struct Profile: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    /// Simulated/test balance only — no real money.
    let simulatedBalance: Double
    /// Last display-name change; gates the 30-day rename cadence. Null = never.
    let displayNameUpdatedAt: Date?
    let createdAt: Date
}

/// A lightweight profile embed (PostgREST `profiles(...)`). `avatarUrl` is
/// optional so both the `(id, display_name, avatar_url)` and `(id, display_name)`
/// embeds decode into the same type.
struct ProfileRef: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let avatarUrl: String?
}

/// A profile returned by search, tagged with the caller's relationship.
struct UserSearchResult: Codable, Identifiable, Hashable {
    let userId: String
    let displayName: String
    let avatarUrl: String?
    let relationship: Relationship

    var id: String { userId }
}

struct Friend: Codable, Identifiable, Hashable {
    let friendId: String
    let displayName: String
    let avatarUrl: String?
    let since: Date?

    var id: String { friendId }
}

struct FriendRequest: Codable, Identifiable, Hashable {
    let direction: RequestDirection
    let otherId: String
    let displayName: String
    let avatarUrl: String?
    let requestedAt: Date

    var id: String { otherId }
}

/// A pending challenge invite the caller has received.
struct ChallengeInvite: Codable, Identifiable, Hashable {
    let inviteId: String
    let challengeId: String
    let title: String
    let entryFee: Double
    let frequency: ChallengeFrequency
    let startAt: Date
    let endAt: Date?
    let inviterName: String
    let participantCount: Int
    let invitedAt: Date

    var id: String { inviteId }
}

struct Challenge: Codable, Identifiable, Hashable {
    let id: String
    let creatorId: String
    let title: String
    let description: String
    let entryFee: Double
    let status: ChallengeStatus
    let challengeType: ChallengeType
    let frequency: ChallengeFrequency
    /// Days per check-in period: daily = 1, weekly = 7, custom = N.
    let periodDays: Int
    let startAt: Date
    let endAt: Date?
    let timezone: String
    let submissionDeadlineTime: String?
    let gracePeriodMinutes: Int
    let proofRequiresPhoto: Bool
    let proofRequiresCaption: Bool
    let proofRequiresLocation: Bool
    let proofRequiresTimestamp: Bool
    let reviewMethod: ReviewMethod
    let tieHandlingRule: TieHandlingRule
    let payoutRule: PayoutRule
    let inviteCode: String
    let createdAt: Date
}

struct ChallengeParticipant: Codable, Identifiable, Hashable {
    let id: String
    let challengeId: String
    let userId: String
    let status: ParticipantStatus
    let joinedAt: Date
    let eliminatedAt: Date?
    let eliminationReason: String?
    let payoutAmount: Double?
}

struct ParticipantWithProfile: Codable, Identifiable, Hashable {
    let id: String
    let challengeId: String
    let userId: String
    let status: ParticipantStatus
    let joinedAt: Date
    let eliminatedAt: Date?
    let eliminationReason: String?
    let payoutAmount: Double?
    let profiles: ProfileRef
}

struct CheckinPeriod: Codable, Identifiable, Hashable {
    let id: String
    let challengeId: String
    let periodIndex: Int
    let periodStart: Date
    let periodEnd: Date
    let submissionDeadline: Date
    let reviewDeadline: Date
    let status: PeriodStatus
}

struct Submission: Codable, Identifiable, Hashable {
    let id: String
    let challengeId: String
    let periodId: String
    let userId: String
    let photoPath: String?
    let caption: String
    let locationLat: Double?
    let locationLng: Double?
    let submittedAt: Date
    let status: SubmissionStatus
    let resolvedBy: String?
}

struct SubmissionVote: Codable, Identifiable, Hashable {
    let id: String
    let submissionId: String
    let voterId: String
    let vote: VoteValue
    let reason: String?
    let createdAt: Date
}

struct VoteWithProfile: Codable, Identifiable, Hashable {
    let id: String
    let submissionId: String
    let voterId: String
    let vote: VoteValue
    let reason: String?
    let createdAt: Date
    let profiles: ProfileRef
}

struct SubmissionWithDetails: Codable, Identifiable, Hashable {
    let id: String
    let challengeId: String
    let periodId: String
    let userId: String
    let photoPath: String?
    let caption: String
    let locationLat: Double?
    let locationLng: Double?
    let submittedAt: Date
    let status: SubmissionStatus
    let resolvedBy: String?
    let profiles: ProfileRef
    let submissionVotes: [VoteWithProfile]
}

struct SimulatedTransaction: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let challengeId: String?
    let type: TransactionType
    let amount: Double
    let createdAt: Date
}

struct ChallengeResolution: Codable, Identifiable, Hashable {
    let id: String
    let challengeId: String
    let resolvedBy: String
    let resolutionType: ResolutionType
    let notes: String
    let createdAt: Date
}

/// Shape returned by the get_challenge_preview RPC.
struct ChallengePreview: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let entryFee: Double
    let frequency: ChallengeFrequency
    let status: ChallengeStatus
    let startAt: Date
    let endAt: Date?
    let participantCount: Int
    let creatorName: String
    let alreadyJoined: Bool
}
