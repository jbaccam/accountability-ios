import SwiftUI

/// Final standings. Port of challenge/[id]/results.tsx. Celebrates showing up:
/// quiet trophy, winners named, payouts as a small detail, full standings below.
struct ResultsView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session

    let challengeId: String

    @State private var detail: ChallengeDetail?
    @State private var isLoading = true
    @State private var error: String?

    private var myId: String? { session.userId }

    private static let joinedStatuses: Set<ParticipantStatus> = [.active, .eliminated, .winner]
    /// Standings sort: winners first, then still-active, then out.
    private static let order: [ParticipantStatus: Int] = [
        .winner: 0, .active: 1, .eliminated: 2, .refunded: 3, .invited: 4,
    ]

    var body: some View {
        Screen(title: "Results") {
            if let detail {
                content(detail)
            } else if let error {
                Text(error).textStyle(.body, color: theme.colors.danger)
            } else {
                LoadingState().frame(height: 200)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private func content(_ detail: ChallengeDetail) -> some View {
        let challenge = detail.challenge
        let joined = detail.participants.filter { Self.joinedStatuses.contains($0.status) }
        let pot = challenge.entryFee * Double(joined.count)
        let winners = detail.participants.filter { $0.status == .winner }
        let standings = detail.participants.sorted {
            (Self.order[$0.status] ?? 9) < (Self.order[$1.status] ?? 9)
        }

        heroCard(winners: winners, pot: pot, status: challenge.status)

        Text("Final standings").textStyle(.title, color: theme.colors.text)
        Card(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(standings.enumerated()), id: \.element.id) { index, p in
                    standingRow(p, divider: index > 0)
                }
            }
        }

        Text(Copy.simulatedBalanceNote).textStyle(.small, color: theme.colors.textFaint)
    }

    private func heroCard(winners: [ParticipantWithProfile], pot: Double, status: ChallengeStatus) -> some View {
        Card(tone: winners.isEmpty ? .default : .accent) {
            VStack(spacing: Spacing.two) {
                if winners.isEmpty {
                    Text("No winner").textStyle(.h2, color: theme.colors.text)
                    Text(status == .cancelled
                        ? "The challenge was cancelled and stakes were refunded."
                        : "This challenge ended without a winner.")
                        .textStyle(.body, color: theme.colors.textDim)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(theme.colors.text)
                        .padding(.bottom, Spacing.one)
                    Text(winners.map { $0.profiles.displayName }.joined(separator: " & "))
                        .textStyle(.h2, color: theme.colors.text)
                        .multilineTextAlignment(.center)
                    Text("\(winners.count > 1 ? "split" : "takes") the \(Copy.simulatedPotLabel.lowercased()) of \(Format.money(pot))")
                        .textStyle(.body, color: theme.colors.textDim)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.three)
        }
    }

    private func standingRow(_ p: ParticipantWithProfile, divider: Bool) -> some View {
        let isMe = p.userId == myId
        return VStack(spacing: 0) {
            if divider {
                Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
            }
            HStack(spacing: Spacing.two + 4) {
                Avatar(name: p.profiles.displayName, url: p.profiles.avatarUrl, isYou: isMe)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(p.profiles.displayName)\(isMe ? " (you)" : "")")
                        .textStyle(.bodyStrong, color: theme.colors.text)
                    if p.status == .winner, let payout = p.payoutAmount {
                        Text("+\(Format.money(payout)) (simulated)")
                            .textStyle(.small, color: theme.colors.success)
                    } else if p.status == .eliminated {
                        Text(eliminationDetail(p))
                            .textStyle(.caption, color: theme.colors.textFaint)
                    }
                }
                Spacer(minLength: Spacing.two)
                ParticipantStatusChip(status: p.status)
            }
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.two + 2)
        }
    }

    private func eliminationDetail(_ p: ParticipantWithProfile) -> String {
        let reason = p.eliminationReason?.replacingOccurrences(of: "_", with: " ") ?? "eliminated"
        if let at = p.eliminatedAt {
            return "\(reason) · \(Format.dateTime(at))"
        }
        return reason
    }

    private func load() async {
        guard let myId else { return }
        do {
            detail = try await ChallengeService.getDetail(challengeId: challengeId, myUserId: myId)
            error = nil
        } catch {
            self.error = Format.errorMessage(error)
        }
        isLoading = false
    }
}
