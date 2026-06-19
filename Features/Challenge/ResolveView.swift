import SwiftUI

/// Creator-only deadlock resolution. Port of challenge/[id]/resolve.tsx. When
/// everyone fails the same round nobody is eliminated; the creator either
/// refunds the group or starts a tie-breaker. This is final.
struct ResolveView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    let challengeId: String

    @State private var resolution: ResolutionType = .refund
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var toast: String?

    private static let options: [ResolutionType] = [.refund, .tiebreaker]

    var body: some View {
        Screen(title: "Resolve") {
            Card(tone: .warning) {
                VStack(alignment: .leading, spacing: Spacing.two) {
                    Text("Everyone failed the same round")
                        .textStyle(.title, color: theme.colors.warning)
                    Text("Nobody was eliminated. As the creator, you decide how the group moves on. Talk it over with your friends first — this is final.")
                        .textStyle(.small, color: theme.colors.textDim)
                }
            }

            SegmentedControl(
                selection: $resolution,
                options: Self.options,
                label: optionLabel
            )

            explanationCard

            AppTextField(
                label: "Note to the group (optional)",
                text: $notes,
                placeholder: "Why you chose this"
            )

            AppButton(
                confirmLabel,
                icon: resolution == .refund ? "arrow.uturn.backward" : "flag.checkered",
                isLoading: isSubmitting,
                isDisabled: isSubmitting,
                action: submit
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }

    @ViewBuilder
    private var explanationCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                switch resolution {
                case .refund:
                    Text("Refund stakes").textStyle(.title, color: theme.colors.text)
                    Text("Ends the challenge. Every participant gets their simulated stake back.")
                        .textStyle(.small, color: theme.colors.textDim)
                case .tiebreaker:
                    Text("Tie-breaker round").textStyle(.title, color: theme.colors.text)
                    Text("Forgives the missed round for everyone and continues the challenge from the current period. Same stakes, same rules.")
                        .textStyle(.small, color: theme.colors.textDim)
                case .manualWinner:
                    Text("Choose a winner").textStyle(.title, color: theme.colors.text)
                    Text("Ends the challenge with a winner you pick.")
                        .textStyle(.small, color: theme.colors.textDim)
                }
            }
        }
    }

    private func optionLabel(_ type: ResolutionType) -> String {
        switch type {
        case .refund: return "Refund everyone"
        case .tiebreaker: return "Tie-breaker"
        case .manualWinner: return "Pick winner"
        }
    }

    private var confirmLabel: String {
        switch resolution {
        case .refund: return "Refund everyone"
        case .tiebreaker: return "Start tie-breaker"
        case .manualWinner: return "Choose winner"
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                _ = try await ChallengeService.resolve(
                    challengeId: challengeId,
                    resolution: resolution,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                await session.refreshProfile()
                nav.pop()
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
