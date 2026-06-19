import SwiftUI

/// Profile: identity, simulated balance, a check-in activity grid, and recent
/// transactions. Port of (tabs)/profile.tsx. Consistency (streak/check-ins) is
/// the hero; the balance is a quiet detail.
struct ProfileView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    @State private var transactions: [SimulatedTransaction] = []
    @State private var activity: CheckinActivity?
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var isSavingName = false
    @State private var isUploadingAvatar = false
    @State private var nameError: String?
    @State private var toast: String?

    private var userId: String? { session.userId }
    private var profile: Profile? { session.profile }

    private var nameAvailableAt: Date? {
        profile.flatMap { ProfileService.nameChangeAvailableAt($0) }
    }
    private var canEditName: Bool { nameAvailableAt == nil }

    private var settingsButton: some View {
        Button { nav.push(.settings) } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 20))
                .foregroundStyle(theme.colors.text)
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        Screen {
            header
            identityCard
            balanceCard
            statsCard
            activitySection
            activityList
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { settingsButton } }
        .toast($toast)
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Header

    private var header: some View {
        Text("Profile").textStyle(.h1, color: theme.colors.text)
    }

    // MARK: - Identity

    private var identityCard: some View {
        Card {
            HStack(spacing: Spacing.three) {
                ZStack(alignment: .bottomTrailing) {
                    Avatar(name: profile?.displayName ?? "?", url: profile?.avatarUrl, size: 64, isYou: true)
                    avatarBadge
                }
                VStack(alignment: .leading, spacing: Spacing.one) {
                    if editingName {
                        nameEditor
                    } else {
                        Text(profile?.displayName ?? "You").textStyle(.h2, color: theme.colors.text)
                            .lineLimit(1)
                        if let since = memberSince {
                            Text("Member since \(since)").textStyle(.small, color: theme.colors.textDim)
                        }
                        identityActions
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var avatarBadge: some View {
        PhotoPickerButton(onPick: uploadAvatar) {
            ZStack {
                Circle().fill(theme.colors.accent)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(theme.colors.surface, lineWidth: 2))
                if isUploadingAvatar {
                    ProgressView().tint(theme.colors.onAccent).scaleEffect(0.6)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.colors.onAccent)
                }
            }
        }
    }

    private var identityActions: some View {
        HStack(spacing: Spacing.three) {
            if canEditName {
                Button {
                    nameDraft = profile?.displayName ?? ""
                    nameError = nil
                    editingName = true
                } label: {
                    Text("Edit name").textStyle(.small, color: theme.colors.accent)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            } else if let next = nameAvailableAt {
                Text("Rename available \(Format.date(next))")
                    .textStyle(.small, color: theme.colors.textFaint)
            }

            if profile?.avatarUrl != nil {
                Button { removeAvatar() } label: {
                    Text("Remove photo").textStyle(.small, color: theme.colors.textFaint)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .disabled(isUploadingAvatar)
            }
        }
        .padding(.top, 2)
    }

    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            AppTextField(
                label: "",
                text: $nameDraft,
                placeholder: "Display name",
                error: nameError
            )
            HStack(spacing: Spacing.two) {
                AppButton(
                    "Cancel",
                    variant: .secondary,
                    size: .sm,
                    fullWidth: false,
                    isDisabled: isSavingName
                ) { editingName = false }
                AppButton(
                    "Save",
                    size: .sm,
                    fullWidth: false,
                    isLoading: isSavingName,
                    isDisabled: isSavingName || nameDraft.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: saveName
                )
            }
        }
    }

    private var memberSince: String? {
        guard let created = profile?.createdAt else { return nil }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: created)
    }

    // MARK: - Balance

    private var balanceCard: some View {
        Card {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Spacing.one) {
                    Text(Copy.simulatedBalanceLabel).textStyle(.label, color: theme.colors.textFaint)
                    Text(Format.money(profile?.simulatedBalance ?? 0))
                        .textStyle(.stat, color: theme.colors.text)
                    Text(Copy.simulatedBalanceNote).textStyle(.small, color: theme.colors.textFaint)
                }
                Spacer(minLength: Spacing.two)
                AppButton("Add", size: .sm, icon: "plus", fullWidth: false) {
                    nav.push(.deposit)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        let checkins = activity?.days.values.reduce(0, +) ?? 0
        let streak = activity.map { currentStreak($0.days) } ?? 0
        let payouts = transactions.filter { $0.type == .payoutReceived }.count
        return Card {
            HStack(spacing: 0) {
                stat("Check-ins", checkins)
                statDivider
                stat("Day streak", streak)
                statDivider
                stat("Payouts", payouts)
            }
        }
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").textStyle(.h2, color: theme.colors.text)
            Text(label).textStyle(.caption, color: theme.colors.textFaint)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle().fill(theme.colors.border).frame(width: HairlineWidth, height: 34)
    }

    // MARK: - Activity grid

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Check-in calendar").textStyle(.label, color: theme.colors.textFaint)
            Card {
                if let activity {
                    ActivityGrid(days: activity.days, now: activity.now)
                } else {
                    Text("Days with approved check-ins fill in here.")
                        .textStyle(.small, color: theme.colors.textDim)
                }
            }
        }
    }

    // MARK: - Transactions

    private var activityList: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Recent activity").textStyle(.label, color: theme.colors.textFaint)
            if transactions.isEmpty {
                Card {
                    Text("Nothing yet. Stakes, payouts, refunds, and top-ups show up here.")
                        .textStyle(.small, color: theme.colors.textDim)
                }
            } else {
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                            transactionRow(tx, divider: index > 0)
                        }
                    }
                }
            }
        }
    }

    private func transactionRow(_ tx: SimulatedTransaction, divider: Bool) -> some View {
        let meta = txMeta(tx.type)
        return VStack(spacing: 0) {
            if divider {
                Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meta.label).textStyle(.bodyStrong, color: theme.colors.text)
                    Text(Format.dateTime(tx.createdAt)).textStyle(.caption, color: theme.colors.textFaint)
                }
                Spacer(minLength: Spacing.two)
                Text("\(meta.sign)\(Format.money(tx.amount))")
                    .textStyle(.title, color: meta.color(theme.colors))
            }
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.two + 2)
        }
    }

    private struct TxMeta {
        let label: String
        let sign: String
        let tone: Tone
        enum Tone { case up, down, flat }
        func color(_ c: AppColors) -> Color {
            switch tone {
            case .up: return c.success
            case .down: return c.danger
            case .flat: return c.textDim
            }
        }
    }

    private func txMeta(_ type: TransactionType) -> TxMeta {
        switch type {
        case .deposit: return TxMeta(label: "Funds added", sign: "+", tone: .up)
        case .stakeReserved: return TxMeta(label: "Stake committed", sign: "-", tone: .down)
        case .stakeLost: return TxMeta(label: "Stake lost", sign: "", tone: .flat)
        case .payoutReceived: return TxMeta(label: "Payout received", sign: "+", tone: .up)
        case .refund: return TxMeta(label: "Refund", sign: "+", tone: .up)
        }
    }

    /// Consecutive days with a check-in, counting back from today (then yesterday).
    private func currentStreak(_ days: [String: Int]) -> Int {
        var cursor = Date()
        if days[Format.localDayKey(cursor)] == nil {
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while let count = days[Format.localDayKey(cursor)], count > 0 {
            streak += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    // MARK: - Data + actions

    private func load() async {
        await session.refreshProfile()
        do {
            async let txReq = ProfileService.listMyTransactions()
            if let userId {
                async let actReq = ProfileService.getMyCheckinActivity(userId: userId)
                let (txs, act) = try await (txReq, actReq)
                transactions = txs
                activity = act
            } else {
                transactions = try await txReq
            }
        } catch {
            toast = "Could not load profile: \(Format.errorMessage(error))"
        }
    }

    private func saveName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSavingName else { return }
        isSavingName = true
        nameError = nil
        Task {
            defer { isSavingName = false }
            do {
                _ = try await ProfileService.updateDisplayName(trimmed)
                await session.refreshProfile()
                editingName = false
                toast = "Name updated."
            } catch {
                nameError = Format.errorMessage(error)
            }
        }
    }

    private func uploadAvatar(_ data: Data) {
        guard let userId, !isUploadingAvatar else { return }
        isUploadingAvatar = true
        Task {
            defer { isUploadingAvatar = false }
            do {
                _ = try await ProfileService.uploadAvatar(userId: userId, jpeg: data)
                await session.refreshProfile()
                toast = "Profile photo updated."
            } catch {
                toast = "Could not update photo: \(Format.errorMessage(error))"
            }
        }
    }

    private func removeAvatar() {
        guard let userId, !isUploadingAvatar else { return }
        isUploadingAvatar = true
        Task {
            defer { isUploadingAvatar = false }
            do {
                try await ProfileService.removeAvatar(userId: userId)
                await session.refreshProfile()
            } catch {
                toast = "Could not remove photo: \(Format.errorMessage(error))"
            }
        }
    }
}

/// GitHub-style contribution grid — tasteful monochrome, accent opacity by count.
/// Shows the trailing weeks up to and including the current week.
private struct ActivityGrid: View {
    @Environment(\.theme) private var theme
    let days: [String: Int]
    let now: Date

    private let weeks = 18
    private let cell: CGFloat = 13
    private let gap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            HStack(alignment: .top, spacing: gap) {
                ForEach(columns, id: \.self) { column in
                    VStack(spacing: gap) {
                        ForEach(column, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(fill(for: day))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            legend
        }
    }

    private var legend: some View {
        HStack(spacing: gap) {
            Text("Less").textStyle(.caption, color: theme.colors.textFaint)
            ForEach([0, 1, 2, 4], id: \.self) { count in
                RoundedRectangle(cornerRadius: 3)
                    .fill(fillForCount(count))
                    .frame(width: cell, height: cell)
            }
            Text("More").textStyle(.caption, color: theme.colors.textFaint)
        }
    }

    /// Columns of dates, oldest week first; each column is Sun..Sat.
    private var columns: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        // Start of the current week (back to its weekday-1 boundary).
        let weekdayIndex = (cal.component(.weekday, from: today) - 1)
        guard let endOfRange = cal.date(byAdding: .day, value: 6 - weekdayIndex, to: today),
              let start = cal.date(byAdding: .day, value: -(weeks * 7 - 1), to: endOfRange)
        else { return [] }

        var result: [[Date?]] = []
        var cursor = start
        for _ in 0..<weeks {
            var column: [Date?] = []
            for _ in 0..<7 {
                column.append(cursor <= today ? cursor : nil)
                cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            }
            result.append(column)
        }
        return result
    }

    private func fill(for day: Date?) -> Color {
        guard let day else { return .clear }
        return fillForCount(days[Format.localDayKey(day)] ?? 0)
    }

    private func fillForCount(_ count: Int) -> Color {
        switch count {
        case 0: return theme.colors.track
        case 1: return theme.colors.accent.opacity(0.30)
        case 2: return theme.colors.accent.opacity(0.55)
        case 3: return theme.colors.accent.opacity(0.78)
        default: return theme.colors.accent
        }
    }
}
