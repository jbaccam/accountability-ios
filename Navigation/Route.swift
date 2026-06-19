import SwiftUI
import Observation

/// Type-safe push destinations. Tab roots are not routes — these are the screens
/// pushed onto a tab's NavigationStack.
enum Route: Hashable {
    case challengeDetail(challengeId: String)
    case submit(challengeId: String)
    case review(challengeId: String)
    case resolve(challengeId: String)
    case results(challengeId: String)
    case invite(challengeId: String)
    case submissionDetail(submissionId: String)
    case settings
    case deposit
}

/// Per-tab navigation path. Screens read this from the environment and append a
/// `Route` to push programmatically; `NavigationLink(value:)` also works.
@MainActor
@Observable
final class Nav {
    var path: [Route] = []

    func push(_ route: Route) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeAll() }
}

/// Maps a Route to its destination screen. Single source of truth so every tab
/// stack resolves routes identically.
struct RouteDestination: View {
    let route: Route

    var body: some View {
        switch route {
        case let .challengeDetail(id): ChallengeDetailView(challengeId: id)
        case let .submit(id): SubmitView(challengeId: id)
        case let .review(id): ReviewView(challengeId: id)
        case let .resolve(id): ResolveView(challengeId: id)
        case let .results(id): ResultsView(challengeId: id)
        case let .invite(id): InviteView(challengeId: id)
        case let .submissionDetail(id): SubmissionDetailView(submissionId: id)
        case .settings: SettingsView()
        case .deposit: DepositView()
        }
    }
}

/// A tab wrapped in its own navigation stack + Nav environment + route mapping.
struct NavTab<Root: View>: View {
    @State private var nav = Nav()
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack(path: $nav.path) {
            root()
                .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
        }
        .environment(nav)
    }
}
