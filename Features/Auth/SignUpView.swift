import SwiftUI

/// Sign-up screen — display name + email + password. On a successful sign-up
/// that still needs email confirmation, push the verify-email screen. Port of
/// (auth)/sign-up.tsx.
struct SignUpView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isLoading = false

    /// Set after a successful sign-up that needs confirmation; drives the push.
    /// Wrapped in an Identifiable box because `navigationDestination(item:)`
    /// requires Identifiable and a bare String is not.
    @State private var pendingVerification: PendingVerification?

    private var passwordTooShort: Bool { !password.isEmpty && password.count < 6 }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 6
    }

    var body: some View {
        AuthScreen(title: "Get started", subtitle: "A few seconds and you're in.") {
            AppTextField(
                label: "Display name",
                text: $displayName,
                icon: "person"
            )

            AppTextField(
                label: "Email",
                text: $email,
                icon: "envelope",
                keyboard: .emailAddress,
                autocapitalization: .never
            )
            .onChange(of: email) { error = nil }

            AppTextField(
                label: "Password",
                text: $password,
                helper: passwordTooShort ? nil : "At least 6 characters.",
                error: passwordTooShort ? "At least 6 characters." : error,
                icon: "lock",
                isSecure: true
            )

            VStack(spacing: Spacing.two) {
                AppButton(
                    "Create account",
                    isLoading: isLoading,
                    isDisabled: isLoading || !canSubmit,
                    action: submit
                )

                NavigationLink(value: AuthRoute.signIn) {
                    Text("Already have an account? Sign in")
                        .textStyle(.bodyStrong, color: theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
            }

            Text(Copy.trustDisclaimer)
                .textStyle(.small, color: theme.colors.textFaint)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $pendingVerification) { pending in
            VerifyEmailView(email: pending.email)
        }
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        isLoading = true
        error = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        Task {
            defer { isLoading = false }
            do {
                let signedInImmediately = try await session.signUp(
                    email: trimmedEmail,
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                // When false, a confirmation email is required — send them to
                // the verify screen. When true, RootView swaps to the tabs.
                if !signedInImmediately {
                    pendingVerification = PendingVerification(email: trimmedEmail)
                }
            } catch {
                self.error = Format.errorMessage(error)
            }
        }
    }
}

/// Identifiable box so a successful-but-unconfirmed sign-up can drive
/// `navigationDestination(item:)`.
private struct PendingVerification: Identifiable, Hashable {
    let email: String
    var id: String { email }
}
