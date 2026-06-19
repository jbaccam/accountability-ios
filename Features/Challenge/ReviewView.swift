import SwiftUI

/// Review queue. Port of challenge/[id]/review.tsx. Splits submissions into the
/// ones waiting on my vote, the ones the creator must settle, and everything
/// else. Tapping a row opens the submission detail to actually vote.
struct ReviewView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    let challengeId: String

    @State private var submissions: [SubmissionWithDetails] = []
    @State private var creatorId: String?
    @State private var isLoading = true
    @State private var error: String?

    private var myId: String? { session.userId }
    private var isCreator: Bool { creatorId != nil && creatorId == myId }

    private var needsMyVote: [SubmissionWithDetails] {
        submissions.filter {
            $0.status == .pending
                && $0.userId != myId
                && !$0.submissionVotes.contains { $0.voterId == myId }
        }
    }
    private var needsCreator: [SubmissionWithDetails] {
        submissions.filter { $0.status == .needsResolution }
    }
    private var rest: [SubmissionWithDetails] {
        let handled = Set(needsMyVote.map(\.id)).union(needsCreator.map(\.id))
        return submissions.filter { !handled.contains($0.id) }
    }

    var body: some View {
        Screen(title: "Review proofs") {
            if let error {
                Text(error).textStyle(.small, color: theme.colors.danger)
            }

            if isLoading && submissions.isEmpty {
                LoadingState().frame(height: 200)
            } else {
                Text("Waiting on your vote (\(needsMyVote.count))")
                    .textStyle(.title, color: theme.colors.text)
                if needsMyVote.isEmpty {
                    EmptyState(
                        icon: "checkmark.seal",
                        title: "All caught up",
                        message: "Nothing needs your review right now."
                    )
                } else {
                    ForEach(needsMyVote) { row($0) }
                }

                if !needsCreator.isEmpty {
                    Text(isCreator
                        ? "Needs your decision (\(needsCreator.count))"
                        : "Waiting on the creator (\(needsCreator.count))")
                        .textStyle(.title, color: theme.colors.text)
                        .padding(.top, Spacing.one)
                    if isCreator {
                        Text("The group vote did not settle these. As creator, you make the call.")
                            .textStyle(.small, color: theme.colors.textDim)
                    }
                    ForEach(needsCreator) { row($0) }
                }

                if !rest.isEmpty {
                    Text("All submissions")
                        .textStyle(.title, color: theme.colors.text)
                        .padding(.top, Spacing.one)
                    ForEach(rest) { row($0) }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func row(_ s: SubmissionWithDetails) -> some View {
        let isMe = s.userId == myId
        return PressableCard {
            nav.push(.submissionDetail(submissionId: s.id))
        } content: {
            HStack(spacing: Spacing.two + 4) {
                Avatar(name: s.profiles.displayName, url: s.profiles.avatarUrl, isYou: isMe)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(s.profiles.displayName)\(isMe ? " (you)" : "")")
                        .textStyle(.bodyStrong, color: theme.colors.text)
                        .lineLimit(1)
                    if !s.caption.isEmpty {
                        Text(s.caption)
                            .textStyle(.small, color: theme.colors.textDim)
                            .lineLimit(1)
                    }
                    Text("\(Format.dateTime(s.submittedAt)) · \(s.submissionVotes.count) \(s.submissionVotes.count == 1 ? "vote" : "votes")")
                        .textStyle(.caption, color: theme.colors.textFaint)
                }
                Spacer(minLength: Spacing.two)
                StatusChip(submissionStatus: s.status)
            }
        }
    }

    private func load() async {
        do {
            async let subsReq = SubmissionService.listChallengeSubmissions(challengeId)
            async let detailReq = ChallengeService.getDetail(
                challengeId: challengeId, myUserId: myId ?? ""
            )
            let (subs, detail) = try await (subsReq, detailReq)
            submissions = subs
            creatorId = detail.challenge.creatorId
            error = nil
        } catch {
            self.error = Format.errorMessage(error)
        }
        isLoading = false
    }
}
