import SwiftUI

/// Post-sign-up "check your email" screen. Port of (auth)/verify-email.tsx,
/// including the resend action with a 45s cooldown.
struct VerifyEmailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    let email: String

    @State private var cooldown = 0
    @State private var isResending = false
    @State private var toast: String?

    init(email: String) {
        self.email = email
    }

    var body: some View {
        AuthScreen(
            title: "Check your email",
            subtitle: "We sent a confirmation link to\n\(displayEmail)"
        ) {
            Text("Open the link on this device and you'll be signed in automatically. If you confirm somewhere else, come back and sign in with your password.")
                .textStyle(.body, color: theme.colors.textDim)

            AppButton(
                cooldown > 0 ? "Resend in \(cooldown)s" : "Resend email",
                variant: .secondary,
                size: .md,
                isLoading: isResending,
                isDisabled: cooldown > 0 || email.isEmpty
            ) {
                Task { await resend() }
            }

            AppButton("I've confirmed — sign in", variant: .ghost, size: .md) {
                dismiss()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task(id: cooldown) {
            guard cooldown > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            cooldown -= 1
        }
    }

    private func resend() async {
        guard !isResending else { return }
        isResending = true
        defer { isResending = false }
        do {
            try await session.resendConfirmation(email: email)
            toast = "Sent — check your inbox"
            cooldown = 45
        } catch {
            toast = Format.errorMessage(error)
        }
    }

    private var displayEmail: String {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your inbox" : trimmed
    }
}
