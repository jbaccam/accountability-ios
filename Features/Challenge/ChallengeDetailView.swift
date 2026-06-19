import SwiftUI

/// Challenge detail. Port of challenge/[id]/index.tsx. Progress is the hero:
/// standings + a slim bar lead; money is a small "on the line" detail. The
/// check-in CTA, review nudge, resolve, and results all live here.
struct ChallengeDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    let challengeId: String

    @State private var detail: ChallengeDetail?
    @State private var isLoading = true
    @State private var error: String?
    @State private var confirmConfig: ConfirmDialogConfig?
    @State private var toast: String?

    private var myId: String? { session.userId }

    /// Participant statuses that count as "joined" / "still in".
    private static let joinedStatuses: Set<ParticipantStatus> = [.active, .eliminated, .winner]
    private static let activeStatuses: Set<ParticipantStatus> = [.active, .winner]

    var body: some View {
        Screen {
            if let detail {
                content(detail)
            } else if let error {
                Card(tone: .warning) {
                    Text(error).textStyle(.body, color: theme.colors.danger)
                }
            } else {
                LoadingState().frame(height: 240)
            }
        }
        .navigationTitle(detail?.challenge.title ?? "Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .confirmDialog($confirmConfig)
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ detail: ChallengeDetail) -> some View {
        let challenge = detail.challenge
        let isCreator = challenge.creatorId == myId
        let me = detail.participants.first { $0.userId == myId }
        let joined = detail.participants.filter { Self.joinedStatuses.contains($0.status) }
        let stillIn = joined.filter { Self.activeStatuses.contains($0.status) }.count
        let total = max(joined.count, 1)
        let progress = Double(stillIn) / Double(total)
        let pot = challenge.entryFee * Double(joined.count)
        let playing = me != nil && [.active, .needsResolution].contains(challenge.status)

        header(challenge, stillIn: stillIn, joinedCount: joined.count, progress: progress, pot: pot)

        if challenge.status == .active {
            inviteCard(challenge, showInvite: me != nil)
        }

        if challenge.status == .needsResolution {
            needsResolutionCard(challenge, isCreator: isCreator)
        }

        if let me, challenge.status == .active {
            checkinCard(detail, me: me)
        }

        if playing && !detail.notStarted {
            reviewNudge(detail)
        }

        if challenge.status == .completed {
            AppButton("View results", icon: "trophy") {
                nav.push(.results(challengeId: challengeId))
            }
        }

        playersSection(detail)
        rulesSection(challenge)

        if !detail.resolutions.isEmpty {
            resolutionsSection(detail.resolutions)
        }

        // Destructive actions.
        if isCreator && challenge.status == .active && detail.notStarted {
            AppButton("Cancel challenge", variant: .danger) { askCancel(challenge) }
        }
        if canLeave(me: me, isCreator: isCreator, status: challenge.status) {
            AppButton("Leave challenge", variant: .danger) { askLeave(challenge) }
        }
    }

    // MARK: - Header

    private func header(
        _ challenge: Challenge,
        stillIn: Int,
        joinedCount: Int,
        progress: Double,
        pot: Double
    ) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                HStack(alignment: .center, spacing: Spacing.two) {
                    Text(challenge.title).textStyle(.h2, color: theme.colors.text)
                    Spacer(minLength: Spacing.two)
                    StatusChip(challengeStatus: challenge.status)
                }

                if !challenge.description.isEmpty {
                    Text(challenge.description).textStyle(.body, color: theme.colors.textDim)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(stillIn) of \(joinedCount) still in")
                            .textStyle(.bodyStrong, color: theme.colors.text)
                        Spacer()
                        Text("\(Int((progress * 100).rounded()))%")
                            .textStyle(.small, color: theme.colors.textFaint)
                    }
                    SlimProgressBar(progress: progress)
                }
                .padding(.top, Spacing.one)

                Text(scheduleLine(challenge))
                    .textStyle(.small, color: theme.colors.textFaint)
                    .padding(.top, Spacing.one)

                Text("\(Format.money(challenge.entryFee)) each on the line · \(Copy.simulatedPotLabel) \(Format.money(pot)) (simulated)")
                    .textStyle(.caption, color: theme.colors.textFaint)
            }
        }
    }

    private func scheduleLine(_ challenge: Challenge) -> String {
        let base = "\(Format.frequency(challenge.frequency, periodDays: challenge.periodDays)) check-ins · starts \(Format.date(challenge.startAt))"
        if let end = challenge.endAt {
            return "\(base) · ends \(Format.date(end))"
        }
        return "\(base) · last one standing"
    }

    // MARK: - Invite card

    private func inviteCard(_ challenge: Challenge, showInvite: Bool) -> some View {
        Card(tone: .flat) {
            VStack(alignment: .leading, spacing: Spacing.three) {
                HStack(alignment: .center, spacing: Spacing.two) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invite code").textStyle(.label, color: theme.colors.textFaint)
                        Text(challenge.inviteCode)
                            .textStyle(.h3, color: theme.colors.text)
                            .tracking(4)
                            .monospacedDigit()
                    }
                    Spacer(minLength: Spacing.two)
                    AppButton("Copy", variant: .secondary, size: .sm, icon: "doc.on.doc", fullWidth: false) {
                        UIPasteboard.general.string = challenge.inviteCode
                        toast = "Invite code copied."
                    }
                }
                if showInvite {
                    AppButton("Invite friends", variant: .secondary, size: .md, icon: "person.badge.plus") {
                        nav.push(.invite(challengeId: challengeId))
                    }
                }
            }
        }
    }

    // MARK: - Needs resolution

    private func needsResolutionCard(_ challenge: Challenge, isCreator: Bool) -> some View {
        Card(tone: .warning) {
            VStack(alignment: .leading, spacing: Spacing.two) {
                Text("Everyone failed this round").textStyle(.title, color: theme.colors.warning)
                Text(isCreator
                    ? "The challenge is paused. As the creator, you decide what happens next."
                    : "The challenge is paused. The creator decides: refund everyone or play a tie-breaker round.")
                    .textStyle(.small, color: theme.colors.textDim)
                if isCreator {
                    AppButton("Resolve now") {
                        nav.push(.resolve(challengeId: challengeId))
                    }
                    .padding(.top, Spacing.one)
                }
            }
        }
    }

    // MARK: - Check-in hero

    private func checkinCard(_ detail: ChallengeDetail, me: ParticipantWithProfile) -> some View {
        let challenge = detail.challenge
        let mineForCurrent = detail.currentPeriod.flatMap { period in
            detail.mySubmissions.first { $0.periodId == period.id }
        }
        return Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                HStack(alignment: .center, spacing: Spacing.two) {
                    Text(me.status == .active ? "Your check-in" : "Your status")
                        .textStyle(.title, color: theme.colors.text)
                    Spacer(minLength: Spacing.two)
                    ParticipantStatusChip(status: me.status)
                }

                if me.status == .eliminated {
                    Text("Eliminated\(me.eliminationReason.map { " — \($0.replacingOccurrences(of: "_", with: " "))" } ?? ""). Your stake stays in the pot, and you can still review proofs.")
                        .textStyle(.small, color: theme.colors.textDim)
                } else if me.status == .active && detail.notStarted {
                    Text("Starts \(Format.date(challenge.startAt)). Invite friends before kickoff!")
                        .textStyle(.body, color: theme.colors.textDim)
                } else if me.status == .active, let period = detail.currentPeriod {
                    if let mine = mineForCurrent {
                        HStack(alignment: .center, spacing: Spacing.two) {
                            Text("This round's proof").textStyle(.body, color: theme.colors.textDim)
                            Spacer(minLength: Spacing.two)
                            StatusChip(submissionStatus: mine.status)
                        }
                    } else {
                        HStack(spacing: Spacing.two) {
                            Image(systemName: "clock")
                                .font(.system(size: 15))
                                .foregroundStyle(theme.colors.textDim)
                            Text("Due \(Format.countdown(deadline: period.submissionDeadline, now: detail.now))")
                                .textStyle(.body, color: theme.colors.textDim)
                        }
                        AppButton("Submit proof", icon: "camera") {
                            nav.push(.submit(challengeId: challengeId))
                        }
                        .padding(.top, Spacing.one)
                    }
                } else if me.status == .active {
                    Text("No open check-in window right now. Pull to refresh.")
                        .textStyle(.small, color: theme.colors.textDim)
                }
            }
        }
    }

    // MARK: - Review nudge

    private func reviewNudge(_ detail: ChallengeDetail) -> some View {
        let count = detail.reviewQueueCount
        return PressableCard {
            nav.push(.review(challengeId: challengeId))
        } content: {
            HStack(spacing: Spacing.two) {
                Image(systemName: "gavel")
                    .font(.system(size: 20))
                    .foregroundStyle(theme.colors.accent)
                Text(count > 0
                    ? "\(count) \(count == 1 ? "proof needs" : "proofs need") your review"
                    : "Review proofs")
                    .textStyle(.body, color: theme.colors.text)
                Spacer(minLength: Spacing.two)
                if count > 0 {
                    Text("\(count)")
                        .textStyle(.caption, color: theme.colors.onAccent)
                        .fontWeight(.heavy)
                        .frame(minWidth: 22, minHeight: 22)
                        .padding(.horizontal, 6)
                        .background(theme.colors.accent)
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.colors.textFaint)
            }
        }
    }

    // MARK: - Players

    private func playersSection(_ detail: ChallengeDetail) -> some View {
        let challenge = detail.challenge
        return VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Players").textStyle(.title, color: theme.colors.text)
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(detail.participants.enumerated()), id: \.element.id) { index, p in
                        playerRow(p, challenge: challenge, divider: index > 0)
                    }
                }
            }
        }
    }

    private func playerRow(
        _ p: ParticipantWithProfile,
        challenge: Challenge,
        divider: Bool
    ) -> some View {
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
                        .lineLimit(1)
                    Text(playerSubtitle(p, challenge: challenge))
                        .textStyle(.caption, color: theme.colors.textFaint)
                }
                Spacer(minLength: Spacing.two)
                ParticipantStatusChip(status: p.status)
            }
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.two + 2)
        }
    }

    private func playerSubtitle(_ p: ParticipantWithProfile, challenge: Challenge) -> String {
        var parts = [p.userId == challenge.creatorId ? "Creator" : "Player"]
        if p.status == .winner, let payout = p.payoutAmount {
            parts.append("won \(Format.money(payout))")
        }
        if p.status == .eliminated, let reason = p.eliminationReason {
            parts.append(reason.replacingOccurrences(of: "_", with: " "))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Rules

    private func rulesSection(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Rules").textStyle(.title, color: theme.colors.text)
            Card {
                VStack(alignment: .leading, spacing: 0) {
                    ruleRow("camera", proofText(challenge))
                    ruleRow("gavel", "Review: \(reviewLabel(challenge.reviewMethod))")
                    ruleRow("clock", deadlineText(challenge))
                    ruleRow("trophy", payoutText(challenge))
                }
            }
        }
    }

    private func ruleRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.two) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(theme.colors.accent)
                .frame(width: 20, alignment: .center)
            Text(text).textStyle(.small, color: theme.colors.textDim)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }

    private func proofText(_ c: Challenge) -> String {
        var s = "Proof: photo + timestamp"
        if c.proofRequiresCaption { s += " + caption" }
        if c.proofRequiresLocation { s += " + location" }
        return s
    }

    private func deadlineText(_ c: Challenge) -> String {
        let when = c.submissionDeadlineTime.map { Format.clockTime($0) } ?? "end of period"
        let grace = c.gracePeriodMinutes > 0 ? " (+\(c.gracePeriodMinutes) min grace)" : ""
        return "Deadline: \(when)\(grace)"
    }

    private func payoutText(_ c: Challenge) -> String {
        let rule = c.payoutRule == .winnerTakesAll ? "winner takes all" : "split among winners"
        return "Payout: \(rule). Miss a check-in or get rejected and you're out."
    }

    private func reviewLabel(_ method: ReviewMethod) -> String {
        switch method {
        case .majority: return "Majority vote (creator breaks ties)"
        case .creatorDecides: return "Creator decides"
        case .unanimous: return "Unanimous approval"
        case .autoApprove: return "Auto-approve unless rejected"
        case .groupVote: return "Group vote"
        }
    }

    // MARK: - Resolutions

    private func resolutionsSection(_ resolutions: [ChallengeResolution]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Resolutions").textStyle(.title, color: theme.colors.text)
            ForEach(resolutions) { r in
                Card {
                    VStack(alignment: .leading, spacing: Spacing.two) {
                        Text("\(resolutionLabel(r.resolutionType)) · \(Format.date(r.createdAt))")
                            .textStyle(.body, color: theme.colors.text)
                        if !r.notes.isEmpty {
                            Text("“\(r.notes)”").textStyle(.small, color: theme.colors.textDim)
                        }
                    }
                }
            }
        }
    }

    private func resolutionLabel(_ type: ResolutionType) -> String {
        switch type {
        case .refund: return "Stakes refunded"
        case .tiebreaker: return "Tie-breaker round started"
        case .manualWinner: return "Winner chosen manually"
        }
    }

    // MARK: - Permissions

    private func canLeave(me: ParticipantWithProfile?, isCreator: Bool, status: ChallengeStatus) -> Bool {
        me?.status == .active && !isCreator && [.active, .needsResolution].contains(status)
    }

    // MARK: - Data + actions

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

    private func askCancel(_ challenge: Challenge) {
        confirmConfig = ConfirmDialogConfig(
            title: "Cancel challenge?",
            message: "Everyone gets their simulated stake back. This can't be undone.",
            confirmLabel: "Cancel challenge",
            destructive: true,
            onConfirm: { cancel(challenge) }
        )
    }

    private func cancel(_ challenge: Challenge) {
        Task {
            do {
                _ = try await ChallengeService.cancel(challenge.id)
                await session.refreshProfile()
                await load()
                toast = "Challenge cancelled — stakes refunded."
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }

    private func askLeave(_ challenge: Challenge) {
        confirmConfig = ConfirmDialogConfig(
            title: "Leave challenge?",
            message: "You'll forfeit your \(Format.money(challenge.entryFee)) stake (simulated) and you can't rejoin. This can't be undone.",
            confirmLabel: "Leave & forfeit",
            destructive: true,
            onConfirm: { leave(challenge) }
        )
    }

    private func leave(_ challenge: Challenge) {
        Task {
            do {
                _ = try await ChallengeService.leave(challenge.id)
                await session.refreshProfile()
                await load()
                toast = "You left the challenge."
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}

/// Maps a participant status onto a StatusChip. The shared StatusChip only ships
/// challenge/submission initializers, so this lives with the challenge feature.
struct ParticipantStatusChip: View {
    let status: ParticipantStatus

    var body: some View {
        switch status {
        case .invited: StatusChip(text: "Invited", kind: .neutral)
        case .active: StatusChip(text: "Active", kind: .success)
        case .eliminated: StatusChip(text: "Out", kind: .danger)
        case .winner: StatusChip(text: "Winner", kind: .success)
        case .refunded: StatusChip(text: "Refunded", kind: .info)
        }
    }
}
