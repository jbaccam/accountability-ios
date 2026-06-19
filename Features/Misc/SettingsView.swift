import SwiftUI

/// Settings: account info, legal/about, and the danger zone (sign out, delete).
/// Port of settings.tsx, reshaped per the iOS notes — display name is edited in
/// Profile, so it's read-only here; password change and theme picker are dropped
/// in favor of system-managed appearance. Pushed inside a NavTab stack.
struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(\.openURL) private var openURL

    @State private var confirm: ConfirmDialogConfig?
    @State private var toast: String?
    @State private var isDeleting = false

    // TODO(real-payments): point these at the real marketing/legal site once it's live.
    private let termsURL = URL(string: "https://accountability.app/terms")!
    private let privacyURL = URL(string: "https://accountability.app/privacy")!
    private let complianceURL = URL(string: "https://accountability.app/compliance")!

    private var profile: Profile? { session.profile }
    private var email: String? { session.session?.user.email }

    var body: some View {
        Screen(title: "Settings") {
            accountSection
            aboutSection
            dangerSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .confirmDialog($confirm)
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Account").textStyle(.label, color: theme.colors.textFaint)
            Card {
                VStack(alignment: .leading, spacing: Spacing.three) {
                    InfoRow(label: "Display name", value: profile?.displayName ?? "—")
                    Text("Edit your name from the Profile tab.")
                        .textStyle(.small, color: theme.colors.textFaint)
                    if let email {
                        divider
                        InfoRow(label: "Email", value: email)
                    }
                    divider
                    InfoRow(
                        label: Copy.simulatedBalanceLabel,
                        value: Format.money(profile?.simulatedBalance ?? 0)
                    )
                }
            }
        }
    }

    // MARK: - About / Legal

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("About").textStyle(.label, color: theme.colors.textFaint)
            Card(padding: 0) {
                VStack(spacing: 0) {
                    linkRow("Terms of service", icon: "doc.text", url: termsURL, divider: false)
                    linkRow("Privacy policy", icon: "lock.shield", url: privacyURL, divider: true)
                    linkRow("Compliance", icon: "checkmark.seal", url: complianceURL, divider: true)
                }
            }

            Card(tone: .flat) {
                VStack(alignment: .leading, spacing: Spacing.two) {
                    Text("Playing fair").textStyle(.bodyStrong, color: theme.colors.text)
                    Text(Copy.trustDisclaimer)
                        .textStyle(.small, color: theme.colors.textDim)
                    divider
                    Text(Copy.simulatedBalanceNote)
                        .textStyle(.small, color: theme.colors.textFaint)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.one) {
                Text("Appearance follows your system light or dark setting.")
                    .textStyle(.small, color: theme.colors.textFaint)
                Text("Accountability v\(appVersion)")
                    .textStyle(.caption, color: theme.colors.textFaint)
            }
        }
    }

    private func linkRow(_ label: String, icon: String, url: URL, divider: Bool) -> some View {
        Button { openURL(url) } label: {
            VStack(spacing: 0) {
                if divider {
                    Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
                }
                HStack(spacing: Spacing.three) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(theme.colors.text)
                        .frame(width: 24)
                    Text(label).textStyle(.bodyStrong, color: theme.colors.text)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.colors.textFaint)
                }
                .padding(Spacing.three)
            }
        }
        .buttonStyle(PressScaleStyle(scale: 0.99))
    }

    // MARK: - Danger zone

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            Text("Danger zone").textStyle(.label, color: theme.colors.textFaint)

            AppButton("Sign out", variant: .secondary) {
                confirm = ConfirmDialogConfig(
                    title: "Sign out?",
                    message: "You'll need to sign back in to check in on your challenges.",
                    confirmLabel: "Sign out",
                    destructive: true,
                    onConfirm: signOut
                )
            }

            AppButton(
                "Delete account",
                variant: .danger,
                isLoading: isDeleting,
                isDisabled: isDeleting
            ) {
                confirm = ConfirmDialogConfig(
                    title: "Delete account?",
                    message: "This permanently deletes your account and all your data — profile, challenges you created, check-ins, and history. This cannot be undone.",
                    confirmLabel: "Delete forever",
                    destructive: true,
                    onConfirm: deleteAccount
                )
            }

            Text("Deleting your account permanently removes your profile, challenges, check-ins, and history.")
                .textStyle(.caption, color: theme.colors.textFaint)
        }
    }

    // MARK: - Pieces

    private var divider: some View {
        Rectangle().fill(theme.colors.border).frame(height: HairlineWidth)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Actions

    private func signOut() {
        Task { await session.signOut() }
        // SessionStore clears the session; RootView swaps back to the auth flow.
    }

    private func deleteAccount() {
        guard !isDeleting else { return }
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                try await ProfileService.deleteMyAccount()
                // The service signs out, which clears session state and returns
                // to the auth flow — nothing more to do here.
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
