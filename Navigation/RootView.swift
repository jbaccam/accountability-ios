import SwiftUI

/// The app's top-level view: auth flow when signed out, the tab bar when signed in.
struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if session.isBootstrapping {
                LoadingState()
            } else if session.isSignedIn {
                MainTabs()
                    .transition(.opacity)
            } else {
                AuthFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: session.isSignedIn)
        .animation(.easeOut(duration: 0.2), value: session.isBootstrapping)
    }
}

private struct MainTabs: View {
    @Environment(\.theme) private var theme

    var body: some View {
        TabView {
            NavTab { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavTab { CreateView() }
                .tabItem { Label("Create", systemImage: "plus.circle.fill") }

            NavTab { JoinView() }
                .tabItem { Label("Join", systemImage: "ticket.fill") }

            NavTab { FriendsView() }
                .tabItem { Label("Friends", systemImage: "person.2.fill") }

            NavTab { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(theme.colors.accent)
    }
}
