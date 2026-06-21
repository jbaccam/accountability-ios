import Foundation
import Observation
import Supabase

/// Auth + current-user state for the whole app. Mirrors the JS auth flow:
/// persisted session via Keychain, auto-refresh while foregrounded, and the
/// profile loaded once signed in.
@MainActor
@Observable
final class SessionStore {
    var session: Session?
    var profile: Profile?
    var isBootstrapping = true

    private let client = Supa.client
    private var listenerTask: Task<Void, Never>?

    var isSignedIn: Bool { session != nil }
    var userId: String? { session?.user.id.uuidString.lowercased() }

    func start() {
        listenerTask?.cancel()
        listenerTask = Task { [weak self] in
            guard let self else { return }
            for await change in client.auth.authStateChanges {
                await self.handle(event: change.event, session: change.session)
            }
        }
        Task { await loadInitialSession() }
    }

    private func loadInitialSession() async {
        session = try? await client.auth.session
        if session != nil { await loadProfile() }
        isBootstrapping = false
    }

    private func handle(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn, .tokenRefreshed, .userUpdated, .initialSession:
            self.session = session
            if session != nil { await loadProfile() }
        case .signedOut:
            self.session = nil
            self.profile = nil
        default:
            break
        }
    }

    // MARK: - Auth actions

    func signIn(email: String, password: String) async throws {
        session = try await client.auth.signIn(email: email, password: password)
        await loadProfile()
    }

    /// Returns true when a session is established immediately (email confirmation
    /// disabled); false when a confirmation email is required.
    @discardableResult
    func signUp(email: String, password: String, displayName: String) async throws -> Bool {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": AnyJSON.string(displayName)]
        )
        if let s = response.session {
            session = s
            await loadProfile()
            return true
        }
        return false
    }

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
        profile = nil
    }

    /// Re-send the signup confirmation email.
    func resendConfirmation(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    func sendPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "accountability://auth-reset")
        )
    }

    func updatePassword(_ newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    /// Handle an inbound auth deep link (email confirm / recovery).
    func handleDeepLink(_ url: URL) async {
        do {
            session = try await client.auth.session(from: url)
            await loadProfile()
        } catch {
            // Not an auth link, or already consumed — ignore.
        }
    }

    func loadProfile() async {
        do {
            profile = try await client.rpc("get_my_profile").execute().value
        } catch {
            profile = nil
        }
    }

    func refreshProfile() async { await loadProfile() }
}
