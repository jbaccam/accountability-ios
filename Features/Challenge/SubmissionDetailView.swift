import SwiftUI

/// A single proof + its votes. Port of challenge/[id]/submission/[submissionId].tsx.
/// Active reviewers vote (approve/reject with an optional reason); the creator
/// settles submissions the group vote could not. The contract only hands us a
/// submissionId, so the parent challenge is loaded from the submission itself.
struct SubmissionDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session

    let submissionId: String

    @State private var submission: SubmissionWithDetails?
    @State private var creatorId: String?
    @State private var amActive = false
    @State private var photoURL: URL?
    @State private var reason = ""
    @State private var isLoading = true
    @State private var isBusy = false
    @State private var toast: String?

    private var myId: String? { session.userId }

    var body: some View {
        Screen(title: "Proof") {
            if let submission {
                content(submission)
            } else if isLoading {
                LoadingState().frame(height: 200)
            } else {
                EmptyState(icon: "photo", title: "Proof unavailable", message: "This submission could not be loaded.")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ s: SubmissionWithDetails) -> some View {
        let isMine = s.userId == myId
        let isCreator = creatorId != nil && creatorId == myId
        let canVote = amActive && !isMine && s.status == .pending
        let myVote = s.submissionVotes.first { $0.voterId == myId }

        proofCard(s, isMine: isMine)

        if canVote {
            voteCard(myVote: myVote)
        }

        if isCreator && s.status == .needsResolution {
            creatorCard
        }

        votesSection(s)
    }

    private func proofCard(_ s: SubmissionWithDetails, isMine: Bool) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                HStack(alignment: .center, spacing: Spacing.two) {
                    HStack(spacing: Spacing.two) {
                        Avatar(name: s.profiles.displayName, url: s.profiles.avatarUrl, isYou: isMine)
                        Text("\(s.profiles.displayName)\(isMine ? " (you)" : "")")
                            .textStyle(.title, color: theme.colors.text)
                            .lineLimit(1)
                    }
                    Spacer(minLength: Spacing.two)
                    StatusChip(submissionStatus: s.status)
                }

                proofPhoto

                if !s.caption.isEmpty {
                    Text(s.caption).textStyle(.body, color: theme.colors.text)
                }

                Text("Submitted \(Format.dateTime(s.submittedAt))")
                    .textStyle(.caption, color: theme.colors.textFaint)

                if let lat = s.locationLat, let lng = s.locationLng {
                    HStack(spacing: Spacing.one) {
                        Image(systemName: "mappin")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.colors.textDim)
                        Text(String(format: "%.4f, %.4f", lat, lng))
                            .textStyle(.caption, color: theme.colors.textFaint)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var proofPhoto: some View {
        if let photoURL {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    ZStack { theme.colors.surfaceAlt; ProgressView().tint(theme.colors.accent) }
                default:
                    ZStack {
                        theme.colors.surfaceAlt
                        Text("Couldn't load photo").textStyle(.small, color: theme.colors.textFaint)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        } else if submission?.photoPath == nil {
            Text("No photo attached.").textStyle(.small, color: theme.colors.textDim)
        }
    }

    private func voteCard(myVote: VoteWithProfile?) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                Text(myVote.map { "You voted \($0.vote.rawValue) — change it?" } ?? "Your verdict")
                    .textStyle(.title, color: theme.colors.text)
                AppTextField(
                    label: "",
                    text: $reason,
                    placeholder: "Reason (optional)"
                )
                voteButtons(
                    onApprove: { castVote(.approve) },
                    onReject: { castVote(.reject) }
                )
            }
        }
    }

    private var creatorCard: some View {
        Card(tone: .warning) {
            VStack(alignment: .leading, spacing: Spacing.two) {
                Text("Creator decision needed").textStyle(.title, color: theme.colors.warning)
                Text("The vote was tied or too few people voted. Your call is final.")
                    .textStyle(.small, color: theme.colors.textDim)
                voteButtons(
                    onApprove: { creatorResolve(true) },
                    onReject: { creatorResolve(false) }
                )
            }
        }
    }

    private func voteButtons(onApprove: @escaping () -> Void, onReject: @escaping () -> Void) -> some View {
        HStack(spacing: Spacing.two) {
            AppButton("Approve", size: .md, icon: "checkmark", isLoading: isBusy, isDisabled: isBusy, action: onApprove)
            AppButton("Reject", variant: .danger, size: .md, icon: "xmark", isLoading: isBusy, isDisabled: isBusy, action: onReject)
        }
        .padding(.top, Spacing.one)
    }

    private func votesSection(_ s: SubmissionWithDetails) -> some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Votes (\(s.submissionVotes.count))").textStyle(.title, color: theme.colors.text)
            if s.submissionVotes.isEmpty {
                Text("No votes yet.").textStyle(.small, color: theme.colors.textDim)
            } else {
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(s.submissionVotes.enumerated()), id: \.element.id) { index, v in
                            voteRow(v, divider: index > 0)
                        }
                    }
                }
            }
        }
    }

    private func voteRow(_ v: VoteWithProfile, divider: Bool) -> some View {
        VStack(spacing: 0) {
            if divider {
                Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
            }
            HStack(alignment: .center, spacing: Spacing.two) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(v.profiles.displayName).textStyle(.bodyStrong, color: theme.colors.text)
                    if let reason = v.reason, !reason.isEmpty {
                        Text("“\(reason)”").textStyle(.small, color: theme.colors.textDim)
                    }
                }
                Spacer(minLength: Spacing.two)
                Text(v.vote.rawValue.uppercased())
                    .textStyle(.label, color: v.vote == .approve ? theme.colors.success : theme.colors.danger)
            }
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.two + 2)
        }
    }

    // MARK: - Data + actions

    private func load() async {
        do {
            let sub = try await SubmissionService.getSubmission(submissionId)
            submission = sub
            if let path = sub.photoPath {
                photoURL = try? await SubmissionService.proofPhotoURL(path)
            }
            // Pull creator + my participant status from the parent challenge.
            if let myId, let detail = try? await ChallengeService.getDetail(
                challengeId: sub.challengeId, myUserId: myId
            ) {
                creatorId = detail.challenge.creatorId
                amActive = detail.participants.first { $0.userId == myId }?.status == .active
            }
        } catch {
            toast = Format.errorMessage(error)
        }
        isLoading = false
    }

    private func castVote(_ vote: VoteValue) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                _ = try await SubmissionService.vote(
                    submissionId: submissionId,
                    vote: vote,
                    reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                reason = ""
                await load()
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }

    private func creatorResolve(_ approve: Bool) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                _ = try await SubmissionService.resolveSubmission(submissionId: submissionId, approve: approve)
                await load()
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
