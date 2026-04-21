import SwiftUI

@main
struct BrewSpotApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    @StateObject private var reviewStore = ReviewStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(bookmarkStore)
                .environmentObject(reviewStore)
                .task {
                    await sessionStore.bootstrap()
                }
        }
    }
}
