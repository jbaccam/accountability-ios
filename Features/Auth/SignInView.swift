import SwiftUI

/// Sign-in screen. Port of (auth)/sign-in.tsx. The auth flow owns its own
/// NavigationStack; we push further destinations with NavigationLink values.
struct SignInView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isLoading = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        AuthScreen(title: "Welcome back", subtitle: "Sign in to your challenges.") {
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
                error: error,
                icon: "lock",
                isSecure: true,
                submitLabel: .go,
                onSubmit: submit
            )
            .onChange(of: password) { error = nil }

            VStack(spacing: Spacing.two) {
                AppButton(
                    "Sign in",
                    isLoading: isLoading,
                    isDisabled: isLoading || !canSubmit,
                    action: submit
                )

                NavigationLink(value: AuthRoute.forgotPassword) {
                    Text("Forgot password?")
                        .textStyle(.bodyStrong, color: theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)

                NavigationLink(value: AuthRoute.signUp) {
                    Text("New here? Create an account")
                        .textStyle(.bodyStrong, color: theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        isLoading = true
        error = nil
        Task {
            defer { isLoading = false }
            do {
                try await session.signIn(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                // On success, SessionStore flips isSignedIn and RootView swaps
                // to the main tabs — nothing more to do here.
            } catch {
                self.error = friendlyAuthError(Format.errorMessage(error))
            }
        }
    }

    private func friendlyAuthError(_ message: String) -> String {
        if message.contains("Invalid login credentials") {
            return "Wrong email or password. Double-check and try again."
        }
        if message.contains("Email not confirmed") {
            return "Your email isn't confirmed yet. Tap the link in the email we sent you."
        }
        return message
    }
}
