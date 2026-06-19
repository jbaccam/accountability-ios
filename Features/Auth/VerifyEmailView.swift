import SwiftUI

/// Post-sign-up "check your email" screen. Port of (auth)/verify-email.tsx.
///
/// NOTE: the RN version also offered a "Resend email" button (with a 45s
/// cooldown) backed by `supabase.auth.resend(type: .signup)`. The shared
/// `SessionStore` API does not yet expose a resend method, so that action is
/// omitted here — see the summary for the requested shared-API addition.
struct VerifyEmailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let email: String

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

            AppButton("I've confirmed — sign in", variant: .ghost, size: .md) {
                dismiss()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var displayEmail: String {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your inbox" : trimmed
    }
}
