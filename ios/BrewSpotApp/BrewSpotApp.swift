import SwiftUI

@main
struct BrewSpotApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    @StateObject private var reviewStore = ReviewStore()
    @StateObject private var cafeListViewModel = CafeListViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(bookmarkStore)
                .environmentObject(reviewStore)
                .environmentObject(cafeListViewModel)
                .task {
                    await sessionStore.bootstrap()
                }
        }
    }
}
