import Foundation

// String enums mirroring src/lib/types.ts. Backed by the same wire strings the
// Postgres enums use, so they decode straight from PostgREST/RPC JSON.

enum ChallengeStatus: String, Codable, CaseIterable, Hashable {
    case draft, active, completed, cancelled
    case needsResolution = "needs_resolution"
}

enum ChallengeType: String, Codable, CaseIterable, Hashable {
    case eliminationStreak = "elimination_streak"
    case fixedDuration = "fixed_duration"
}

enum ChallengeFrequency: String, Codable, CaseIterable, Hashable {
    case daily, weekly, custom
}

enum ReviewMethod: String, Codable, CaseIterable, Hashable {
    case majority
    case creatorDecides = "creator_decides"
    case unanimous
    case autoApprove = "auto_approve"
    case groupVote = "group_vote"
}

enum TieHandlingRule: String, Codable, CaseIterable, Hashable {
    case creatorResolves = "creator_resolves"
    case autoRefund = "auto_refund"
    case tiebreakerRound = "tiebreaker_round"
}

enum PayoutRule: String, Codable, CaseIterable, Hashable {
    case winnerTakesAll = "winner_takes_all"
    case splitAmongWinners = "split_among_winners"
}

enum ParticipantStatus: String, Codable, CaseIterable, Hashable {
    case invited, active, eliminated, winner, refunded
}

enum PeriodStatus: String, Codable, CaseIterable, Hashable {
    case open, review, closed
}

enum SubmissionStatus: String, Codable, CaseIterable, Hashable {
    case pending, approved, rejected, disputed
    case needsResolution = "needs_resolution"
}

enum VoteValue: String, Codable, CaseIterable, Hashable {
    case approve, reject
}

enum TransactionType: String, Codable, CaseIterable, Hashable {
    case stakeReserved = "stake_reserved"
    case stakeLost = "stake_lost"
    case payoutReceived = "payout_received"
    case refund
    case deposit
}

enum ResolutionType: String, Codable, CaseIterable, Hashable {
    case refund, tiebreaker
    case manualWinner = "manual_winner"
}

enum FriendshipStatus: String, Codable, CaseIterable, Hashable {
    case pending, accepted
}

/// Caller's relationship to a searched user (search_users RPC).
enum Relationship: String, Codable, CaseIterable, Hashable {
    case none, friends, incoming, outgoing
}

/// Direction of a pending friend request.
enum RequestDirection: String, Codable, CaseIterable, Hashable {
    case incoming, outgoing
}
