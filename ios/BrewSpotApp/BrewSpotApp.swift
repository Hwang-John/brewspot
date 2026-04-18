import SwiftUI

@main
struct BrewSpotApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .task {
                    await sessionStore.bootstrap()
                }
        }
    }
}
