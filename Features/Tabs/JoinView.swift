import SwiftUI

/// Join-by-code screen. Port of (tabs)/join.tsx. Look up a preview from an invite
/// code, then commit the stake and open the challenge. Also lists pending invites.
struct JoinView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    @State private var code = ""
    @State private var preview: ChallengePreview?
    @State private var invites: [ChallengeInvite] = []
    @State private var error: String?
    @State private var isLookingUp = false
    @State private var isJoining = false
    @State private var busyInviteId: String?
    @State private var confirmConfig: ConfirmDialogConfig?
    @State private var toast: String?

    private var codeIsValid: Bool {
        code.trimmingCharacters(in: .whitespaces).count == 6
    }

    var body: some View {
        Screen(title: "Join") {
            AppTextField(
                label: "Invite code",
                text: $code,
                placeholder: "ABC123",
                error: error,
                autocapitalization: .characters,
                submitLabel: .search,
                onSubmit: lookUp
            )
            .onChange(of: code) { _, newValue in
                let upper = String(newValue.uppercased().prefix(6))
                if upper != code { code = upper }
                preview = nil
                error = nil
            }

            AppButton(
                "Look up challenge",
                isLoading: isLookingUp,
                isDisabled: isLookingUp || !codeIsValid,
                action: lookUp
            )

            if let preview {
                previewCard(preview)
            }

            if !invites.isEmpty {
                invitesSection
            }

            Text(Copy.trustDisclaimer).textStyle(.small, color: theme.colors.textFaint)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .confirmDialog($confirmConfig)
        .task { await loadInvites() }
        .refreshable { await loadInvites() }
    }

    // MARK: - Preview

    private func previewCard(_ preview: ChallengePreview) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                HStack(alignment: .center, spacing: Spacing.two) {
                    Text(preview.title).textStyle(.h3, color: theme.colors.text)
                    Spacer(minLength: Spacing.two)
                    StatusChip(challengeStatus: preview.status)
                }

                if !preview.description.isEmpty {
                    Text(preview.description).textStyle(.body, color: theme.colors.textDim)
                }

                Text("Created by \(preview.creatorName) · \(playerCount(preview.participantCount)) · \(frequencyLabel(preview.frequency)) check-ins")
                    .textStyle(.small, color: theme.colors.textFaint)

                Text(scheduleLine(preview))
                    .textStyle(.small, color: theme.colors.textFaint)

                Text("\(Format.money(preview.entryFee)) on the line (simulated)")
                    .textStyle(.bodyStrong, color: theme.colors.text)
                    .padding(.top, Spacing.one)

                if preview.alreadyJoined {
                    AppButton("Open challenge") {
                        nav.push(.challengeDetail(challengeId: preview.id))
                    }
                    .padding(.top, Spacing.two)
                } else {
                    AppButton(
                        "Join · commit \(Format.money(preview.entryFee))",
                        isLoading: isJoining,
                        isDisabled: isJoining
                    ) { askToJoin(preview) }
                    .padding(.top, Spacing.two)
                }
            }
        }
    }

    private func scheduleLine(_ preview: ChallengePreview) -> String {
        let start = "Starts \(Format.date(preview.startAt))"
        if let end = preview.endAt {
            return "\(start) · ends \(Format.date(end))"
        }
        return "\(start) · last one standing"
    }

    // MARK: - Invites

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Pending invites · \(invites.count)")
                .textStyle(.label, color: theme.colors.textFaint)
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

    // MARK: - Helpers

    private func playerCount(_ n: Int) -> String {
        "\(n) \(n == 1 ? "player" : "players")"
    }

    /// Label for a preview's cadence (no periodDays available on the preview).
    private func frequencyLabel(_ f: ChallengeFrequency) -> String {
        switch f {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Periodic"
        }
    }

    // MARK: - Actions

    private func lookUp() {
        guard codeIsValid, !isLookingUp else { return }
        isLookingUp = true
        error = nil
        Task {
            defer { isLookingUp = false }
            do {
                preview = try await ChallengeService.getChallengePreview(
                    code: code.trimmingCharacters(in: .whitespaces)
                )
            } catch {
                preview = nil
                self.error = Format.errorMessage(error)
            }
        }
    }

    private func askToJoin(_ preview: ChallengePreview) {
        confirmConfig = ConfirmDialogConfig(
            title: "Join this challenge?",
            message: "You'll commit \(Format.money(preview.entryFee)) (simulated) to \"\(preview.title)\". If you miss a check-in or back out, that stake is forfeited.",
            confirmLabel: "Commit \(Format.money(preview.entryFee))",
            onConfirm: { join(preview) }
        )
    }

    private func join(_ preview: ChallengePreview) {
        guard !isJoining else { return }
        isJoining = true
        error = nil
        Task {
            defer { isJoining = false }
            do {
                let challenge = try await ChallengeService.joinByInviteCode(
                    code.trimmingCharacters(in: .whitespaces)
                )
                await session.refreshProfile()
                self.preview = nil
                code = ""
                nav.push(.challengeDetail(challengeId: challenge.id))
            } catch {
                self.error = Format.errorMessage(error)
            }
        }
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
                await loadInvites()
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

    private func loadInvites() async {
        do {
            invites = try await ChallengeService.listInvites()
        } catch {
            // Non-fatal: the lookup flow still works without the invites list.
            toast = Format.errorMessage(error)
        }
    }
}
