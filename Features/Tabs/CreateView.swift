import SwiftUI

/// New-challenge form. Port of (tabs)/create.tsx. Produces a CreateChallengeInput
/// and, on success, pushes the new challenge's detail screen.
struct CreateView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    // Basics
    @State private var title = ""
    @State private var details = ""
    @State private var entryFeeText = "25"

    // Schedule
    @State private var frequency: ChallengeFrequency = .daily
    @State private var customDaysText = "3"

    @State private var startAt: Date = Self.midnight(daysFromToday: 1)
    @State private var hasEndDate = false
    @State private var endAt: Date = Self.midnight(daysFromToday: 31)

    // Deadline (end of period vs. fixed clock time)
    @State private var useDeadlineTime = false
    @State private var deadlineTime: Date = Self.time(hour: 21, minute: 0)

    @State private var graceMinutesText = "0"

    // Proof
    @State private var requiresCaption = true
    @State private var requiresLocation = false

    // Review + payout
    @State private var reviewMethod: ReviewMethod = .majority
    @State private var payoutRule: PayoutRule = .winnerTakesAll

    @State private var isSubmitting = false
    @State private var error: String?

    private var fee: Double { Format.parseMoney(entryFeeText) }
    private var balance: Double { session.profile?.simulatedBalance ?? 0 }
    private var feeOver: Bool { fee > balance }

    private var customDays: Int { Int(customDaysText) ?? 0 }
    private var customDaysInvalid: Bool {
        frequency == .custom && (customDays < 2 || customDays > 90)
    }

    private var canSubmit: Bool {
        !isSubmitting
            && !title.trimmingCharacters(in: .whitespaces).isEmpty
            && fee >= 0
            && !feeOver
            && !customDaysInvalid
            && (!hasEndDate || endAt > startAt)
    }

    var body: some View {
        Screen(title: "New challenge") {
            basicsSection
            scheduleSection
            proofSection
            reviewSection
            payoutSection

            Divider().overlay(theme.colors.border)

            Text(Copy.trustDisclaimer).textStyle(.small, color: theme.colors.textFaint)
            Text(Copy.simulatedBalanceNote).textStyle(.small, color: theme.colors.textFaint)

            if let error {
                Text(error).textStyle(.small, color: theme.colors.danger)
            }

            AppButton(
                "Create & commit \(Format.money(fee))",
                isLoading: isSubmitting,
                isDisabled: !canSubmit,
                action: submit
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Basics

    private var basicsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.three) {
            sectionTitle("Basics")
            AppTextField(label: "Title", text: $title, placeholder: "Gym every day")
            AppTextField(
                label: "Rules / what counts",
                text: $details,
                placeholder: "What counts as a valid check-in?"
            )
            AppTextField(
                label: "Entry stake",
                text: $entryFeeText,
                placeholder: "25",
                helper: feeOver ? nil : "Simulated money — your balance: \(Format.money(balance)).",
                error: feeOver ? "Exceeds your simulated balance of \(Format.money(balance))." : nil,
                icon: "dollarsign",
                keyboard: .decimalPad
            )
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.three) {
            sectionTitle("Schedule")

            SegmentedControl(
                selection: $frequency,
                options: ChallengeFrequency.allCases,
                label: { $0.pickerLabel }
            )

            if frequency == .custom {
                AppTextField(
                    label: "Every N days",
                    text: $customDaysText,
                    placeholder: "3",
                    helper: customDaysInvalid ? nil : "One check-in every \(customDays) days.",
                    error: customDaysInvalid ? "Between 2 and 90 days." : nil,
                    keyboard: .numberPad
                )
            }

            DatePicker(
                "Starts",
                selection: $startAt,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .tint(theme.colors.accent)
            .textStyle(.bodyStrong, color: theme.colors.text)

            ToggleRow(
                title: "Has an end date",
                subtitle: hasEndDate ? nil : "Off = last one standing.",
                isOn: $hasEndDate
            )
            if hasEndDate {
                DatePicker(
                    "Ends",
                    selection: $endAt,
                    in: startAt...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .tint(theme.colors.accent)
                .textStyle(.bodyStrong, color: theme.colors.text)
            }

            ToggleRow(
                title: "Fixed daily deadline",
                subtitle: useDeadlineTime ? nil : "Off = end of the period.",
                isOn: $useDeadlineTime
            )
            if useDeadlineTime {
                DatePicker(
                    "Deadline",
                    selection: $deadlineTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
                .tint(theme.colors.accent)
                .textStyle(.bodyStrong, color: theme.colors.text)
            }

            AppTextField(
                label: "Grace period (minutes)",
                text: $graceMinutesText,
                placeholder: "0",
                helper: "Extra time after the deadline before a miss counts.",
                keyboard: .numberPad
            )
        }
    }

    // MARK: - Proof

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: Spacing.three) {
            sectionTitle("Proof")
            Card {
                VStack(alignment: .leading, spacing: Spacing.three) {
                    Text("Photo + timestamp are always required.")
                        .textStyle(.small, color: theme.colors.textDim)
                    ToggleRow(title: "Require a caption", isOn: $requiresCaption)
                    ToggleRow(title: "Require location", isOn: $requiresLocation)
                }
            }
        }
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.three) {
            sectionTitle("Review")
            VStack(spacing: Spacing.two) {
                ForEach(Self.reviewOptions, id: \.value) { option in
                    reviewOptionRow(option)
                }
            }
            Text("If everyone fails a period, the challenge pauses and the creator chooses a refund or a tie-breaker round.")
                .textStyle(.small, color: theme.colors.textFaint)
        }
    }

    private func reviewOptionRow(_ option: ReviewOption) -> some View {
        let active = option.value == reviewMethod
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { reviewMethod = option.value }
        } label: {
            HStack(alignment: .top, spacing: Spacing.three) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            active ? theme.colors.accent : theme.colors.borderStrong,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if active {
                        Circle().fill(theme.colors.accent).frame(width: 10, height: 10)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .textStyle(.bodyStrong, color: active ? theme.colors.accent : theme.colors.text)
                    Text(option.description)
                        .textStyle(.small, color: theme.colors.textDim)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.three)
            .background(active ? theme.colors.accentSoft : theme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(active ? theme.colors.accent : theme.colors.border, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(PressScaleStyle(scale: 0.99))
    }

    // MARK: - Payout

    private var payoutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.three) {
            sectionTitle("Payout")
            SegmentedControl(
                selection: $payoutRule,
                options: [.winnerTakesAll, .splitAmongWinners],
                label: { $0.pickerLabel }
            )
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text).textStyle(.title, color: theme.colors.text)
    }

    private static func midnight(daysFromToday: Int) -> Date {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: daysFromToday, to: base) ?? base
    }

    private static func time(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    private var deadlineString: String? {
        guard useDeadlineTime else { return nil }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: deadlineTime)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }

    // MARK: - Submit

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        error = nil
        Task {
            defer { isSubmitting = false }
            do {
                let input = CreateChallengeInput(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: details.trimmingCharacters(in: .whitespacesAndNewlines),
                    entryFee: fee,
                    frequency: frequency,
                    periodDays: frequency == .custom ? customDays : nil,
                    startAt: startAt,
                    endAt: hasEndDate ? endAt : nil,
                    timezone: Format.deviceTimezone(),
                    submissionDeadlineTime: deadlineString,
                    gracePeriodMinutes: max(0, Int(graceMinutesText) ?? 0),
                    requiresCaption: requiresCaption,
                    requiresLocation: requiresLocation,
                    reviewMethod: reviewMethod,
                    payoutRule: payoutRule
                )
                let created = try await ChallengeService.createChallenge(input)
                await session.refreshProfile()
                nav.push(.challengeDetail(challengeId: created.id))
            } catch {
                self.error = Format.errorMessage(error)
            }
        }
    }

    // MARK: - Review options

    struct ReviewOption {
        let value: ReviewMethod
        let label: String
        let description: String
    }

    private static let reviewOptions: [ReviewOption] = [
        ReviewOption(
            value: .majority,
            label: "Majority vote",
            description: "Friends approve or reject each proof; the creator breaks ties."
        ),
        ReviewOption(
            value: .creatorDecides,
            label: "Creator decides",
            description: "Only the creator approves or rejects proofs."
        ),
        ReviewOption(
            value: .unanimous,
            label: "Unanimous",
            description: "Every other player must approve for a proof to pass."
        ),
        ReviewOption(
            value: .autoApprove,
            label: "Auto-approve",
            description: "Proofs pass automatically unless someone rejects them."
        ),
    ]
}

private extension ChallengeFrequency {
    var pickerLabel: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
}

private extension PayoutRule {
    var pickerLabel: String {
        switch self {
        case .winnerTakesAll: return "Winner takes all"
        case .splitAmongWinners: return "Split winners"
        }
    }
}
