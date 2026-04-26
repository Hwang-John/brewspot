import SwiftUI

@main
struct BrewSpotApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    @StateObject private var reviewStore = ReviewStore()
    @StateObject private var cafeListViewModel = CafeListViewModel()
    @StateObject private var toastCenter = AppToastCenter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(bookmarkStore)
                .environmentObject(reviewStore)
                .environmentObject(cafeListViewModel)
                .environmentObject(toastCenter)
                .task {
                    await sessionStore.bootstrap()
                }
        }
    }
}
