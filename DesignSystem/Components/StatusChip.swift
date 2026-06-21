import SwiftUI

enum StatusKind {
    case neutral, success, warning, danger, info

    func fill(_ c: AppColors) -> Color {
        switch self {
        case .neutral: return c.surfaceHigh
        case .success: return c.successSoft
        case .warning: return c.warningSoft
        case .danger: return c.dangerSoft
        case .info: return c.infoSoft
        }
    }

    func dot(_ c: AppColors) -> Color {
        switch self {
        case .neutral: return c.textFaint
        case .success: return c.success
        case .warning: return c.warning
        case .danger: return c.danger
        case .info: return c.info
        }
    }
}

/// Tinted bg + colored dot + high-contrast primary-text label. Color-blind safe
/// (never relies on color alone). Port of components/ui/status-chip.
struct StatusChip: View {
    @Environment(\.theme) private var theme
    let text: String
    var kind: StatusKind = .neutral

    var body: some View {
        HStack(spacing: Spacing.two) {
            Circle()
                .fill(kind.dot(theme.colors))
                .frame(width: 6, height: 6)
            Text(text).textStyle(.label, color: theme.colors.text)
        }
        .padding(.horizontal, Spacing.two)
        .padding(.vertical, Spacing.one)
        .background(kind.fill(theme.colors))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(text)")
    }
}

extension StatusChip {
    /// Map a challenge status onto chip text + kind.
    init(challengeStatus: ChallengeStatus) {
        switch challengeStatus {
        case .draft: self.init(text: "Draft", kind: .neutral)
        case .active: self.init(text: "Active", kind: .success)
        case .completed: self.init(text: "Completed", kind: .info)
        case .cancelled: self.init(text: "Cancelled", kind: .neutral)
        case .needsResolution: self.init(text: "Needs resolution", kind: .warning)
        }
    }

    /// Map a submission status onto chip text + kind.
    init(submissionStatus: SubmissionStatus) {
        switch submissionStatus {
        case .pending: self.init(text: "Pending", kind: .warning)
        case .approved: self.init(text: "Approved", kind: .success)
        case .rejected: self.init(text: "Rejected", kind: .danger)
        case .disputed: self.init(text: "Disputed", kind: .danger)
        case .needsResolution: self.init(text: "Needs resolution", kind: .warning)
        }
    }

    /// Map a participant status onto chip text + kind. "Still in" leads — progress
    /// is the hero (see PRODUCT.md).
    init(participantStatus: ParticipantStatus) {
        switch participantStatus {
        case .invited: self.init(text: "Invited", kind: .neutral)
        case .active: self.init(text: "Still in", kind: .success)
        case .eliminated: self.init(text: "Out", kind: .danger)
        case .winner: self.init(text: "Winner", kind: .success)
        case .refunded: self.init(text: "Refunded", kind: .info)
        }
    }
}
