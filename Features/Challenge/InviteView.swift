import SwiftUI

/// Invite friends into a challenge. Port of challenge/[id]/invite.tsx, reshaped
/// per the iOS notes: multi-select friend rows + a single batch invite, plus the
/// shareable invite code with a copy button. Invitees commit only on accept.
struct InviteView: View {
    @Environment(\.theme) private var theme

    let challengeId: String

    @State private var friends: [Friend] = []
    @State private var inviteCode: String?
    @State private var selected: Set<String> = []
    @State private var alreadyInvited: Set<String> = []
    @State private var isLoading = true
    @State private var isInviting = false
    @State private var error: String?
    @State private var toast: String?

    private var selectableSelected: [String] {
        selected.filter { !alreadyInvited.contains($0) }
    }

    var body: some View {
        Screen(title: "Invite friends") {
            Text("Pick friends to invite into this challenge. They only commit their stake once they accept — nobody is added without confirming.")
                .textStyle(.small, color: theme.colors.textDim)

            if let inviteCode {
                inviteCodeCard(inviteCode)
            }

            if let error {
                Text(error).textStyle(.small, color: theme.colors.danger)
            }

            if isLoading && friends.isEmpty {
                LoadingState().frame(height: 200)
            } else if friends.isEmpty {
                EmptyState(
                    icon: "person.2",
                    title: "No friends yet",
                    message: "Add friends from the Friends tab first, then invite them straight into your challenges. You can still share the invite code above."
                )
            } else {
                friendsList
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .safeAreaInset(edge: .bottom) {
            if !selectableSelected.isEmpty {
                inviteBar
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Invite code

    private func inviteCodeCard(_ code: String) -> some View {
        Card(tone: .flat) {
            HStack(alignment: .center, spacing: Spacing.two) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite code").textStyle(.label, color: theme.colors.textFaint)
                    Text(code)
                        .textStyle(.h3, color: theme.colors.text)
                        .tracking(4)
                        .monospacedDigit()
                }
                Spacer(minLength: Spacing.two)
                AppButton("Copy", variant: .secondary, size: .sm, icon: "doc.on.doc", fullWidth: false) {
                    UIPasteboard.general.string = code
                    toast = "Invite code copied."
                }
            }
        }
    }

    // MARK: - Friends list

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Your friends · \(friends.count)").textStyle(.label, color: theme.colors.textFaint)
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                        friendRow(friend, divider: index > 0)
                    }
                }
            }
        }
    }

    private func friendRow(_ friend: Friend, divider: Bool) -> some View {
        let invited = alreadyInvited.contains(friend.friendId)
        let isSelected = selected.contains(friend.friendId)
        return VStack(spacing: 0) {
            if divider {
                Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
            }
            Button {
                guard !invited else { return }
                if isSelected { selected.remove(friend.friendId) }
                else { selected.insert(friend.friendId) }
            } label: {
                HStack(spacing: Spacing.three) {
                    Avatar(name: friend.displayName, url: friend.avatarUrl)
                    Text(friend.displayName)
                        .textStyle(.bodyStrong, color: theme.colors.text)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.two)
                    if invited {
                        StatusChip(text: "Invited", kind: .success)
                    } else {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.textFaint)
                    }
                }
                .padding(.horizontal, Spacing.three)
                .padding(.vertical, Spacing.two + 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(invited)
        }
    }

    // MARK: - Invite bar

    private var inviteBar: some View {
        let count = selectableSelected.count
        return AppButton(
            "Invite \(count) \(count == 1 ? "friend" : "friends")",
            icon: "person.badge.plus",
            isLoading: isInviting,
            isDisabled: isInviting,
            action: invite
        )
        .padding(Spacing.three)
        .background(.ultraThinMaterial)
    }

    // MARK: - Data + actions

    private func load() async {
        do {
            async let friendsReq = FriendService.listFriends()
            async let detailReq = ChallengeService.getDetail(challengeId: challengeId, myUserId: "")
            friends = try await friendsReq
            // The invite code is a nice-to-have; don't fail the screen if it errors.
            if let detail = try? await detailReq {
                inviteCode = detail.challenge.inviteCode
            }
            error = nil
        } catch {
            self.error = Format.errorMessage(error)
            friends = []
        }
        isLoading = false
    }

    private func invite() {
        let ids = selectableSelected
        guard !ids.isEmpty, !isInviting else { return }
        isInviting = true
        Task {
            defer { isInviting = false }
            do {
                let sent = try await ChallengeService.invite(challengeId: challengeId, inviteeIds: ids)
                alreadyInvited.formUnion(ids)
                selected.removeAll()
                toast = sent > 0
                    ? "Invited \(sent) \(sent == 1 ? "friend" : "friends")."
                    : "Those friends are already in."
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
