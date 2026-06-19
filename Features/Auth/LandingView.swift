import SwiftUI

/// Auth landing — the first thing a signed-out user sees. Routes to sign-up /
/// sign-in. Port of (auth)/index.tsx.
struct LandingView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        AuthScreen(
            title: "Bet on yourself",
            subtitle: "Private challenges with friends. Everyone puts in, everyone proves it — the most consistent take it."
        ) {
            VStack(spacing: Spacing.two) {
                NavigationLink(value: AuthRoute.signUp) {
                    AppButtonLabel("Create account", variant: .primary)
                }
                .buttonStyle(.plain)

                NavigationLink(value: AuthRoute.signIn) {
                    AppButtonLabel("Sign in", variant: .secondary)
                }
                .buttonStyle(.plain)
            }

            Card(tone: .flat) {
                VStack(alignment: .leading, spacing: Spacing.one) {
                    Text("Before you start")
                        .textStyle(.label, color: theme.colors.accent)
                    Text(Copy.trustDisclaimer)
                        .textStyle(.small, color: theme.colors.textDim)
                        .padding(.top, Spacing.one)
                    Text(Copy.simulatedBalanceNote)
                        .textStyle(.small, color: theme.colors.textDim)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Renders an AppButton's pill appearance inside a NavigationLink. AppButton
/// owns a tap action, so for pure navigation we use a NavigationLink wrapping
/// this label, which matches the AppButton visual contract.
private struct AppButtonLabel: View {
    @Environment(\.theme) private var theme
    let title: String
    let variant: ButtonVariant

    init(_ title: String, variant: ButtonVariant) {
        self.title = title
        self.variant = variant
    }

    var body: some View {
        Text(title)
            .textStyle(.title, color: foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, Spacing.four)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.pill)
                    .stroke(strokeColor, lineWidth: HairlineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
    }

    private var foreground: Color {
        switch variant {
        case .primary: return theme.colors.onAccent
        case .secondary: return theme.colors.text
        case .ghost: return theme.colors.accent
        case .danger: return theme.colors.danger
        }
    }

    private var background: Color {
        switch variant {
        case .primary: return theme.colors.accent
        case .secondary: return theme.colors.surfaceHigh
        case .ghost: return .clear
        case .danger: return theme.colors.dangerSoft
        }
    }

    private var strokeColor: Color {
        variant == .secondary ? theme.colors.border : .clear
    }
}
