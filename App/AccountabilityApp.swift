import SwiftUI

@main
struct AccountabilityApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                RootView()
                    .environment(session)
            }
            .task { session.start() }
            .onOpenURL { url in
                Task { await session.handleDeepLink(url) }
            }
        }
    }
}
