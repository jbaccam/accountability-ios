import SwiftUI

/// Friends, requests, and people search. Port of (tabs)/friends.tsx, reorganized
/// behind a SegmentedControl per the iOS screen notes.
struct FriendsView: View {
    @Environment(\.theme) private var theme

    enum Tab: Hashable { case friends, requests, search }

    @State private var tab: Tab = .friends

    @State private var friends: [Friend] = []
    @State private var requests: [FriendRequest] = []

    @State private var query = ""
    @State private var results: [UserSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    @State private var busyId: String?
    @State private var removeConfig: ConfirmDialogConfig?
    @State private var toast: String?

    private var incoming: [FriendRequest] { requests.filter { $0.direction == .incoming } }
    private var outgoing: [FriendRequest] { requests.filter { $0.direction == .outgoing } }

    var body: some View {
        Screen(title: "Friends") {
            SegmentedControl(
                selection: $tab,
                options: [.friends, .requests, .search],
                label: tabLabel
            )

            switch tab {
            case .friends: friendsTab
            case .requests: requestsTab
            case .search: searchTab
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .confirmDialog($removeConfig)
        .task { await load() }
        .refreshable { await load() }
    }

    private func tabLabel(_ t: Tab) -> String {
        switch t {
        case .friends: return friends.isEmpty ? "Friends" : "Friends · \(friends.count)"
        case .requests: return incoming.isEmpty ? "Requests" : "Requests · \(incoming.count)"
        case .search: return "Search"
        }
    }

    // MARK: - Friends tab

    @ViewBuilder private var friendsTab: some View {
        if friends.isEmpty {
            EmptyState(
                icon: "person.2",
                title: "No friends yet",
                message: "Search by name to send a request. Friends make challenges stick — find your crew."
            )
        } else {
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                        personRow(name: friend.displayName, url: friend.avatarUrl, divider: index > 0) {
                            Button {
                                askRemove(friend)
                            } label: {
                                Image(systemName: "person.badge.minus")
                                    .font(.system(size: 20))
                                    .foregroundStyle(theme.colors.textFaint)
                            }
                            .buttonStyle(.plain)
                            .disabled(busyId == friend.friendId)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Requests tab

    @ViewBuilder private var requestsTab: some View {
        if incoming.isEmpty && outgoing.isEmpty {
            EmptyState(
                icon: "tray",
                title: "No requests",
                message: "Friend requests you send or receive show up here."
            )
        } else {
            if !incoming.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.two) {
                    sectionLabel("Incoming · \(incoming.count)")
                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(incoming.enumerated()), id: \.element.id) { index, req in
                                personRow(name: req.displayName, url: req.avatarUrl, divider: index > 0) {
                                    HStack(spacing: Spacing.two) {
                                        AppButton(
                                            "Decline",
                                            variant: .secondary,
                                            size: .sm,
                                            fullWidth: false,
                                            isLoading: busyId == req.otherId,
                                            isDisabled: busyId != nil
                                        ) { respondRequest(req.otherId, accept: false) }
                                        AppButton(
                                            "Accept",
                                            size: .sm,
                                            fullWidth: false,
                                            isLoading: busyId == req.otherId,
                                            isDisabled: busyId != nil
                                        ) { respondRequest(req.otherId, accept: true, done: "Friend added.") }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if !outgoing.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.two) {
                    sectionLabel("Pending · \(outgoing.count)")
                    Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(outgoing.enumerated()), id: \.element.id) { index, req in
                                personRow(name: req.displayName, url: req.avatarUrl, divider: index > 0) {
                                    tag("Requested")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search tab

    @ViewBuilder private var searchTab: some View {
        AppTextField(
            label: "",
            text: $query,
            placeholder: "Find people by name",
            icon: "magnifyingglass",
            autocapitalization: .never,
            submitLabel: .search,
            onSubmit: { runSearch(query) }
        )
        .onChange(of: query) { _, newValue in
            scheduleSearch(newValue)
        }

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            Text("Search by name to find people and send requests.")
                .textStyle(.small, color: theme.colors.textDim)
        } else if isSearching && results.isEmpty {
            LoadingState().frame(height: 80)
        } else if results.isEmpty {
            Card {
                Text("No one matches \u{201C}\(trimmed)\u{201D}.")
                    .textStyle(.small, color: theme.colors.textDim)
            }
        } else {
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, r in
                        personRow(name: r.displayName, url: r.avatarUrl, divider: index > 0) {
                            searchAction(r)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func searchAction(_ r: UserSearchResult) -> some View {
        switch r.relationship {
        case .none:
            AppButton(
                "Add",
                size: .sm,
                icon: "person.badge.plus",
                fullWidth: false,
                isLoading: busyId == r.userId,
                isDisabled: busyId != nil
            ) { sendRequest(r.userId) }
        case .outgoing:
            tag("Requested")
        case .incoming:
            AppButton(
                "Accept",
                size: .sm,
                fullWidth: false,
                isLoading: busyId == r.userId,
                isDisabled: busyId != nil
            ) { respondRequest(r.userId, accept: true, done: "Friend added.") }
        case .friends:
            tag("Friends", tone: .success)
        }
    }

    // MARK: - Row helpers

    private func personRow<Trailing: View>(
        name: String,
        url: String?,
        divider: Bool,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(spacing: 0) {
            if divider {
                Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
            }
            HStack(spacing: Spacing.three) {
                Avatar(name: name, url: url, size: 40)
                Text(name).textStyle(.bodyStrong, color: theme.colors.text)
                    .lineLimit(1)
                Spacer(minLength: Spacing.two)
                trailing()
            }
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.two + 2)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).textStyle(.label, color: theme.colors.textFaint)
    }

    private func tag(_ label: String, tone: StatusKind = .neutral) -> some View {
        let fg = tone == .success ? theme.colors.success : theme.colors.textFaint
        let bg = tone == .success ? theme.colors.successSoft : theme.colors.surfaceHigh
        return Text(label)
            .textStyle(.small, color: fg)
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.one + 2)
            .background(bg)
            .clipShape(Capsule())
    }

    // MARK: - Data + actions

    private func load() async {
        do {
            async let friendsReq = FriendService.listFriends()
            async let requestsReq = FriendService.listFriendRequests()
            let (f, r) = try await (friendsReq, requestsReq)
            friends = f
            requests = r
        } catch {
            toast = Format.errorMessage(error)
        }
    }

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(320))
            if Task.isCancelled { return }
            await performSearch(trimmed)
        }
    }

    private func runSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchTask = Task { await performSearch(trimmed) }
    }

    private func performSearch(_ query: String) async {
        do {
            let found = try await FriendService.searchUsers(query)
            if !Task.isCancelled { results = found }
        } catch {
            toast = Format.errorMessage(error)
        }
        if !Task.isCancelled { isSearching = false }
    }

    private func sendRequest(_ id: String) {
        runAction(id, done: "Request sent.") {
            try await FriendService.sendFriendRequest(addresseeId: id)
        }
    }

    private func respondRequest(_ id: String, accept: Bool, done: String? = nil) {
        runAction(id, done: done) {
            try await FriendService.respondFriendRequest(requesterId: id, accept: accept)
        }
    }

    private func askRemove(_ friend: Friend) {
        removeConfig = ConfirmDialogConfig(
            title: "Remove friend?",
            message: "You'll no longer see \(friend.displayName) in your friends. You can add them again later.",
            confirmLabel: "Remove",
            destructive: true,
            onConfirm: {
                runAction(friend.friendId) {
                    try await FriendService.removeFriend(otherId: friend.friendId)
                }
            }
        )
    }

    private func runAction(_ id: String, done: String? = nil, _ fn: @escaping () async throws -> Void) {
        guard busyId == nil else { return }
        busyId = id
        Task {
            defer { busyId = nil }
            do {
                try await fn()
                await load()
                let trimmed = query.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { await performSearch(trimmed) }
                if let done { toast = done }
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
