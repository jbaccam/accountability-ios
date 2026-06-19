import SwiftUI

/// The signed-out auth flow. Owns its OWN NavigationStack (do NOT use the `Nav`
/// environment object here). Root is the landing screen; everything else is
/// pushed via `AuthRoute`.
struct AuthFlowView: View {
    @Environment(\.theme) private var theme
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LandingView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .signIn:
                        SignInView()
                    case .signUp:
                        SignUpView()
                    case .forgotPassword:
                        ForgotPasswordView()
                    case .verifyEmail(let email):
                        VerifyEmailView(email: email)
                    }
                }
        }
        .tint(theme.colors.accent)
    }
}

/// Destinations within the auth flow's own stack.
enum AuthRoute: Hashable {
    case signIn
    case signUp
    case forgotPassword
    case verifyEmail(String)
}
