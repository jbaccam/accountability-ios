import SwiftUI

/// Reset-password request screen. Sends a recovery email, then shows a
/// confirmation state. Port of (auth)/forgot-password.tsx.
struct ForgotPasswordView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var sent = false
    @State private var error: String?
    @State private var isLoading = false

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        Group {
            if sent {
                sentState
            } else {
                form
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        AuthScreen(
            title: "Reset password",
            subtitle: "Enter your account email and we'll send you a reset link."
        ) {
            AppTextField(
                label: "Email",
                text: $email,
                error: error,
                icon: "envelope",
                keyboard: .emailAddress,
                autocapitalization: .never,
                submitLabel: .send,
                onSubmit: submit
            )
            .onChange(of: email) { error = nil }

            VStack(spacing: Spacing.two) {
                AppButton(
                    "Send reset link",
                    isLoading: isLoading,
                    isDisabled: isLoading || trimmedEmail.isEmpty,
                    action: submit
                )
                AppButton("Back", variant: .ghost, size: .md) { dismiss() }
            }
        }
    }

    private var sentState: some View {
        AuthScreen(
            title: "Check your email",
            subtitle: "We sent a password reset link to\n\(trimmedEmail)"
        ) {
            Text("Open the link on this device to choose a new password.")
                .textStyle(.body, color: theme.colors.textDim)

            AppButton("Back to sign in", variant: .ghost, size: .md) { dismiss() }
        }
    }

    private func submit() {
        guard !trimmedEmail.isEmpty, !isLoading else { return }
        isLoading = true
        error = nil
        Task {
            defer { isLoading = false }
            do {
                try await session.sendPasswordReset(email: trimmedEmail)
                sent = true
            } catch {
                self.error = Format.errorMessage(error)
            }
        }
    }
}
