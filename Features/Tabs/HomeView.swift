import SwiftUI

/// Home / my challenges. Port of (tabs)/index.tsx. Progress is the hero: each
/// challenge shows a quiet "X of Y still in" line + a slim bar, with the stake
/// as a small "on the line" detail. No hero pot numbers.
struct HomeView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    @State private var challenges: [ChallengeListItem] = []
    @State private var invites: [ChallengeInvite] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var busyInviteId: String?
    @State private var toast: String?

    /// Participant statuses that still count as "in the running".
    private static let activeStatuses: Set<String> = ["active", "winner"]
    private static let joinedStatuses: Set<String> = ["active", "eliminated", "winner"]
    /// Sort order so the things that need attention float up.
    private static let statusOrder: [ChallengeStatus: Int] = [
        .needsResolution: 0, .active: 1, .completed: 2, .cancelled: 3, .draft: 4,
    ]

    private var sortedChallenges: [ChallengeListItem] {
        challenges.sorted {
            let a = Self.statusOrder[$0.challenge.status] ?? 9
            let b = Self.statusOrder[$1.challenge.status] ?? 9
            return a < b
        }
    }

    private var firstName: String {
        let name = session.profile?.displayName ?? ""
        return name.split(separator: " ").first.map(String.init) ?? ""
    }

    var body: some View {
        Screen(title: greeting) {
            if let error {
                Card(tone: .warning) {
                    Text("Could not load challenges: \(error)")
                        .textStyle(.small, color: theme.colors.danger)
                }
            }

            if !invites.isEmpty {
                invitesSection
            }

            if isLoading && challenges.isEmpty && invites.isEmpty {
                LoadingState().frame(height: 200)
            } else if challenges.isEmpty && !isLoading {
                emptyState
            } else {
                challengeList
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task { await load() }
        .refreshable { await load() }
    }

    private var greeting: String {
        firstName.isEmpty ? "Your challenges" : "Hi, \(firstName)"
    }

    // MARK: - Invites

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Invites · \(invites.count)").textStyle(.label, color: theme.colors.textFaint)
            ForEach(invites) { invite in
                Card(tone: .accent) {
                    VStack(alignment: .leading, spacing: Spacing.two) {
                        Text(invite.title).textStyle(.title, color: theme.colors.text)
                            .lineLimit(1)
                        Text("\(invite.inviterName) invited you · \(playerCount(invite.participantCount)) · starts \(Format.date(invite.startAt))")
                            .textStyle(.small, color: theme.colors.textDim)
                        Text("\(Format.money(invite.entryFee)) on the line (simulated)")
                            .textStyle(.bodyStrong, color: theme.colors.text)
                        HStack(spacing: Spacing.two) {
                            AppButton(
                                "Decline",
                                variant: .secondary,
                                size: .sm,
                                isLoading: busyInviteId == invite.id,
                                isDisabled: busyInviteId != nil
                            ) { respond(to: invite, accept: false) }
                            AppButton(
                                "Accept",
                                size: .sm,
                                isLoading: busyInviteId == invite.id,
                                isDisabled: busyInviteId != nil
                            ) { respond(to: invite, accept: true) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        // Create / Join live in their own tabs, so the empty state points there
        // rather than pushing a route (there is no route for those roots).
        EmptyState(
            icon: "trophy",
            title: "No challenges yet",
            message: "Start one from the Create tab, or join with a code from the Join tab. Put something on the line and show up."
        )
    }

    // MARK: - Challenge list

    private var challengeList: some View {
        VStack(alignment: .leading, spacing: Spacing.three) {
            Text("Your challenges").textStyle(.label, color: theme.colors.textFaint)
            ForEach(sortedChallenges) { item in
                challengeCard(item)
            }
        }
    }

    private func challengeCard(_ item: ChallengeListItem) -> some View {
        let challenge = item.challenge
        let joined = item.participants.filter { Self.joinedStatuses.contains($0.status) }
        let stillIn = joined.filter { Self.activeStatuses.contains($0.status) }.count
        let total = max(joined.count, 1)
        let progress = Double(stillIn) / Double(total)

        return PressableCard {
            nav.push(.challengeDetail(challengeId: challenge.id))
        } content: {
            VStack(alignment: .leading, spacing: Spacing.three) {
                HStack(alignment: .center, spacing: Spacing.two) {
                    Text(challenge.title).textStyle(.title, color: theme.colors.text)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.two)
                    StatusChip(challengeStatus: challenge.status)
                }

                HStack(spacing: Spacing.one + 2) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.colors.textFaint)
                    Text("\(Format.frequency(challenge.frequency, periodDays: challenge.periodDays)) · \(playerCount(joined.count)) · \(Format.money(challenge.entryFee)) on the line")
                        .textStyle(.small, color: theme.colors.textDim)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(stillIn) of \(joined.count) still in")
                            .textStyle(.bodyStrong, color: theme.colors.text)
                        Spacer()
                        Text("\(Int((progress * 100).rounded()))%")
                            .textStyle(.small, color: theme.colors.textFaint)
                    }
                    SlimProgressBar(progress: progress)
                }
            }
        }
    }

    // MARK: - Helpers

    private func playerCount(_ n: Int) -> String {
        "\(n) \(n == 1 ? "player" : "players")"
    }

    // MARK: - Data

    private func load() async {
        do {
            async let challengeReq = ChallengeService.listMyChallenges()
            async let inviteReq = ChallengeService.listInvites()
            let (c, i) = try await (challengeReq, inviteReq)
            challenges = c
            invites = i
            error = nil
        } catch {
            self.error = Format.errorMessage(error)
        }
        isLoading = false
    }

    private func respond(to invite: ChallengeInvite, accept: Bool) {
        guard busyInviteId == nil else { return }
        busyInviteId = invite.id
        Task {
            defer { busyInviteId = nil }
            do {
                let challenge = try await ChallengeService.respondInvite(
                    inviteId: invite.inviteId, accept: accept
                )
                await session.refreshProfile()
                await load()
                if accept {
                    toast = "Joined \"\(invite.title)\" — stake committed."
                    nav.push(.challengeDetail(challengeId: challenge.id))
                } else {
                    toast = "Invite declined."
                }
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
